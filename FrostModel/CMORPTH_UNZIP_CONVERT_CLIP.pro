;*******************************************************************************
; PURPOSE:
;  Convert CMORPTH to UNZIP
;
; INPUTS:
; CMORPTHDirectory: input file path.
; UNZIPDirectory: output file path.
;
; OUTPUTS:
; envi
;
; AUTHOR:
; wuxb
;
; MODIFICATION HISTORY:
; 2016.11.28
; 2016.11.30   update add  half hour to one hour
;
;*******************************************************************************
PRO  CMORPTH_UNZIP_CONVERT_CLIP

   CMORPTHDirectory   = 'D:\worktemp\Permafrost(FrostModel)\Data\Prec\PrecZip\'
   TempDirectory      = 'D:\worktemp\Permafrost(FrostModel)\Data\Prec\Temp\'
   UNZIPDirectory     = 'D:\worktemp\Permafrost(FrostModel)\Data\Prec\TempUnZip\'
   ShpFilePath        = 'D:\\workspace\\Write Paper\\SoilTextureProduce\\Data\\ProcessData\\Boundary\\Tibet_Plateau_Boundar.shp'
   
   IF(KEYWORD_SET(CMORPTHDirectory) EQ 0 OR KEYWORD_SET(UNZIPDirectory) EQ 0) THEN RETURN
   
   ZipFiles    = FILE_SEARCH(CMORPTHDirectory, COUNT = nFileCount, '*tar', $
     /TEST_READ, /FULLY_QUALIFY_PATH)
   IF(nFileCount LE 0) THEN BEGIN
     MESSAGE, 'There are no valid GLS CMORPTH data to be processed.'
     RETURN
   ENDIF
   
   ;**************************************************************************
   ;
   ; 1) Initialize the Common variables
   ;
   ;**************************************************************************
   GridSizeX          = 0.072756669D   ;
   GridSizeY          = 0.072771377D   ;
   nx                 = 4948L   ;
   ny                 = 1649L   ;
   ; start point
   StartX             = -179.9818 ;
   StartY             = 59.963614 ;
   ;**************************************************************************
   ;
   ; 2) Creat project
   ;
   ;**************************************************************************
   ; prepare for the envi file header, 0.25deg and 0.5deg are different
   ; Projection
   iProj = ENVI_PROJ_CREATE(/GEOGRAPHIC)
   ; Create the map information
   ps    = [GridSizeX, GridSizeY]
   mc    = [GridSizeX, GridSizeY, StartX, StartY]
   Datum = 'WGS-84'
   Units = ENVI_TRANSLATE_PROJECTION_UNITS ('Degrees')
   iMap  = ENVI_MAP_INFO_CREATE(/GEOGRAPHIC,MC=MC,PS=PS,PROJ=iProj,UNITS=Units)

   ;**************************************************************************
   ;
   ; 3) PROCESS THE FILE
   ;
   ;**************************************************************************
   FOR i=0,nFileCount-1 DO BEGIN
     ;***********************************************************************
     ; {1) Decompress the *.tar files and combine the file by each
     ;***********************************************************************
     gzFilePath   = ZipFiles[i]
     UCommands   = '7z e ' + gzFilePath + ' -aos -o' + TempDirectory
     ; use SPAWN to execute outer executable program- 7z.exe
     SPAWN, UCommands,/HIDE
     ;***********************************************************************
     ; {2) Decompress the *.bz2 files and combine the file by each
     ;***********************************************************************
     ZipFilesBz    = FILE_SEARCH(TempDirectory, COUNT = nFileCountBz2, '*bz2', $
       /TEST_READ, /FULLY_QUALIFY_PATH)
     IF(nFileCountBz2 LE 0) THEN BEGIN
       MESSAGE, 'There are no valid bz2 CMORPTH data to be processed.'
       RETURN
     ENDIF
     FOR j=0,nFileCountBz2-1 DO BEGIN
       bzFilePath   = ZipFilesBz[j]
       UCommandsBz   = '7z e ' + bzFilePath + ' -aos -o' + UNZIPDirectory
       ; use SPAWN to execute outer executable program- 7z.exe
       SPAWN, UCommandsBz,/HIDE
       ;Delete The bz2 file
       IF FILE_TEST(bzFilePath) THEN BEGIN
          FILE_DELETE,bzFilePath
       ENDIF
       ;***********************************************************************
       ; {3) Convert the binary files to envi file
       ;***********************************************************************
       bzFileName        =  FILE_BASENAME(bzFilePath)
       FileName          = STRMID(bzFileName,0,STRLEN(bzFileName)-4) 
       OutFileName       =  UNZIPDirectory + FileName

       IF FILE_TEST(OutFileName) THEN BEGIN
        
         OPENR, hFile, OutFileName, /GET_LUN
         data1        = READ_BINARY(hFile,DATA_DIMS=[nx,ny],DATA_START=0,$
                       DATA_TYPE=4,ENDIAN='little')
;         data1        = REVERSE(data1, 2)

         data2        = READ_BINARY(hFile,DATA_DIMS=[nx,ny],DATA_START=31872,$
                       DATA_TYPE=4,ENDIAN='little')
;         data2        = REVERSE(data2, 2)

         data         =  data1 + data2
         data(where(data< 0)) = -999

         ;3.2   Monthly file names
         FileName    =  FILE_BASENAME(OutFileName)
         OutFilePath =  UNZIPDirectory + FileName  + '.dat'

         OPENW, HData, OutFilePath, /GET_LUN
         WRITEU, HData,data
         FREE_LUN, HData

         ; Edit the envi header file
         ENVI_SETUP_HEAD, FNAME=OutFilePath,NS=nx,NL=ny,NB=1,INTERLEAVE=0,$
           DATA_TYPE=4,OFFSET=0,MAP_INFO=iMap,/WRITE,$
           /OPEN,R_FID=Data_FID
         FREE_LUN,hFile
         
         
         ;Delete The Binary  File
         IF FILE_TEST(OutFileName) THEN BEGIN
           FILE_DELETE,OutFileName
         ENDIF
       ENDIF
       
       ;***********************************************************************
       ; {4) Clip the world envi file to QTP file
       ;***********************************************************************

       IF STRLEN(ShpFilePath) EQ 0 THEN RETURN
       oshp = OBJ_NEW('IDLffshape',ShpFilePath)
       oshp->GETPROPERTY,n_entities=n_ent,Attribute_info=attr_info,$
         n_attributes=n_attr,Entity_type=ent_type
       roi_shp = LONARR(n_ent)
       FOR ishp = 0,n_ent-1 DO BEGIN
         entitie = oshp->GETENTITY(ishp)
         IF entitie.SHAPE_TYPE EQ 5 THEN BEGIN
           record = *(entitie.VERTICES)
           ;Convert map Coordinates
           ENVI_CONVERT_FILE_COORDINATES,Data_FID,xmap,ymap,record[0,*],record[1,*]
           ;Creat ROI
           roi_shp[ishp] = ENVI_CREATE_ROI(ns=nx,nl=ny)
           ENVI_DEFINE_ROI,roi_shp[ishp],/polygon,xpts=REFORM(xmap),ypts=REFORM(ymap)
           ;记录X,Y的区间，裁剪用
           IF ishp EQ 0 THEN BEGIN
             xMin = ROUND(MIN(xMap,max = xMax))
             yMin = ROUND(MIN(yMap,max = yMax))
           ENDIF ELSE BEGIN
             xMin = xMin < ROUND(MIN(xMap))
             xMax = xMax > ROUND(MAX(xMap))
             yMin = yMin < ROUND(MIN(yMap))
             yMax = yMax > ROUND(MAX(yMap))
           ENDELSE
         ENDIF
         oshp->DESTROYENTITY,entitie
       ENDFOR;ishp
       xMin = xMin >0
       xMax = xMax < nx-1
       yMin = yMin >0
       yMax = yMax < ny-1
       ;**************************************************************************
       ; 3) output file setting
       ;**************************************************************************
       OutFilename = UNZIPDirectory + FileName + '_QTP.dat'
       out_dims    = [-1,xMin,xMax,yMin,yMax]
       pos = INDGEN(1)
       ENVI_DOIT,'ENVI_SUBSET_VIA_ROI_DOIT',background=0,fid=Data_FID,dims=out_dims,out_name=OutFilename,$
         ns = nx, nl = ny,pos=pos,roi_ids = roi_shp

       ENVI_FILE_MNG, ID=Data_FID,/REMOVE,/DELETE
       
       ;remove fids
       fids = ENVI_GET_FILE_IDS()
       IF (fids[0] EQ -1) THEN RETURN
       ENVI_FILE_MNG, id = fids[0], /REMOVE
       
       
     ENDFOR
   ENDFOR
END
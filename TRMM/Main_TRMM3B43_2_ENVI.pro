;*******************************************************************************
; PURPOSE:
;  Convert trmm3b43 to envi 
;
; INPUTS:
; TRMMDirectory: input file path.
; ENVIDirectory: output file path.
;
; OUTPUTS:
; envi 
;
; AUTHOR:
; wuxb
;
; MODIFICATION HISTORY:
; 2014.5.7
;
;*******************************************************************************
PRO  Main_TRMM3B43_2_ENVI, TRMMDirectory ,ENVIDirectory

  TRMMDirectory   = 'D:\Temp\111\'
  ENVIDirectory   = 'D:\Temp\222\'
  
  ;**************************************************************************
  ;
  ; 1) Initialize the Common variables
  ;
  ;**************************************************************************
  GridSizeX          = 0.07278   ;
  GridSizeY          = 0.07275
  nx                 = 4948L  ;
  ny                 = 1649L   ;
  ; start point
  StartX             = -179.9818 ;
  StartY             = -59.963 ;
  
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
  mc    = [GridSizeX, 0.25D, StartX, StartY]
  Datum = 'WGS-84'
  Units = ENVI_TRANSLATE_PROJECTION_UNITS ('Degrees')
  iMap  = ENVI_MAP_INFO_CREATE(/GEOGRAPHIC,MC=MC,PS=PS,PROJ=iProj,UNITS=Units)
  
  ;**************************************************************************
  ;
  ; 3) Get the files to be convert
  ;
  ;**************************************************************************
  BINFilePaths = FILE_SEARCH(TRMMDirectory, '/*.{bin,accum}', COUNT = nCount, /TEST_READ, /FULLY_QUALIFY_PATH)
  IF(nCount LE 0) THEN RETURN
  FOR i=0, nCount-1 DO BEGIN
  
    ;**************************************************************************
    ; [1] Get File Year
    ;**************************************************************************
    FilePath    =    FILE_DIRNAME(BINFilePaths[i]);
    DataYear    =    STRMID(FilePath, STRLEN(FilePath)-4, STRLEN(FilePath));
    ;**************************************************************************
    ; [2] Create no exists file althorgh Year
    ;**************************************************************************
    OutPath     =    ENVIDirectory  + DataYear;
    Result      =    FILE_TEST(OutPath);
    IF Result EQ 0 THEN BEGIN
      FILE_MKDIR,OutPath
    END
    
    ;*********************************************************************
    ; [3] Save the daily data to ENVI standard file
    ;*********************************************************************
    ;3.1   Read  month  file  data
    OPENR, hFile, BINFilePaths[i], /GET_LUN
    data        = Read_binary(hFile,DATA_DIMS=[nx,ny],DATA_START=0,$
      DATA_TYPE=4,ENDIAN='big')
    data        = Reverse(data, 2)
    
    ;3.2   Monthly file names
    FileName    =  FILE_BASENAME(BINFilePaths[i])
    FileNameTmp =  Strsplit(FileName,'.',/extract)
    FileOutName = FileNameTmp[0] + "_" + DataYear + STRMID(FileNameTmp[1],2,2) +"_V" + $
                  FileNameTmp[2] + "_" + FileNameTmp[3]
    OutFilePath = OutPath + '\' + FileOutName  + '.dat'
    
    OPENW, HData, OutFilePath, /GET_LUN
    WRITEU, HData,data
    FREE_LUN, HData
    
    ; Edit the envi header file
    ENVI_SETUP_HEAD, FNAME=OutFilePath,NS=nx,NL=ny,NB=1,INTERLEAVE=0,$
      DATA_TYPE=4,OFFSET=0,MAP_INFO=iMap,BNAMES=['3B43_V7'],/WRITE,$
      /OPEN,R_FID=Data_FID
    ENVI_FILE_MNG, ID=Data_FID, /REMOVE
    
    FREE_LUN,hFile
     
  END
 
END

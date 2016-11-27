;******************************************************************************
;; $Id: envi45_config/Program/LakeMappingTools/SRTM_CreateDEMFromLandsatExt.pro $
;;
;; Author: Junli LI, Geography Department of UCLA, Los Angeles, CA 90095
;+
;; NAME:
;;   SRTM_CreateDEMFromLandsatExt
;;
;; PURPOSE:
;;   The procedure create DEM from SRTM file, for each landsat file. The spatial
;;   extent of the DEM is the same as that of the Landsat file. 
;;
;; PARAMETERS:
;;   LandsatFile(in)   - input Landsat file path
;;
;;   SRTMFile(in)      - input SRTM file path
;;
;;   DEMFile(in)       - input subseted DEM file path
;;
;; OUTPUTS:
;;
;; CALLING CUSTOM-DEFINED FUNCTIONS: 
;;
;; PROCEDURES OR FUNCTIONS CALLED:  SRTM_DEM_SHADE_SubSet
;;
;; MODIFICATION HISTORY:
;;   Written by:  Junli LI, 2009/04/23 12:00 AM
;-
;******************************************************************************

PRO SubBaseFileFromCoronaExtents, LandsatFile, SRTMFile, DEMFile


    CORONA_DIR = 'I:\Corona\Corona_Used\'
    BaseImgFile= 'I:\Corona\Corona_Yini\QuickEye8m_UTM44_S.dat'
    BASEImg_DIR= 'I:\Corona\BaseImgDIR\'
    
     ; Find all corona files in the give directory
    CoronaFilePaths = FILE_SEARCH(CORONA_DIR,'*.DAT', COUNT = FileCount, $
                                 /TEST_READ, /FULLY_QUALIFY_PATH)
      
    IF(FileCount LE 0) THEN BEGIN
        Message, 'There are no valid corona files in the given directory.'
        RETURN
    ENDIF
    
    ;**************************************************************************
    ; 1) Load the Base image file
    ;***************************************************************************
    ENVI_OPEN_FILE, BaseImgFile, R_FID = BASE_FID
    ;**************************************************************************
    ; 2) Get the project information of the Landsat images and SRTM images
    ;***************************************************************************
    ENVI_FILE_QUERY, BASE_FID, NS=BASE_NS, NL=BASE_NL, DIMS=BASE_DIMS
    ; the map information structure
    ImageMapinfo  = ENVI_GET_MAP_INFO(FID=BASE_FID)
    ; the projection information
    BASEProj       = ENVI_GET_PROJECTION(FID=BASE_FID, PIXEL_SIZE=BASEPixSiz)
    ;**************************************************************************
    ; 3)  Load the Corona files and subset BASE image with their extents
    ;   
    ;**************************************************************************
    ; Initialize ENVI and store all errors and warnings in LogFileBatch.txt
    logProcedureFileName = 'LogFileBatch.txt'
    ENVI, /RESTORE_BASE_SAVE_FILES
    ENVI_BATCH_INIT, LOG_FILE = logProcedureFileName
    ;
    PRINT, 'Subset Base Image files with Corona file extents.....'
    time_begin = SYSTIME(/UTC)
    PRINT, 'time begins' + STRING(time_begin)
    
    FOR i=0, FileCount-1 DO BEGIN
    
        CoronaFileName = CoronaFilePaths[i]
        FileName       = FILE_BASENAME(CoronaFileName)
        BaseImg_Sub    = BASEImg_DIR + 'BASE_'+ FileName
       
        ;**************************************************************************
        ; 2) Get the project information of the Landsat images and SRTM images
        ;***************************************************************************
        ENVI_OPEN_FILE,  CoronaFileName, R_FID = Corona_FID
        ENVI_FILE_QUERY, Corona_FID, NS=COR_NS, NL=COR_NL, DIMS=COR_DIMS
        ; the map information structure
        ImageMapinfo = ENVI_GET_MAP_INFO(FID=Corona_FID)
        ; the projection information
        BASEProj     = ENVI_GET_PROJECTION(FID=Corona_FID, PIXEL_SIZE=Cor_Siz)
       
        ; Convert x,y pixel coordinates of the Image to map coordinates
        xPix = [0, COR_NS-1]
        yPix = [0, COR_NL-1]
        ENVI_CONVERT_FILE_COORDINATES, Corona_FID, xPix, yPix, xMap, yMap, /TO_MAP
        ENVI_CONVERT_FILE_COORDINATES, BASE_FID,xBASE,yBASE,xMap,yMap
        ;  
        xBASE = LONG(xBASE)
        yBASE = LONG(yBASE)
    
        ; Adjust the subset extent of the SRTM so as to make it with the spatial 
        ; extent of SRTM files
       IF(xBASE[0] GE BASE_NS OR yBASE[0] GE BASE_NL OR xBASE[1] LT 0 $
          OR yBASE[1] LT 0) THEN BEGIN
          PRINTF, CoronaFileName + ' is outside of the file extents!'
          RETURN
       ENDIF
       IF(xBASE[0] LT 0) THEN xBASE[0] = 0
       IF(xBASE[1] GE BASE_NS) THEN xBASE[1] = BASE_NS-1
       IF(yBASE[0] LT 0) THEN yBASE[0] = 0
       IF(yBASE[1] GE BASE_NL) THEN yBASE[1] = BASE_NL-1
       ; Get the SRTM data in the map range of xDEM and yDEM
       SUB_DIMS = [-1, xBASE[0],xBASE[1], yBASE[0], yBASE[1] ]
       SUB_NS   = xBASE[1]-xBASE[0]
       SUB_NL   = yBASE[1]-yBASE[0]
       
       
       
      ;**************************************************************************
      ; 4) Convert the projection of the SRTM from Geography Lat/Lon to UTM 
      ;    projection of the Landsat image files
      ;**************************************************************************
    
      ;**************************************************************************
      ; 5) SubSet the tmp files and smooth the DEM use median filters
      ;**************************************************************************
      ; Convert map coordinates of to  pixel coordinates of the tmpfile
      ENVI_CONVERT_FILE_COORDINATES, tmp_FID, xPix, yPix, xMap, yMap
      xPix = uint(xPix)
      yPix = uint(yPix)
      DEM_DIMS = [-1L, xPix[0],xPix[0]+ImageWidth-1, yPix[0], yPix[0]+ImageHeight-1]
      ENVI_OUTPUT_TO_EXTERNAL_FORMAT, FID=tmp_FID,POS=[0],DIMS=DEM_DIMS,$
                     OUT_BNAME='DEM', OUT_NAME=DEMFile, /ENVI         
      ; Close the tmp file
      ENVI_FILE_MNG, ID = tmp_FID, /REMOVE, /DELETE
    
      ; remove all the FIDs in the file lists
      FIDS = ENVI_GET_FILE_IDS()
      IF(N_ELEMENTS(FIDS) GE 1) THEN BEGIN
         FOR i = 0, N_ELEMENTS(FIDS) - 1 DO BEGIN
           IF(FIDS[i] NE -1) THEN  ENVI_FILE_MNG, ID=FIDS[i], /REMOVE
         ENDFOR
      ENDIF
    ENDFOR
END
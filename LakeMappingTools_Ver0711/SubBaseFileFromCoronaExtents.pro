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

PRO SubBaseFileFromCoronaExtents 


    CORONA_DIR = 'I:\Corona\Corona_Used\'
    BaseImgFile= 'I:\Corona\Corona_Yini\QuickEye8m_UTM44_S.dat'
    BASEImg_DIR= 'I:\Corona\BaseImgDIR\'
    
     ; Find all corona files in the give directory
    CoronaFilePaths = FILE_SEARCH(CORONA_DIR,'*.IMG', COUNT = FileCount, $
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
        TypeSuf        = STRMID(FileName,STRLEN(FileName)-4,4) 
        IF(TypeSuf EQ '.img' ) THEN FileName = STRMID(FileName,0,STRLEN(FileName)-4)+'.dat'
        BaseImg_Sub    = BASEImg_DIR + 'BASE_'+ FileName
         
        ;**************************************************************************
        ; 2) Get the project information of the Landsat images and SRTM images
        ;***************************************************************************
        ENVI_OPEN_DATA_FILE,  CoronaFileName, /IMAGINE, R_FID = Corona_FID
        ENVI_FILE_QUERY, Corona_FID, NS=COR_NS, NL=COR_NL, DIMS=COR_DIMS
        ; the map information structure
        CoronaMapinfo = ENVI_GET_MAP_INFO(FID=Corona_FID)
        ; the projection information
        CoronaProj     = ENVI_GET_PROJECTION(FID=Corona_FID, PIXEL_SIZE=Cor_PS)
       
        ; Convert x,y pixel coordinates of the Image to map coordinates
        xPix  = [0, COR_NS-1]
        yPix  = [0, COR_NL-1]
        ENVI_CONVERT_FILE_COORDINATES, Corona_FID, xPix, yPix, xMap, yMap, /TO_MAP
        ENVI_CONVERT_FILE_COORDINATES, BASE_FID,xBASE,yBASE,xMap,yMap
        ;  
        xBASE = LONG(xBASE)
        yBASE = LONG(yBASE)
    
        ; Adjust the subset extent of the SRTM so as to make it with the spatial 
        ; extent of SRTM files
       IF( xBASE[1] GE BASE_NS OR yBASE[1] GE BASE_NL OR xBASE[0] LT 0 $
          OR yBASE[0] LT 0) THEN BEGIN
          PRINTF, CoronaFileName + ' is outside of the file extents!'
          RETURN
       ENDIF
       ; Get the SRTM data in the map range of xDEM and yDEM
       SUB_DIMS  = [-1, xBASE[0],xBASE[1], yBASE[0], yBASE[1] ]
       BASE_DATA =  ENVI_GET_DATA(FID=BASE_FID, DIMS=SUB_DIMS, POS=[0])
       BASE_OUT  = CONGRID(TEMPORARY(BASE_DATA), COR_NS, COR_NL, /INTERP) 
       
       FILE_TYPE       = ENVI_FILE_TYPE('ENVI Standard')
       ; Create a classification layer
       ENVI_ENTER_DATA, TEMPORARY(BASE_OUT), BNAMES='BASE_Sub',$
                     FILE_TYPE=FILE_TYPE, MAP_INFO=CoronaMapinfo, PIXEL_SIZE=Cor_PS,$
                     R_FID=OUT_FID
       ENVI_OUTPUT_TO_EXTERNAL_FORMAT, FID=OUT_FID,POS=[0],DIMS=COR_DIMS,$
                     OUT_BNAME='BASE_Sub', OUT_NAME=BaseImg_Sub, /ENVI   
       
       ENVI_FILE_MNG, ID=OUT_FID, /REMOVE
       ENVI_FILE_MNG, ID=Corona_FID, /REMOVE
    ENDFOR
     ENVI_FILE_MNG, ID=BASE_FID, /REMOVE
    ; remove all the FIDs in the file lists
     FIDS = ENVI_GET_FILE_IDS()
     IF(N_ELEMENTS(FIDS) GE 1) THEN BEGIN
        FOR i = 0, N_ELEMENTS(FIDS) - 1 DO BEGIN
          IF(FIDS[i] NE -1) THEN  ENVI_FILE_MNG, ID=FIDS[i], /REMOVE
        ENDFOR
     ENDIF
END
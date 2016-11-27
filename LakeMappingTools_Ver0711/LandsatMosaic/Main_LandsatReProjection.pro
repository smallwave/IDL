PRO Main_LandsatReProjection

    ;*************************************************************************
    ; Initilize the procedure parameters
    ;*************************************************************************
    ; ############################################################
    ; Temporary variables, just for testing
    Landsat_DIR   = 'H:\2010_add\'
    ReProject_DIR = 'H:\CentralAsia2010_reproj\'
    SRTMFile      = 'H:\Reproject\CentralAisa_Albers_P150R026.dat'
    ; ############################################################
    
    IF(Landsat_DIR EQ '' OR ReProject_DIR EQ '') THEN BEGIN
       MESSAGE, 'The given directory is invalid.'
       RETURN
    ENDIF
    LandsatFilePaths = FILE_SEARCH(Landsat_DIR,'*.dat', COUNT=FileCount,$
                                   /TEST_READ, /FULLY_QUALIFY_PATH) 
    IF(FileCount LE 0) THEN BEGIN
        PRINT, 'There are no valid Landsat files in the given directory.'
        RETURN
    ENDIF
  
    ENVI, /RESTORE_BASE_SAVE_FILES
    ENVI_BATCH_INIT, LOG_FILE = logProcedureFileName
    
    ;*************************************************************************
    ;
    ; Loop procedures to extract lake from the landsat scenes
    ;
    ;*************************************************************************
    ; Open the SRTM File
    ENVI_OPEN_FILE, SRTMFile, R_FID=SRTM_FID
    ; the projection information
    SRTMProj      = ENVI_GET_PROJECTION(FID=SRTM_FID, PIXEL_SIZE=SRTMPixSiz)
    
    FOR i=0, FileCount-1 DO BEGIN
        LandsatFile  = LandsatFilePaths[i]
        FileName     = STRMID(LandsatFile, 0, STRLEN(LandsatFile)-4)
        ; Get the base file name (without directory)
        FileName     = FILE_BASENAME(FileName)
        ReProjFile   = ReProject_DIR + FileName + '_Reproj.dat'
        ENVI_OPEN_FILE, LandsatFile, R_FID = TM_FID
        Proj         = ENVI_GET_PROJECTION(FID=TM_FID, PIXEL_SIZE=PS)
        ENVI_FILE_QUERY, TM_FID, NS=NS, NL=NL, NB=NB, DIMS=DIMS
        POS = LINDGEN(NB)
        ENVI_CONVERT_FILE_MAP_PROJECTION, FID=TM_FID, POS=POS, DIMS=DIMS,$
               O_PROJ = SRTMProj, O_PIXEL_SIZE = PS, GRID = [80,80], $
               OUT_NAME=ReProjFile, WARP_METHOD=2, RESAMPLING=0, BACKGROUND=0,$
               R_FID=Proj_FID
        ; Close the SRTM file
        ENVI_FILE_MNG, ID = TM_FID, /REMOVE
        ENVI_FILE_MNG, ID = Proj_FID, /REMOVE
    ENDFOR
    ENVI_FILE_MNG, ID = SRTM_FID, /REMOVE
    
    ; remove all the FIDs in the file lists
    FIDS = ENVI_GET_FILE_IDS()
    IF(N_ELEMENTS(FIDS) GE 1) THEN BEGIN
       FOR i = 0, N_ELEMENTS(FIDS) - 1 DO BEGIN
           IF(FIDS[i] NE -1) THEN  ENVI_FILE_MNG, ID=FIDS[i], /REMOVE
       ENDFOR
    ENDIF
    
END
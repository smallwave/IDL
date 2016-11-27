
PRO Main_LandsatReflectance

    ;*************************************************************************
    ; Initilize the procedure parameters
    ;*************************************************************************
    ; ############################################################
    ; Temporary variables, just for testing
    Landsat_DIR = 'I:\Landsat_add\2010\'
    Refl_DIR    = 'I:\Landsat_add\2010_ref\'
    ; ############################################################
    
    IF(Landsat_DIR EQ '' OR Refl_DIR EQ '') THEN BEGIN
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
    nTotalMinutes = 0.0
    FOR i=0, FileCount-1 DO BEGIN 

        LandsatFile  = LandsatFilePaths[i]
        FileName        = STRMID(LandsatFile, 0, STRLEN(LandsatFile)-4)
        ; Get the base file name (without directory)
        FileName        = FILE_BASENAME(FileName)
        RefFileName     =  FileName + '_Refl.dat'
        ReflFile        =  Refl_DIR + RefFileName
        
        ; Processing
        print, STRTRIM(STRING(i+1),2) + ': ' + FileName + ' is processing'
        time_begin      = SYSTIME(1,/SECONDS)
        ;GLCF_Landsat_TOAReflectance, LandsatFile, ReflFile
        GLOVIS_Landsat_TOAReflectance1,LandsatFile, ReflFile
        time_end   = SYSTIME(1,/SECONDS)
        print, 'Processing time: ' + STRING(time_end-time_begin) + ' seconds'
    ENDFOR
    print, 'FINISHED!'
END
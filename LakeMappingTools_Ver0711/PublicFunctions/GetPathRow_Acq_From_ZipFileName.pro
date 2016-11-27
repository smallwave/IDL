PRO GetPathRow_Acq_From_ZipFileName
   
    Landsat_Directory  = 'E:\LandsatETM_Tibet\OriginalData\zip\'
    TxtFileName        = 'E:\LandsatETM_Tibet\ETM_datalist.txt'
    ;
    ; Find all of the Landsat file paths in the input directory
    ;
    ZipFiles = FILE_SEARCH(Landsat_Directory, COUNT = FileCount, '*.gz', /TEST_READ, /FULLY_QUALIFY_PATH)
    IF(FileCount LE 0) THEN BEGIN
       MESSAGE, 'There are no valid GLCF landsat data to be processed.'
       RETURN
    ENDIF
    
    ENVI, /RESTORE_BASE_SAVE_FILES
    ENVI_BATCH_INIT, LOG_FILE = logProcedureFileName
    ; Get the file handle of the logProcedureFileName
    
    GET_LUN, PRO_LUN
    OPENW, PRO_LUN, TxtFileName

    ; Loop by the scene count of landsat images
    FOR i=0,FileCount-1 DO BEGIN
        gzFilePath   = ZipFiles[i]
        gzFileName   = FILE_BASENAME(gzFilePath)
        Path         = STRMID(gzFileName,3,3)+'  '
        Row          = STRMID(gzFileName,6,3)+'  '
        AcqDate      = STRMID(gzFileName,9,7)
        sYear        = STRMID(AcqDate,0,4)
        nYear        = LONG(sYear)
        nDays        = LONG(STRMID(AcqDate,4,3))
        JulDays      = JulDay(1,0,nYear)+nDays
        CALDAT, JulDays, nMonth, nDay, nYear1
        IF(nDay  LT 10) THEN sDay  = '0'+STRTRIM(STRING(nDay),2)  ELSE sDay  = STRTRIM(STRING(nDay),2)
        IF(nMonth LT 10) THEN sMonth = '0'+STRTRIM(STRING(nMonth),2) ELSE sMonth = STRTRIM(STRING(nMonth),2)
        sDate        = sYear+sMonth+sDay
        PRINTF,PRO_LUN,Path,Row,sDate
    ENDFOR
    
    FREE_LUN, PRO_LUN
END
    
PRO PUB_AddDATprefix

    Meteo_DIR = 'D:\MoonsoonAsia_PrecipiataionData_Japan\APHRODITE\Monthly\DAT\'
    ; Get the file count from the input dir
    MeteoFiles = FILE_SEARCH(Meteo_DIR, COUNT = nFileCount,'*',$
                             /TEST_READ, /FULLY_QUALIFY_PATH)
    IF(nFileCount LE 0) THEN BEGIN
       RETURN
    ENDIF
    
    FOR i=0L,nFileCount-1 DO BEGIN 
    
        MeteoFile     = MeteoFiles[i]
        MeteoFile1    = MeteoFile + '.dat'
        FILE_MOVE,MeteoFile,MeteoFile1
    ENDFOR
    
    
END
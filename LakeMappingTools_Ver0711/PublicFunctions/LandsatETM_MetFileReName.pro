PRO LandsatETM_MetFileReName
 
    FILE_DIR   = 'D:\Northermica\met\'
    ; Find landsat files in the give directory
    FilePaths  = FILE_SEARCH(FILE_DIR,'*.*', COUNT = FileCount, $
                             /TEST_READ, /FULLY_QUALIFY_PATH)

    FOR i=0, FileCount-1 DO BEGIN
        FileName    = FilePaths[i]
        BaseFileName = FILE_BASENAME(FileName)   
        ; Path    
        FileName1    = 'p' + STRMID(BaseFileName, 3, 4) + 'r'
        ; Row
        FileName2    = STRMID(BaseFileName, 6, 3)
        ; Get the year
        sYear        = '_7dk' + STRMID(BaseFileName, 9,4)
        ; Get the days, then convert it to Month, Day
        Days         = FIX(STRMID(BaseFileName, 13,3))
        Juldays      = JULDAY(1,1,2000)+Days
        CALDAT, Juldays, Month,Day
        strMonth = STRTRIM(Month,2)
        IF(Month LT 10) THEN strMonth = '0'+strMonth
        strDays  = STRTRIM(Day,2)
        IF(Day LT 10) THEN strDays   = '0'+strDays
        ; Get the extension for file types
        pos = STRPOS(BaseFileName,'.')
        FileTypes =  STRMID(BaseFileName,pos,STRLEN(BaseFileName)-pos)
        NewFileName  = FILE_DIR+FileName1 + FileName2+sYear+strMonth+strDays+FileTypes
        ; Generate the output file name
        FILE_MOVE, FileName, NewFileName
    ENDFOR
    
END
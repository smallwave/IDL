PRO LandsatETM_ReName
 
    FILE_DIR   = '/Volumes/TM/Landsat/'
    ; Find landsat files in the give directory
    FilePaths  = FILE_SEARCH(FILE_DIR,'*.dat.hdr', COUNT = FileCount, $
                             /TEST_READ, /FULLY_QUALIFY_PATH)

    FOR i=0, FileCount-1 DO BEGIN
        FileName    = FilePaths[i]
        NewFileName =  STRMID(FileName,0,STRLEN(FileName)-7)
        NewFileName  = NewFileName + 'HDR'
        ; Generate the output file name
        FILE_MOVE, FileName, NewFileName
        
    ENDFOR
    
END
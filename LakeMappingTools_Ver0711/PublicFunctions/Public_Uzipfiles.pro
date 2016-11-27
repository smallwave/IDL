


PRO PUBLIC_UZipFiles,INFile_DIR, OUTFile_DIR
    
    ; ########################################################################
    ; Temporary variables, just for testing       
    INFile_DIR   = '/Volumes/D2/tm/1990/TM1990_1/'
    OUTFile_DIR  = '/Volumes/D2/tm/1990/TM1990_GLCF/'
    ; ########################################################################
 
     STR_FILENAME = '*.tar.gz'
       ;Find all the files in INFile_DIR whose names match with STR_FILENAME
       FilePaths = FILE_SEARCH(INFile_DIR,STR_FILENAME, COUNT=FileCount,$
                                   /TEST_READ, /FULLY_QUALIFY_PATH) 
       FOR i=0,FileCount-1 DO BEGIN
          FileI = FilePaths[i]
          BaseFile = FILE_BASENAME(FileI)
          FileJ = OUTFile_DIR+STRMID(BaseFile, 0, STRLEN(BaseFile) - 7) +'/'
          FILE_MKDIR,FileJ
          UCommands   = 'tar -xzvf ' + FileI + ' -C ' + FileJ
          print, UCommands
          SPAWN, UCommands
       ENDFOR
    print,'end'
END
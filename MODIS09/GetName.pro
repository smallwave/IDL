PRO Getname
  
    FilePath = 'E:\Landsat_Modis\MOD09GHK\'
    TXTPath  = 'E:\Landsat_Modis\MOD09GHK_List.txt'
    OPENW, hFile,txtPath, /GET_LUN
    
    FileSearch = FILE_SEARCH(FilePath, COUNT = ProductCount, '*.dat', /TEST_READ, /FULLY_QUALIFY_PATH)
    IF(ProductCount LE 0) THEN BEGIN
       Print, 'There are no valid MODIS data to be processed.'
       RETURN
    ENDIF
    
    FOR i=0, ProductCount-1 DO BEGIN
      File =FileSearch[i]
      Filename  =  FILE_BASENAME(File)
      MOD_Name  =  STRMID(Filename,0,STRLEN(Filename)-15)
      PRINTF, hFile, MOD_Name
    ENDFOR
    FREE_LUN, hFile
END
    
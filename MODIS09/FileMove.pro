Pro FileMove

    FilePath = 'D:\MODIS\MOD17A3\mod17a3\'
    OUTFile  = 'D:\MODIS\MOD17A3\'

    FileSearch = FILE_SEARCH(FilePath, COUNT = ProductCount, '*.hdf', /TEST_READ, /FULLY_QUALIFY_PATH)
    IF(ProductCount LE 0) THEN BEGIN
       Print, 'There are no valid MODIS data to be processed.'
       RETURN
    ENDIF
    
    FOR i=0, ProductCount-1 DO BEGIN
      File      =  FileSearch[i] 
      Filename  =  FILE_BASENAME(File)
      MOD_TYPE  =  STRMID(filename,0,7) 
      MOD_DATE  =  STRMID(Filename,8,8)
;      MOD_Path  =  STRMID(FIlename,17,6)   
      SUB_DIR   =  OUTFile + MOD_TYPE + '_' + MOD_DATE
      ;SUB_DIR    =  'E:\MOD09GHK\MOD09GHK_A2003\'
      
      IF(FILE_TEST(SUB_DIR, /DIRECTORY) EQ 0) THEN FILE_MKDIR,SUB_DIR
      
      ;IF(MOD_DATE EQ 2003) THEN BEGIN 
      
      FILE_MOVE, File, SUB_DIR    
      
      ;ENDIF 
      

    ENDFOR
end    
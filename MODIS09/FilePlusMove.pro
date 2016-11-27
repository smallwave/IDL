Pro FilePlusMove

    MODISFile   = 'J:\MOD13A2\'
    OutFile     = 'E:\OLD\'
    
    FileSearch = FILE_SEARCH(MODISFile, COUNT = ProductCount, '*.hdf', /TEST_READ, /FULLY_QUALIFY_PATH)
    IF(ProductCount LE 0) THEN BEGIN
       Print, 'There are no valid MODIS data to be processed.'
       RETURN
    ENDIF
    
    FOR i=1,ProductCount-1 DO BEGIN
      File                =   FileSearch[i-1]
      File2               =   FileSearch[i]
      Modisname           =   FILE_BASENAME(File)
      Modisname2          =   FILE_BASENAME(File2)      
      ModisHead           =   STRMID(Modisname,0,28)
      ModisHead2          =   STRMID(Modisname2,0,28)
      ModisProductDate    =   STRMID(Modisname,28,13)
      ModisProductDate2   =   STRMID(Modisname2,28,13)
      
      MOD_TYPE  =  STRMID(Modisname,0,7) 
      MOD_DATE  =  STRMID(Modisname,8,8)
      MOD_Path  =  STRMID(Modisname,17,6)   
      SUB_DIR   =  OUTFile + MOD_TYPE + '_' + MOD_DATE
      
;      IF(FILE_TEST(SUB_DIR, /DIRECTORY) EQ 0) THEN FILE_MKDIR,SUB_DIR      
      
      IF ModisHead eq ModisHead2 and ModisProductDate LT ModisProductDate2 THEN BEGIN
        
        FILE_MOVE, File, OutFile
        
      ENDIF      
        
    ENDFOR
    
    
END
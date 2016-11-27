Pro NameModify
  
      ModisFile = 'E:\MOD17A2_Month\'
      OutFile   = 'E:\MOD17A2_Monthly\'
  
    FileSearch = FILE_SEARCH(ModisFile, COUNT = ProductCount, '*.hdf', /TEST_READ, /FULLY_QUALIFY_PATH)
    IF(ProductCount LE 0) THEN BEGIN
       Print, 'There are no valid MODIS data to be processed.'
       RETURN
    ENDIF 
    
    FOR i=0, ProductCount-1 DO BEGIN
      File     =  FileSearch[i]
      FileName =  FILE_BASENAME(File)
      Mod_Type =  STRMID(filename,0,7)
      Mod_year =  STRMID(Filename,8,5) 
      Mod_Day  =  STRMID(FileName,13,2)
      MOD_Month=  STRING(Mod_day/3 + 1 ,FORMAT='(I02)')
      Mod_Last =  STRMID(Filename,16,STRLEN(FileName)-16)
      OutName  =  OutFile + Mod_Type + '.' + Mod_year + 'M' + MOD_Month + Mod_Last
      
         file_move,file,outname
          ;ENVI_WRITE_ENVI_FILE,file,out_name= OutName
          
    ENDFOR
  
END

PRO MODIS_FileRelocation

;    Product_Directory  = 'H:\modis_product\ByDate_Path\'
;    Relocate_Directory = 'H:\modis_product\ByPath_Date\'
     Product_Directory  = 'E:\MOD17_GPP\MOD17A2\'
     Relocate_Directory = 'E:\MOD17A2\'

    ; Find all of the Landsat file paths in the input directory
    Date_Directory = FILE_SEARCH(Product_Directory, COUNT = ProductCount, 'Y*', /TEST_READ, /TEST_DIRECTORY)   
    IF(ProductCount LE 0) THEN BEGIN
       MESSAGE, 'There are no valid MODIS data to be processed.'
       RETURN
    ENDIF

    ; Loop by the scene count of landsat images
    FOR i=0,ProductCount-1 DO BEGIN
        MODIS_DIR  = Date_Directory[i]+'\'
        Modis_Search = FILE_SEARCH(MODIS_DIR, COUNT = nCOUNT, 'D*', /TEST_READ, /TEST_DIRECTORY)
          FOR j=0, nCOUNT-1 DO BEGIN
            MOD_File = Modis_Search[j] + '\'
            DirName    = FILE_BASENAME(MOD_File)
            ;nIndex     = STRPOS(DirName, '_')
            ;MOD_TYPE   = STRMID(DirName, 0, nIndex)
            MOD_TYPE   = STRMID(MODIS_DIR,3,7)    ; According to the file paths, modify the length
            nIndex     = STRPOS(DirName, '_', /REVERSE_SEARCH)
            sYear      = STRMID(DirName, nIndex+1, 4)
            nYear      = UINT(sYear)
              IF(MODIS_DATE(MOD_TYPE, nYear,sDATE=sDATE)) THEN BEGIN
              RelocateMODISFile, MODIS_DIR, Relocate_Directory, MOD_TYPE, sDATE
              ENDIF
          ENDFOR        
    ENDFOR

END
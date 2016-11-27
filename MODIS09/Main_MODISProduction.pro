PRO Main_MODISProduction

    MODISLand_DIR = 'E:\MODIS_Data\MOD09A1_2002\MOD09A1\'
    Mosaic_DIR    = 'E:\MODIS_Data\MOD09A1_2002\MOD09A1_CentralAsia\'


    ; Find all of the MODIS file paths in the input directory
    Date_Directory = FILE_SEARCH(MODISLand_DIR, COUNT = ProductCount, 'M?D*', /TEST_READ, $
      /FULLY_QUALIFY_PATH, /TEST_DIRECTORY)
    IF(ProductCount LE 0) THEN BEGIN
       Print, 'There are no valid MODIS data to be processed.'
       RETURN
    ENDIF

    ; Loop by the scene count of landsat images
    FOR i=0,ProductCount-1 DO BEGIN
        MODIS_Directory    = Date_Directory[i]+'\'
        MODISDirectoryName = FILE_BASENAME(MODIS_Directory)
        ENVIDirectoryName  = MODISDirectoryName + '_ENVI\'
;        ENVI_Directory     = MODISLand_DIR + ENVIDirectoryName
        ENVI_Directory     = Mosaic_DIR + ENVIDirectoryName
        IF(FILE_TEST(ENVI_Directory, /DIRECTORY) EQ 0) THEN FILE_MKDIR,ENVI_Directory
        ; First convert the HDF file to ENVI file
        MODIS_HDFtoENVI,MODIS_Directory, ENVI_Directory
        ; Then Mosaic and reproject envi filesd
        MODIS_Mosaic, ENVI_Directory, Mosaic_DIR
    ENDFOR

END
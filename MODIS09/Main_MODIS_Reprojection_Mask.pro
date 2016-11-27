PRO Main_MODIS_Reprojection_Mask

    Mosaic_DIR = '/Volumes/R14TB/MOD09A1_CentralAsia/'
    Subset_DIR = '/Volumes/R14TB/MOD09A1_CentralAsia_Reprj/'
    MASK_FILE  = '/Volumes/R14TB/Mask/centralaisa_modis_geographic_15s.dat'
                                               

    ; Find all of the MODIS file paths in the input directory
    MosaicFiles = FILE_SEARCH(Mosaic_DIR, COUNT = FileCount, '*.dat', /TEST_READ)
    IF(FileCount LE 0) THEN BEGIN
       MESSAGE, 'There are no valid MODIS data to be processed.'
       RETURN
    ENDIF

    ; Loop by the scene count of landsat images
    FOR i=0,FileCount-1 DO BEGIN
        MosaicFile    = MosaicFiles[i]
        FileName    = FILE_BASENAME(MosaicFile)
        OutName     = STRMID(Filename,0,STRLEN(filename)-4)
        ;SubsetFile  = Subset_DIR + FileName
        SubsetFile  = Subset_DIR + OutName + '_prj' + '.dat' 
        ;MODIS_Project, MosaicFile,SubsetFile,MASK_FILE
        MODIS_SubsetWithMASKFile,MosaicFile,MASK_FILE,SubsetFile
        ;subet 
    ENDFOR

END
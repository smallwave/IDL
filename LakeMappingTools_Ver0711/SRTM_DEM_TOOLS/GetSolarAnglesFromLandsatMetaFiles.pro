

PRO GetSolarAnglesFromLandsatMetaFiles, LandsatFile, SunAzimuth, SunElev

    ; Open the Landsat File
    ENVI_OPEN_FILE, LandsatFile, R_FID = TM_FID
    ; Get the sun azimuth and sun elevation angles from the Landsat header file
    SunAzimuth =  ENVI_GET_HEADER_VALUE(TM_FID, 'sun azimuth angle', /FLOAT, $
                                        UNDEFINED=1)
    SunElev    =  ENVI_GET_HEADER_VALUE(TM_FID, 'sun elevation angle',/FLOAT,$
                                        UNDEFINED=1)

    ENVI_FILE_MNG, ID = TM_FID, /REMOVE
    
END


PRO GetMODISCoeff, ProductType, GD_NAME = GD_NAME, SD_NAMES = SD_NAMES, $
                   DATA_TYPE = DATA_TYPE

    IF(ProductType EQ 'MOD09GQ' OR ProductType EQ 'MYD09GQ') THEN BEGIN

       GD_NAME  = 'MODIS_Grid_2D'
       SD_NAMES = ['sur_refl_b01_1','sur_refl_b02_1']
       DATA_TYPE= 4

    ENDIF

    IF(ProductType EQ 'MOD09GQK' OR ProductType EQ 'MYD09GQK') THEN BEGIN

       GD_NAME  = 'MOD_Grid_L2g_2d'
       SD_NAMES = ['sur_refl_b01_1','sur_refl_b02_1']
       DATA_TYPE= 4

    ENDIF

    IF(ProductType EQ 'MOD09GA' OR ProductType EQ 'MYD09GA') THEN BEGIN

       GD_NAME  = 'MODIS_Grid_500m_2D'
       SD_NAMES = ['sur_refl_b03_1','sur_refl_b04_1','sur_refl_b01_1',$
                   'sur_refl_b02_1','sur_refl_b05_1','sur_refl_b06_1',$
                   'sur_refl_b07_1']
       DATA_TYPE= 4
    ENDIF

    IF(ProductType EQ 'MOD09GHK' OR ProductType EQ 'MYD09GHK') THEN BEGIN

       GD_NAME  = 'MOD_Grid_L2g_2d'
       SD_NAMES = ['sur_refl_b03_1','sur_refl_b04_1','sur_refl_b01_1',$
                   'sur_refl_b02_1','sur_refl_b05_1','sur_refl_b06_1',$
                   'sur_refl_b07_1']
       DATA_TYPE= 4

    ENDIF

    IF(ProductType EQ 'MOD09A1' OR ProductType EQ 'MYD09A1') THEN BEGIN

       GD_NAME  = 'MOD_Grid_500m_Surface_Reflectance'
       SD_NAMES = ['sur_refl_b03','sur_refl_b04','sur_refl_b01',$
                   'sur_refl_b02','sur_refl_b05','sur_refl_b06',$
                   'sur_refl_b07','sur_refl_szen','sur_refl_day_of_year']
       DATA_TYPE= 4

    ENDIF

    IF(ProductType EQ 'MOD11A1' OR ProductType EQ 'MYD11A1') THEN BEGIN

       GD_NAME  = 'MODIS_Grid_Daily_1km_LST'
       SD_NAMES = ['LST_Day_1km','LST_Night_1km','Emis_31','Emis_32']
       DATA_TYPE= 4

    ENDIF

    IF(ProductType EQ 'MOD11A2' OR ProductType EQ 'MYD11A2') THEN BEGIN

       GD_NAME  = 'MODIS_Grid_8Day_1km_LST'
       SD_NAMES = ['LST_Day_1km','LST_Night_1km','Emis_31','Emis_32']
       DATA_TYPE= 4

    ENDIF

    IF(ProductType EQ 'MOD12Q1') THEN BEGIN

       GD_NAME  = 'MOD12Q1'
       SD_NAMES = ['Land_Cover_Type_1','Land_Cover_Type_2','Land_Cover_Type_3',$
                   'Land_Cover_Type_4','Land_Cover_Type_5']
       DATA_TYPE= 1

    ENDIF

    IF(ProductType EQ 'MOD13Q1' OR ProductType EQ 'MYD13Q1' ) THEN BEGIN

       GD_NAME  = 'MODIS_Grid_16DAY_250m_500m_VI'
       SD_NAMES = ['250m 16 days NDVI','250m 16 days EVI']
       DATA_TYPE= 4

    ENDIF

    IF(ProductType EQ 'MOD13A1' OR ProductType EQ 'MYD13A1' ) THEN BEGIN

       GD_NAME  = 'MODIS_Grid_16DAY_500m_VI'
       SD_NAMES = ['500m 16 days NDVI','500m 16 days EVI']
       DATA_TYPE= 4

    ENDIF

    IF(ProductType EQ 'MOD13A2' OR ProductType EQ 'MYD13A2') THEN BEGIN

       GD_NAME  = 'MODIS_Grid_16DAY_1km_VI'
       SD_NAMES = ['1 km 16 days NDVI','1 km 16 days EVI']
       DATA_TYPE= 4

    ENDIF

    IF(ProductType EQ 'MOD15A2' OR ProductType EQ 'MYD15A2') THEN BEGIN

       GD_NAME  = 'MOD_Grid_MOD15A2'
       SD_NAMES = ['Lai_1km','Fpar_1km']
       DATA_TYPE= 4

    ENDIF

    IF(ProductType EQ 'MOD17A2' OR ProductType EQ 'MYD17A2') THEN BEGIN

       GD_NAME  = 'MOD_Grid_MOD17A2'
       SD_NAMES = ['Gpp_1km','PsnNet_1km']
       DATA_TYPE= 4

    ENDIF

    IF(ProductType EQ 'MOD17A3' OR ProductType EQ 'MYD17A3') THEN BEGIN

       GD_NAME  = 'MOD_Grid_MOD17A3'
       SD_NAMES = ['Gpp_1km','Npp_1km','Gpp_Npp_QC_1km']
       DATA_TYPE= 4

    ENDIF
    
    IF(ProductType EQ 'MCD43A3') THEN BEGIN

       GD_NAME  = 'MOD_Grid_BRDF'
       SD_NAMES = ['Albedo_BSA_Band1','Albedo_BSA_Band2','Albedo_BSA_Band3',$
                   'Albedo_BSA_Band4','Albedo_BSA_Band5','Albedo_BSA_Band6',$
                   'Albedo_BSA_Band7','Albedo_BSA_vis','Albedo_BSA_nir',$
                   'Albedo_BSA_shortwave']
       DATA_TYPE= 4

    ENDIF
    
    IF(ProductType EQ 'MCD43B3') THEN BEGIN

       GD_NAME  = 'MOD_Grid_BRDF'
       SD_NAMES = ['Albedo_BSA_Band1','Albedo_BSA_Band2','Albedo_BSA_Band3',$
                   'Albedo_BSA_Band4','Albedo_BSA_Band5','Albedo_BSA_Band6',$
                   'Albedo_BSA_Band7','Albedo_BSA_vis','Albedo_BSA_nir',$
                   'Albedo_BSA_shortwave']
       DATA_TYPE= 4

    ENDIF

END
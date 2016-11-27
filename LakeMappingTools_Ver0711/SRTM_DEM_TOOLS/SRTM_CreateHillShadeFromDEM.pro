;******************************************************************************
;; $Id: envi45_config/Program/LakeMappingTools/SRTM_CreateHillShadeFromDEM.pro$
;;
;; Author: Junli LI, Geography Department of UCLA, Los Angeles, CA 90095
;+
;; NAME:
;;   SRTM_CreateHillShadeFromDEM
;;
;; PURPOSE:
;;   The procedure create hill shade info from the give dem files
;;
;; PARAMETERS:
;;   DEMFile(in)   - input DEM file path
;;
;;   SHADEFile(in) - input hill shade file path
;;
;;   SunAzimuth(in)- solar azimuth angle
;;
;;   SunElev(in)   - solar elevation angle
;;
;; OUTPUTS:
;;
;; CALLING CUSTOM-DEFINED FUNCTIONS: 
;;
;; PROCEDURES OR FUNCTIONS CALLED:  SRTM_DEM_SHADE_SubSet
;;
;; MODIFICATION HISTORY:
;;   Written by:  Junli LI, 2009/04/23 12:00 AM
;-
;******************************************************************************

PRO SRTM_CreateHillShadeFromDEM, DEMFile, SHADEFile, SunAzimuth, SunElev 

    ; If Hill shade file already exists, return
    IF(FILE_TEST(SHADEFile, /READ)) THEN RETURN

    ; Open the DEM File
    ENVI_OPEN_FILE, DEMFile, R_FID = DEM_FID    
    ENVI_FILE_QUERY, DEM_FID, NS = NS, NL = NL, DIMS = DIMS
    DEMProj  = ENVI_GET_PROJECTION(FID = DEM_FID, PIXEL_SIZE = PS)
    ; perform shade relief of a DEM file
    ENVI_DOIT, 'TOPO_DOIT', FID=DEM_FID, POS=0, DIMS=DIMS, BPTR=2, $
               ELEVATION=SunElev,AZIMUTH=SunAzimuth,PIXEL_SIZE=PS, $
               OUT_BNAME='Shade Relief',OUT_NAME=SHADEFile, R_FID=SHD_FID
    ENVI_FILE_MNG, ID=DEM_FID, /REMOVE              
    ENVI_FILE_MNG, ID=SHD_FID, /REMOVE  
    
    FIDS = ENVI_GET_FILE_IDS()
    IF(N_ELEMENTS(FIDS) GE 1) THEN BEGIN
       FOR i = 0, N_ELEMENTS(FIDS) - 1 DO BEGIN
           IF(FIDS[i] NE -1) THEN  ENVI_FILE_MNG, ID = FIDS[i], /REMOVE
       ENDFOR
    ENDIF
    
END
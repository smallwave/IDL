;******************************************************************************
;;
;; $Id: envi45_config/Program/LakeMappingTools/GLOVIS_NDSI_TM_ETM.pro $
;;
;; Author: Junli LI, Geography Department of UCLA, Los Angeles, CA 90095
;+
;; NAME:
;;   GLOVIS_NDSI_TM_ETM
;;
;; PURPOSE:
;;   The procedure caculates NDSI for Landsat TM/ETM+, As SWIR Bands( Band 5 of
;;   Landsat TM/ETM+ sensor) are used, MSS files can't get the NDSI 
;;  
;;                  B4_REF - B5_REF
;;          NDSI = -----------------
;;                  B4_REF + B5_REF
;;
;; PARAMETERS:
;;
;;   LandsatFile (In) - The Landsat TM/ETM+ file .
;;
;;   NDSIFile(in)      - The NDSI file
;;
;; MODIFICATION HISTORY:
;;   Written by:  Junli LI, 2009/04/29 11:40 PM
;-
;******************************************************************************

PRO GLOVIS_NDSI_TM_ETM, LandsatFile, NDSIFile, STR_ERROR
   
   ; First get the Landsat MSS sensor ID
    FileName = FILE_BASENAME(LandsatFile)
    SensorID = STRMID(FileName,9,3)
    ; Different Sensors have different solar irradiance(ESun)
    IF(SensorID EQ 'LT4') THEN ESun = [1983.0,1795.0,1539.0,1028.0,219.8,83.49]
    IF(SensorID EQ 'LT5') THEN ESun = [1983.0,1796.0,1536.0,1031.0,220.0,83.44]
    IF(SensorID EQ 'LE7') THEN ESun = [1997.0,1812.0,1533.0,1039.0,230.8,84.90]
    IF(N_ELEMENTS(ESun) LE 0) THEN BEGIN
       STR_ERROR = FileName + ' : Different Landsat files for our use!'
       RETURN
    ENDIF
    
    ENVI_OPEN_FILE, LandsatFile, R_FID = TM_FID
    ; Get the image basic information of the Landsat images
    ENVI_FILE_QUERY, TM_FID, NB = NB, DIMS = DIMS, BNAMES = BNAMES, $
                     DATA_GAINS=Gains, DATA_OFFSETS=Offsets
    Proj   = ENVI_GET_PROJECTION(FID=TM_FID, PIXEL_SIZE=PS, UNITS=Units)
    MapInfo= ENVI_GET_MAP_INFO(FID=TM_FID)
  
    ; Read the bands
    Band4 = ENVI_GET_DATA(FID=TM_FID, DIMS=DIMS, POS=[3])
    Band5 = ENVI_GET_DATA(FID=TM_FID, DIMS=DIMS, POS=[4])
    ENVI_FILE_MNG, ID = TM_FID,/REMOVE
    
    Mask  = Band4 GT 0
    ; DN to Reflectance 
    Band4 = Mask*FLOAT((Band4*Gains[3]+Offsets[3])*ESun[4])
    Band5 = Mask*FLOAT((Band5*Gains[4]+Offsets[4])*ESun[3])
    Band4 = (Band4 LT 0)*0.001+(Band4 GT 0)*Band4
    Band5 = (Band5 LT 0)*0.001+(Band5 GT 0)*Band5
    
    NDSI_Add = Band4+Band5
    NDSI     = Band4-Band5
    index    = WHERE(NDSI_Add GT 0,nCount)
    
    IF(nCount EQ 0) THEN BEGIN
       STR_ERROR = 'GLOVIS_ETM_NDWI failed!'
       RETURN
    ENDIF
    NDSI[index] = NDSI[index]/NDSI_Add[index]
    ; save to external ENVI file
    FTYPE   = ENVI_FILE_TYPE('ENVI Standard')
    ENVI_ENTER_DATA, NDSI, BNAMES=['NDSI'],FILE_TYPE=FTYPE,MAP_INFO=MapInfo,$
                     PIXEL_SIZE = PS, UNITS = Units, R_FID=NDWI_FID
    ENVI_OUTPUT_TO_EXTERNAL_FORMAT, FID=NDWI_FID,POS=[0],DIMS=DIMS,$
                     OUT_BNAME=['NDSI'], OUT_NAME=NDSIFile, /ENVI
    ENVI_FILE_MNG, ID=NDWI_FID,/REMOVE
    
    FIDS = ENVI_GET_FILE_IDS()
    ncount=N_ELEMENTS(FIDS)
    IF(ncount GE 1) THEN BEGIN
       FOR i = 0, ncount-1 DO BEGIN
           IF(FIDS[i] NE -1) THEN  ENVI_FILE_MNG, ID=FIDS[i], /REMOVE
       ENDFOR
    ENDIF
    STR_ERROR = ''
END
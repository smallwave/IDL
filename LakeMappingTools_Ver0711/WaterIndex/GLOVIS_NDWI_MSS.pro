;*****************************************************************************
;;
;; $Id: envi45_config/Program/LakeMappingTools/GLOVIS_MSS_NDWI.pro $
;;
;; Author: Junli LI, Geography Department of UCLA, Los Angeles, CA 90095
;+
;; NAME:
;;   GLOVIS_MSS_NDWI
;;
;; PURPOSE:
;;   The procedure caculates  NDWI file for Landsat MSS
;;
;; PARAMETERS:
;;
;;   LandsatFile (In) - The Landsat file to be processed (ENVI standard file).
;;
;;   NDWIFile(in)      - The file path of NDWI file
;;
;; MODIFICATION HISTORY:
;;   Written by:  Junli LI, 2009/04/23 11:40 PM
;-
;******************************************************************************

PRO GLOVIS_NDWI_MSS, LandsatFile, NDWIFile, STR_ERROR

; First get the Landsat MSS sensor ID
    FileName = FILE_BASENAME(LandsatFile)
    SensorID = STRMID(FileName,9,3)
    IF(SensorID EQ 'LM1') THEN ESun = [1823.0,1559.0,1276.0,880.1]
    IF(SensorID EQ 'LM2') THEN ESun = [1829.0,1539.0,1268.0,886.6]
    IF(SensorID EQ 'LM3') THEN ESun = [1839.0,1555.0,1291.0,887.9]
    IF(SensorID EQ 'LM4') THEN ESun = [1827.0,1569.0,1260.0,866.4]
    IF(SensorID EQ 'LM5') THEN ESun = [1824.0,1570.0,1249.0,853.4]
    IF(SensorID EQ 'LT4') THEN ESun = [1983.0,1795.0,1539.0,1028.0,219.8,83.49]
    IF(SensorID EQ 'LT5') THEN ESun = [1983.0,1796.0,1536.0,1031.0,220.0,83.44]
    IF(SensorID EQ 'LE7') THEN ESun = [1997.0,1812.0,1533.0,1039.0,230.8,84.90]
    ; Different Sensors have different solar irradiance(ESun)
    idx_b1 = 0
    idx_b4 = 3
    ; Load the Landsat File to get the Band to be calculated
    ENVI_OPEN_FILE, LandsatFile, R_FID = MSS_FID
    ; Get the image basic information of the Landsat images  
    ENVI_FILE_QUERY, MSS_FID, NB=NB, DIMS=DIMS, BNAMES=BNAMES, $
                     DATA_GAINS=Gains, DATA_OFFSETS=Offsets
    MapInfo= ENVI_GET_MAP_INFO(FID=MSS_FID)
  
    ; Read the bands
    Band1 = ENVI_GET_DATA(FID=MSS_FID, DIMS=DIMS, POS=[idx_b1])
    Band4 = ENVI_GET_DATA(FID=MSS_FID, DIMS=DIMS, POS=[idx_b4])
    ENVI_FILE_MNG, ID = MSS_FID,/REMOVE

    Band1 = FLOAT((Band1 LE 0)*0.001+(Band1 GT 0)*(Band1*Gains[idx_b1]+Offsets[idx_b1]))*ESun[idx_b4]
    Band4 = FLOAT((Band4 LE 0)*0.001+(Band4 GT 0)*(Band4*Gains[idx_b4]+Offsets[idx_b4]))*ESun[idx_b1]
    
    NDWI_Add = Band1+Band4
    NDWI     = Band1-Band4
    index    = WHERE(NDWI_Add GT 0,nCount)
    IF(nCount EQ 0) THEN BEGIN
       STR_ERROR = 'GLOVIS_MSS_NDWI failed!'
       return
    ENDIF
    NDWI[index] = NDWI[index]/NDWI_Add[index]
    ; save to external ENVI file
    FTYPE   = ENVI_FILE_TYPE('ENVI Standard')
    ENVI_ENTER_DATA, NDWI, BNAMES=['NDWI'],FILE_TYPE=FTYPE,MAP_INFO=MapInfo,$
                     R_FID=NDWI_FID
    ENVI_OUTPUT_TO_EXTERNAL_FORMAT, FID=NDWI_FID,POS=[0],DIMS=DIMS,$
                     OUT_BNAME=['NDWI'], OUT_NAME=NDWIFile, /ENVI
    ENVI_FILE_MNG, ID=NDWI_FID,/REMOVE
    
    FIDS = ENVI_GET_FILE_IDS()
    ncount=n_elements(FIDS)
    IF(ncount GE 1) THEN BEGIN
       FOR i = 0, ncount-1 DO BEGIN
           IF(FIDS[i] NE -1) THEN  ENVI_FILE_MNG, ID=FIDS[i], /REMOVE
       ENDFOR
    ENDIF
    STR_ERROR = ''
    
END
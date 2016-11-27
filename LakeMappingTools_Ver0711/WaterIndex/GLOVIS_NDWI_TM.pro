;******************************************************************************
;;
;; $Id: envi45_config/Program/LakeMappingTools/GLOVIS_TM_NDWI.pro $
;;
;; Author: Junli LI, Geography Department of UCLA, Los Angeles, CA 90095
;+
;; NAME:
;;   GLOVIS_TM_NDWI
;;
;; PURPOSE:
;;   The procedure caculates  NDWI file for Landsat TM
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

PRO GLOVIS_NDWI_TM, LandsatFile, NDWIFile, STR_ERROR

     ; First get the Landsat TM sensor ID
    FileName = FILE_BASENAME(LandsatFile)
    SensorID = STRMID(FileName,9,3)
    IF(SensorID EQ 'LT4') THEN ESun = [1983.0,1795.0,1539.0,1028.0,219.8,83.49]
    IF(SensorID EQ 'LT5') THEN ESun = [1983.0,1796.0,1536.0,1031.0,220.0,83.44]
    idx_b2 = 1
    idx_b4 = 3
    
    ; Load the Landsat File to get the Band to be calculated
    ENVI_OPEN_FILE, LandsatFile, R_FID = TM_FID
    ; Get the image basic information of the Landsat images
    ENVI_FILE_QUERY, TM_FID, NB = NB, DIMS = DIMS, BNAMES = BNAMES, $
                     DATA_GAINS=Gains, DATA_OFFSETS=Offsets
    Proj   = ENVI_GET_PROJECTION(FID=TM_FID, PIXEL_SIZE=PS, UNITS=Units)
    MapInfo= ENVI_GET_MAP_INFO(FID=TM_FID)
  
    ; Read the bands
    Band2 = ENVI_GET_DATA(FID=TM_FID, DIMS=DIMS, POS=[idx_b2])
    Band4 = ENVI_GET_DATA(FID=TM_FID, DIMS=DIMS, POS=[idx_b4])
    ENVI_FILE_MNG, ID = TM_FID,/REMOVE
   
    ; DN to Reflectance 
    Band2 = FLOAT((Band2*Gains[1]+Offsets[1])*ESun[idx_b4])
    Band4 = FLOAT((Band4*Gains[3]+Offsets[3])*ESun[idx_b2])
    Band2 = (Band2 LT 0)*0.001+(Band2 GT 0)*Band2
    Band4 = (Band4 LT 0)*0.001+(Band4 GT 0)*Band4
    
    NDWI_Add = Band2+Band4
    NDWI     = Band2-Band4
    index    = WHERE(NDWI_Add GT 0,nCount)
    IF(nCount EQ 0) THEN BEGIN
       STR_ERROR = 'GLOVIS_ETM_NDWI failed!'
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
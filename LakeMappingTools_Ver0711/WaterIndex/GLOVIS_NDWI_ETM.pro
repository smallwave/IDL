;******************************************************************************
;;
;; $Id: envi45_config/Program/LakeMappingTools/GLOVIS_ETM_NDWI.pro $
;;
;; Author: Junli LI, Geography Department of UCLA, Los Angeles, CA 90095
;+
;; NAME:
;;   GLOVIS_ETM_NDWI
;;
;; PURPOSE:
;;   The procedure caculates  NDWI file for Landsat ETM+
;;
;;                  B2_REF - B4_REF
;;          NDWI = -----------------
;;                  B2_REF + B4_REF
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

PRO GLOVIS_NDWI_ETM, LandsatFile, NDWIFile, STR_ERROR

    ; solar irradiance(ESun) for Band 2 and Band 4
    ESun = [1997.0,1812.0,1533.0,1039.0,230.8,84.90]
    idx_b2 = 1
    idx_b4 = 3
    
    ENVI_OPEN_FILE, LandsatFile,/NO_INTERACTIVE_QUERY,/NO_REALIZE, R_FID = TM_FID
    ; Get the image basic information of the Landsat images
    ENVI_FILE_QUERY, TM_FID, NB = NB, DIMS = DIMS, BNAMES = BNAMES, $
                     DATA_GAINS=Gains, DATA_OFFSETS=Offsets
    MapInfo= ENVI_GET_MAP_INFO(FID=TM_FID)
    
    ; Read the bands
    Band2 = ENVI_GET_DATA(FID=TM_FID, DIMS=DIMS, POS=[idx_b2])
    Band4 = ENVI_GET_DATA(FID=TM_FID, DIMS=DIMS, POS=[idx_b4])
    ENVI_FILE_MNG, ID = TM_FID,/REMOVE
    
    ; DN to Reflectance 
    Band2 = FLOAT((Band2*Gains[1]+Offsets[1])*ESun[idx_b4])
    Band4 = FLOAT((Band4*Gains[3]+Offsets[3])*ESun[idx_b2])
    Band2 = (Band2 LT 0)*0.001+(Band2 gt 0)*Band2
    Band4 = (Band4 LT 0)*0.001+(Band4 gt 0)*Band4
    
    NDWI_Add = Band2+Band4
    NDWI     = Band2-Band4
    index    = WHERE(NDWI_Add gt 0,nCount)
    if(nCount eq 0) then begin
       STR_ERROR = 'GLOVIS_ETM_NDWI failed!'
       return
    endif
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
    if(ncount ge 1) then begin
       for i = 0, ncount-1 DO begin
           if(FIDS[i] NE -1) then  ENVI_FILE_MNG, ID=FIDS[i], /REMOVE
       endfor
    endif
    STR_ERROR = ''
END
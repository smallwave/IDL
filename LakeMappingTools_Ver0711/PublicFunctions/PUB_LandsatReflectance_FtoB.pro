;******************************************************************************
;; $Id: envi45_config/Program/LakeExtraction/PUB_LandsatReflectance_FtoB.pro $
;;
;; Author: Junli LI, Geography Department of UCLA, Los Angeles, CA 90095
;+
;; NAME:
;;   PUB_LandsatReflectance_FtoB
;;
;; PURPOSE:
;;   The function transfer image data from float type to byte format
;;    
;;
;; PARAMETERS:
;;
;;   RefFileName (in)  - the reflectance file with float file format REF [0~1]
;;
;;   BYTEFileName(in)   - the image data with byte file format
;;
;;
;; MODIFICATION HISTORY:
;;    Written by:  Junli LI, 2009/04/29 06:00 PM
;-
;******************************************************************************

Pro PUB_LandsatReflectance_FtoB, RefFileName, BYTEFileName
  
    ; Load the Landsat Files
    ENVI_OPEN_FILE, RefFileName, R_FID = REF_FID
    IF(REF_FID EQ -1) THEN BEGIN
       RETUEN
    ENDIF
       
    ; [2.1] Width, Height, Band dimensions,starting sample and row of the image
    ENVI_FILE_QUERY, REF_FID, NB=NB, NS=NS, NL=NL, DIMS=DIMS,BNAMES=BNAMES
    ; Map information
    MapInfo  = ENVI_GET_MAP_INFO(FID=REF_FID)
    ; Projection information
    Proj     = ENVI_GET_PROJECTION(FID=REF_FID, PIXEL_SIZE=PS)
   
    ; Load the data
    nBand = FLTARR(NS,NL,NB)
    FOR i=0,NB-1 DO nBand[*,*,i] = ENVI_GET_DATA(FID=REF_FID,DIMS=DIMS, POS=[i])
    nBand    = BYTE(nBand*255) 
    ENVI_ENTER_DATA, nBand, MAP_INFO=MapInfo, R_FID=BYTE_FID
    ENVI_FILE_QUERY, BYTE_FID, DIMS=nDIMS
    nPOS     = LINDGEN(NB) 
    ENVI_OUTPUT_TO_EXTERNAL_FORMAT, FID=BYTE_FID,POS=nPOS,DIMS=nDIMS,$
                           OUT_BNAME=BNAMES, OUT_NAME=BYTEFileName, /ENVI
    
    ENVI_FILE_MNG,ID=BYTE_FID, /REMOVE                  
    ENVI_FILE_MNG,ID=REF_FID,  /REMOVE
    ; remove all the FIDs in the file lists
    FIDS = ENVI_GET_FILE_IDS()
    FOR i = 0, N_ELEMENTS(FIDS) - 1 DO BEGIN
        IF(FIDS[i] NE -1) THEN  ENVI_FILE_MNG, ID = FIDS[i], /REMOVE
    ENDFOR
END
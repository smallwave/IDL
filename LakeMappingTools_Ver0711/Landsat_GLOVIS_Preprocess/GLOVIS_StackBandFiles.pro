;*******************************************************************************
;; $Id: envi45_config/Program/LakeMappingTools/GLOVIS_StackBandFiles
;;
;; Author: Junli LI, Geography Department of UCLA, Los Angeles, CA 90095
;+
;; NAME:
;;   GLOVIS_StackBandFiles
;;
;; PURPOSE:
;;   The function stack the Landsat band files into one ENVI standard file.
;;
;; PARAMETERS:
;;
;;   BandFileNames(In) - 6 Landsat band files, Band1-Band5, Band7
;;
;;   BandFileCount(In) - Band file number, here is 6.
;;
;;   LandsatMetFile(In)- The meta file of the Landsat data
;;
;;   SensorID(In)      - ID of landsat file- LM1/LM2/LM3/LM4/LM5/LT4/LT5/LE7.
;;
;;   StackNames(In)    - File path of the band-stacked landsat image .
;;
;; CALLING PROCEDURES:
;;
;;   GLOVIS_LandsatFiles_ZIPtoENVI: Generate ENVI files from GLOVIS zip files 
;;     
;; CALLING CUSTOM-DEFINED FUNCTIONS:  
;;
;;   GLOVIS_FileHeaderEdit : Add the meta file to the ENVI header file
;;
;; MODIFICATION HISTORY:
;;   Written by:  Junli LI, 2008/11/15 06:00 PM
;;   Modified  :  Junli LI, 2009/04/01 12:00 AM
;-
;*******************************************************************************
;
FUNCTION GLOVIS_StackBandFiles, BandFileNames, nBands, LandsatMetaFile, $
                                SensorID, StackNames, ERR_String
                                
    ; Get the initial
    nFIDs        = lonarr(nBands)
    nPOS         = lonarr(nBands)
    
    ;**************************************************************************
    ; [1] Load the TIFF band Files of the BandFileNames
    ;**************************************************************************
    FOR i=0, nBands-1 DO BEGIN
       ENVI_OPEN_FILE, BandFileNames[i], R_FID = t_fid
       IF(i EQ 0) THEN BEGIN
          ENVI_FILE_QUERY, t_fid, NS=NS, NL=NL, DIMS=DIMS,DATA_TYPE=DT
          MapInfo  = ENVI_GET_MAP_INFO(FID = fid)
       ENDIF ELSE BEGIN
          ENVI_FILE_QUERY, t_fid, NS=Width, NL=Height, DIMS=DIMS, DATA_TYPE=Type
          IF((Width NE NS) OR (Height NE NL) OR (Type NE DT)) THEN BEGIN
             ERR_String = BandFileNames[i] + ':has different size with others'
             RETURN, 0
          ENDIF
       ENDELSE
       ; Set the variables for layer stacking
       nFIDs[i]  = t_fid
       nPOS[i]   = i
    ENDFOR
    
    ;**************************************************************************
    ; [2] Set the attribute and output the band stacked file
    ;**************************************************************************
    
    ; Load the data
    nData = BYTARR(NS,NL,nBands)
    MASK  = BYTARR(NS,NL)
    MASK  = MASK EQ 0
    BandNames = STRARR(nBands)
    FOR i=0,nBands-1 DO BEGIN
        Band = ENVI_GET_DATA(FID = nFIDs[i],DIMS=DIMS, POS=[0])
        MASK = MASK AND (Band GT 0)
        nData[*,*,i] = Band
        IF(i LT 5) THEN BandNames[i] = 'Band '+STRTRIM(STRING(i+1),2) $
        ELSE BandNames[i] = 'Band '+STRTRIM(STRING(i+2),2)
        ENVI_FILE_MNG, ID = nFIDs[i], /REMOVE, /DELETE
    ENDFOR
    
    ; smooth the Mask boundary, in order to get the regular edge of the image 
    
    MASK = GLOVIS_SmoothImageMask(MASK)
    
    FOR i=0,nBands-1 DO nData[*,*,i] = nData[*,*,i] * MASK
    
    ; Write the file
    ENVI_ENTER_DATA, nData, MAP_INFO=MapInfo, R_FID=STACK_FID
    ENVI_FILE_QUERY, STACK_FID, DIMS=nDIMS
    ENVI_OUTPUT_TO_EXTERNAL_FORMAT, FID=STACK_FID,POS=nPOS,DIMS=nDIMS,$
                           OUT_BNAME=BandNames, OUT_NAME=StackNames, /ENVI           
    ; Close all the open Files
    FIDS = ENVI_GET_FILE_IDS()
    FOR i = 0, N_ELEMENTS(FIDS) - 1 DO BEGIN
        IF(FIDS[i] NE -1) THEN  ENVI_FILE_MNG, ID = FIDS[i], /REMOVE
    ENDFOR
   
    ; Read sensor info from LandsatMetaFile and edit the ENVI header file
    ENVI_OPEN_FILE, StackNames, R_FID = STACK_FID
    GLOVIS_FileHeaderEdit, STACK_FID, SensorID, LandsatMetaFile
    ENVI_FILE_MNG, ID = STACK_FID, /REMOVE
    RETURN, 1
END
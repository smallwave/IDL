;*****************************************************************************
;; $Id: envi45_config/Program/LakeMappingTools/MAPPINT_GetDEMandSHADEBand.pro $
;;
;; Author: Junli LI, Geography Department of UCLA, Los Angeles, CA 90095
;+
;; NAME:
;;   MAPPINT_GetDEMandSHADEBand
;;
;; PURPOSE:
;;   This procedure gets DEM and shade bands from Files, make sure the DIMS of 
;;   DEM and Shade band have the same size
;;
;; PARAMETERS:
;;
;;   Landsat_FID(in)      - handle of landsat file
;;
;;   DEM_UTMZone_DIR(in)  - The directroy of DEM files with UTM projection
;;
;;   DEM_LatLon_File(in)  - The DEM files(Whole region) with Lat/Lon projection
;;
;; CALLING CUSTOM-DEFINED FUNCTIONS:  WaterExtraction
;;
;; PROCEDURES OR FUNCTIONS CALLED:   
;;
;; MODIFICATION HISTORY:
;;
;;  Written by:  Junli LI, 2008/10/08 12:00 AM
;;  
;-
;*****************************************************************************

FUNCTION MAPPING_GetDEMandSHADEBand,DEMFile,ShadeFile,DEM=DEMBand,SHADE=ShadeBand
    
    ; Catch Error
    STR_ERROR = ''
    CATCH, Error_status 
    ; This statement begins the error handler: 
    IF Error_status NE 0 THEN BEGIN 
       STR_ERROR = STRING(Error_status) + ' :' + !ERROR_STATE.MSG
       PRINT, STR_ERROR
       CATCH, /CANCEL 
       RETURN, 0
    ENDIF
    
    ;***************************************************************************
    ; [1] Load the Shade file
    ;***************************************************************************
    ENVI_OPEN_FILE, ShadeFile, R_FID=SHADE_FID
    ; get info of the Landsat file
    ENVI_FILE_QUERY, SHADE_FID, NS=Width, NL=Height, DIMS=DIMS
    ; projection information
    Proj       = ENVI_GET_PROJECTION(FID=SHADE_FID, PIXEL_SIZE=PS)
    ShadeBand  = ENVI_GET_DATA(FID=SHADE_FID, DIMS=DIMS, POS=[0])
    
    ;***************************************************************************
    ; [2] Subset the DEM Band from the DEM Files 
    ;***************************************************************************
    ENVI_OPEN_FILE, DEMFile, R_FID=DEM_FID
    ENVI_FILE_QUERY, DEM_FID, NS=DEM_Width, NL=DEM_Height, DIMS=DEM_DIMS
    DEMProj   = ENVI_GET_PROJECTION(FID=DEM_FID, PIXEL_SIZE=DEM_PS)
    
    ; If the pixel size of the DEM file and Shade file is different then return
    IF(PS[0] NE DEM_PS[0] OR PS[1] NE DEM_PS[1]) THEN BEGIN
       ENVI_FILE_MNG, ID=DEM_FID, /REMOVE
       ENVI_FILE_MNG, ID=SHADE_FID, /REMOVE
       RETURN, 0
    ENDIF
    
    ; If the DIMS of the two files is the same, 
    IF(Width EQ DEM_Width AND Height EQ DEM_Height) THEN BEGIN
       DEMBand = ENVI_GET_DATA(FID=DEM_FID, DIMS=DIMS, POS=[0])
    ENDIF
    
    IF(DEM_Width GT Width AND DEM_Height GT Height) THEN BEGIN
       ; Get the map coordinates of image Rect
       xPix       = [0, Width-1]
       yPix       = [0, Height-1]
       ; Tranform pixel coordinates to map coordinates
       ENVI_CONVERT_FILE_COORDINATES, SHADE_FID, xPix, yPix, xMap, yMap, /TO_MAP
       ; Tranform map coordinates to pixel coordinates
       ENVI_CONVERT_FILE_COORDINATES, DEM_FID, xPix, yPix, xMap, yMap
       
       x_MIN      = ROUND(MIN(xPix),/L64)
       x_MAX      = x_MIN+Width-1
       y_MIN      = ROUND(MIN(yPix),/L64)
       y_MAX      = y_MIN+Height-1
       DIMS       = [-1,x_MIN,x_MAX,y_MIN,y_MAX]
       IF(x_MIN LT 0 OR x_MAX GE DEM_Width OR y_MIN LT 0 OR y_MAX GE DEM_Height)$
       THEN BEGIN
          ENVI_FILE_MNG, ID=DEM_FID, /REMOVE
          ENVI_FILE_MNG, ID=SHADE_FID, /REMOVE
          RETURN, 0
       ENDIF
       DEMBand    = ENVI_GET_DATA(FID=DEM_FID, DIMS=DIMS, POS=[0])
    ENDIF
    ENVI_FILE_MNG, ID=DEM_FID, /REMOVE
    ENVI_FILE_MNG, ID=SHADE_FID, /REMOVE
    RETURN, 1 
      
END
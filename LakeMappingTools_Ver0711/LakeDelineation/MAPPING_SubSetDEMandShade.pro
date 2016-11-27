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

FUNCTION MAPPING_SubSetDEMandShade, DEMFile,Landsat_FID,DEM=DEMBand,SHADE=ShadeBand
                                    
    
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
    ; [1] Load the Landsat file
    ;***************************************************************************
   ; ENVI_OPEN_FILE, LandsatFile, R_FID=Landsat_FID
    ; get info of the Landsat file
    ENVI_FILE_QUERY, Landsat_FID, NS=NS, NL=NL, DIMS=DIMS
    ; projection information
    Proj       = ENVI_GET_PROJECTION(FID=Landsat_FID, PIXEL_SIZE=PS)
    ; Get the sun azimuth and sun elevation angles from the Landsat header file
    SunAzimuth = ENVI_GET_HEADER_VALUE(Landsat_FID, 'sun azimuth angle',/FLOAT,$
                                        UNDEFINED=1)
    SunElev    = ENVI_GET_HEADER_VALUE(Landsat_FID,'sun elevation angle',/FLOAT,$
                                        UNDEFINED=1) 
    IF(SunAzimuth EQ -1 OR SunElev EQ -1) THEN RETURN, 0
    
    
    ;***************************************************************************
    ; [2] Subset the DEM Band from the DEM Files 
    ;***************************************************************************
    ENVI_OPEN_FILE, DEMFile, R_FID=DEM_FID
    ENVI_FILE_QUERY, DEM_FID, NS=DEM_NS, NL=DEM_NL, DIMS=DEM_DIMS
    DEMProj    = ENVI_GET_PROJECTION(FID=DEM_FID, PIXEL_SIZE=DEM_PS)
    
    ; Perform shade relief of a DEM file
    ENVI_DOIT, 'TOPO_DOIT', FID=DEM_FID, POS=0, DIMS=DEM_DIMS, BPTR=2, $
               ELEVATION=SunElev, AZIMUTH=SunAzimuth,PIXEL_SIZE=DEM_PS, $
               IN_MEMORY=1, R_FID=Shade_FID 
    
    ; If the DEM file has the same dimesion with Landsat
    IF(NS EQ DEM_NS AND NL EQ DEM_NL) THEN BEGIN
      DEMBand  = ENVI_GET_DATA(FID=DEM_FID,  DIMS=DIMS, POS=[0])
      ShadeBand= ENVI_GET_DATA(FID=Shade_FID,DIMS=DIMS, POS=[0])
      ENVI_FILE_MNG,ID=DEM_FID, /REMOVE
      ENVI_FILE_MNG,ID=Shade_FID, /REMOVE
;      ENVI_FILE_MNG,ID=Landsat_FID, /REMOVE
      RETURN, 1
    ENDIF
    
    ; Or subset the image
    ; Get the map coordinates of image Rect
    xPix       = [0, NS-1]
    yPix       = [0, NL-1]
    ; Tranform pixel coordinates to map coordinates
    ENVI_CONVERT_FILE_COORDINATES, Landsat_FID, xPix, yPix, xMap, yMap, /TO_MAP
    ; Tranform map coordinates to pixel coordinates
    ENVI_CONVERT_FILE_COORDINATES, DEM_FID, xPix, yPix, xMap, yMap
    ; Get the subset dimension   
    x_MIN      = ROUND(MIN(xPix),/L64)
    x_MAX      = ROUND(MAX(xPix),/L64)
    y_MIN      = ROUND(MIN(yPix),/L64)
    y_MAX      = ROUND(MAX(yPix),/L64)
    DIMS       = [-1,x_MIN,x_MAX,y_MIN,y_MAX]
    IF(x_MIN LT 0 OR x_MAX GE DEM_NS OR y_MIN LT 0 OR y_MAX GE DEM_NL) THEN BEGIN
       ENVI_FILE_MNG,ID=DEM_FID,    /REMOVE
       ENVI_FILE_MNG,ID=Shade_FID,  /REMOVE
;       ENVI_FILE_MNG,ID=Landsat_FID,/REMOVE
       RETURN, 0
    ENDIF
    DEM        = ENVI_GET_DATA(FID=DEM_FID,  DIMS=DIMS, POS=[0])
    Shade      = ENVI_GET_DATA(FID=Shade_FID,DIMS=DIMS, POS=[0])
    DEMBand    = CONGRID(TEMPORARY(DEM),  NS, NL, /INTERP)
    ShadeBand  = CONGRID(TEMPORARY(Shade),NS, NL, /INTERP)
    
    ENVI_FILE_MNG,ID=DEM_FID,    /REMOVE
    ENVI_FILE_MNG,ID=Shade_FID,  /REMOVE
;    ENVI_FILE_MNG,ID=Landsat_FID,/REMOVE
    RETURN, 1 
      
END
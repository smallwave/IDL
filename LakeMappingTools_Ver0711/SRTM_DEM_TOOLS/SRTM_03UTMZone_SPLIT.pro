;*****************************************************************************
;; $Id: envi45_config/Program/LakeExtraction/SRTM_03UTMZone_SPLIT.pro $
;;
;; Author: Junli LI, Geography Department of UCLA, Los Angeles, CA 90095
;+
;; NAME:
;;   SRTM_03UTMZone_SPLIT
;;
;; PURPOSE:
;;   This procedure generate DEM subset files with UTM zone spatial extent 
;;
;; PARAMETERS:
;;
;;   DEMFile(in)        - The DEM File with Lat/Long Projection
;;
;;   DEM_SubFile(in)    - The Subset file from DEM 
;;
;;   UTMZoneN(in)       - UTM Zone Number(Tibet are in range of UTM North
;;                        44 45 46, so the UTMZoneN is 44, 45, 46)
;;
;;   LatLong_RANGEs(in) - The ouput directory of lake vector files 
;;
;; MODIFICATION HISTORY:
;;
;;  Written by:  Junli LI, 2008/10/08 11:00 AM
;;  Modified  :  Junli LI, 2008/10/08 06:40 PM,
;-
;*****************************************************************************
PRO SRTM_03UTMZone_SPLIT, DEMFile, DEM_SubFile, UTMZoneN, LatLong_RANGE
    
    
    ;;########################################################################
    ;;************************* For procedure test *************************** 
      DEMFile         = 'E:\LandsatETM_Tibet\SRTM\SRTM_Tibet'
      DEM_SubFile     = 'E:\LandsatETM_Tibet\SRTM\DEM_UTMZone46'
      UTMZoneN        = 46   
      LatLong_RANGE   = [27,39,88,95]
      ; UTM_ZONE_44   = [27,39,77,86]
      ; UTM_ZONE_45   = [27,39,82,92]
      ; UTM_ZONE_46   = [27,39,88,95]
    ;************************* For procedure test *************************** 
    ; ########################################################################
    
    ; Find SRTM files in the give directory
    ENVI_OPEN_FILE, DEMFile, R_FID = DEM_FID
    ENVI_FILE_QUERY, DEM_FID, NS = Width, NL = Height
    
    ; Define the input projection and output projection
    
    ; input projection from the DEM file
    iProj = ENVI_GET_PROJECTION(FID=DEM_FID)
    
    ; output projection from the UTM zone number
    UNITS = ENVI_TRANSLATE_PROJECTION_UNITS('Meters')  
    DATUM = 'WGS-84'
    oProj = ENVI_PROJ_CREATE(/UTM, ZONE=UTMZoneN, DATUM=DATUM, UNITS=UNITS) 
   
    ; Define the spatial extent 
    Lat_MIN = LatLong_RANGE[0]
    Lat_MAX = LatLong_RANGE[1]
    Lon_MIN = LatLong_RANGE[2]
    Lon_MAX = LatLong_RANGE[3]
     
    ; Convert the Lat/Long coordinates to pixel coordinates
    xMap  = [Lon_MIN, Lon_MAX]
    yMap  = [Lat_MAX, Lat_MIN]
    ENVI_CONVERT_FILE_COORDINATES, DEM_FID, xPix, yPix, xMap, yMap
    x_MAX = LONG(MAX(xPix))
    x_MIN = LONG(MIN(xPix))
    y_MAX = LONG(MAX(yPix))
    y_MIN = LONG(MIN(yPix))
    
    ; Get the Subset spatial ranges 
    x_MAX = (x_MAX GT Width-1) ? Width-1 : x_MAX
    x_MIN = (x_MIN GT 0)? x_MIN : 0
    y_MAX = (y_MAX GT Height-1) ? Height-1 : y_MAX
    y_MIN = (y_MIN GT 0)? y_MIN : 0
    DIMS  = [-1,x_MIN,x_MAX,y_MIN,y_MAX]
    POS   = [0]
    
    PixSiz  = [30, 30]
    BNAMES  = 'DEM_' + STRTRIM(STRING(UTMZoneN),2)
    ; Reprojection 
    OUT_NAME = DEM_SubFile
    ENVI_CONVERT_FILE_MAP_PROJECTION, FID=DEM_FID, POS=POS, DIMS=DIMS,$
                    O_PROJ=oProj, O_PIXEL_SIZE=PixSiz, GRID=[25,25],$
                    OUT_BNAME=BNAMES, WARP_METHOD=2,RESAMPLING=1, $
                    BACKGROUND=0, OUT_NAME=OUT_NAME, R_FID=Proj_FID
        
    ENVI_FILE_MNG, ID=Proj_FID, /REMOVE 
    ENVI_FILE_MNG, ID=DEM_FID, /REMOVE
    
END
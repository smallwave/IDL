;******************************************************************************
;; $Id: envi45_config/Program/LakeMappingTools/SRTM_CreateDEMFromLandsatExt.pro $
;;
;; Author: Junli LI, Geography Department of UCLA, Los Angeles, CA 90095
;+
;; NAME:
;;   SRTM_CreateDEMFromLandsatExt
;;
;; PURPOSE:
;;   The procedure create DEM from SRTM file, for each landsat file. The spatial
;;   extent of the DEM is the same as that of the Landsat file. 
;;
;; PARAMETERS:
;;   LandsatFile(in)   - input Landsat file path
;;
;;   SRTMFile(in)      - input SRTM file path
;;
;;   DEMFile(in)       - input subseted DEM file path
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

PRO SRTM_CreateDEMFromLandsatExt, LandsatFile, SRTMFile, DEMFile

    ; If DEM file already exists, return
    IF(FILE_TEST(DEMFile, /READ)) THEN RETURN
    
    ;**************************************************************************
    ; 1) Load the input file
    ;***************************************************************************
    ENVI_OPEN_FILE, LandsatFile, R_FID = TM_FID
    ; Open the SRTM File
    ENVI_OPEN_FILE, SRTMFile, R_FID = SRTM_FID

    ;**************************************************************************
    ; 2) Get the project information of the Landsat images and SRTM images
    ;***************************************************************************

    ENVI_FILE_QUERY, TM_FID, NS=ImageWidth, NL=ImageHeight, NB=NB, DIMS=DIMS
    ENVI_FILE_QUERY, SRTM_FID, NS = SRTMWidth, NL = SRTMHeight
    ; the map information structure
    ImageMapinfo  = ENVI_GET_MAP_INFO(FID = TM_FID)
    ; the projection information
    ImgProj       = ENVI_GET_PROJECTION(FID = TM_FID, PIXEL_SIZE = ImgPixSiz)
    ; the projection information
    SRTMProj      = ENVI_GET_PROJECTION(FID = SRTM_FID, PIXEL_SIZE = SRTMPixSiz)
    
    ;**************************************************************************
    ; 3)  Subset the SRTM image use the range of the Image map range. In order 
    ;     to get it, follow these three steps
    ;     (1) Get the Map ranges of the Landsat image files
    ;     (2) Convert Map coordinates from UTM projections to Geographic Lat/Lon
    ;     (3) Convert Map cooridnates to pixel coordinates of the SRTM files
    ;**************************************************************************
    
    ; Convert x,y pixel coordinates of the Image to map coordinates
    xPix = [0, ImageWidth-1]
    yPix = [0, ImageHeight-1]
    ENVI_CONVERT_FILE_COORDINATES, TM_FID, xPix, yPix, xMap, yMap, /TO_MAP
    ; Convert map coordinates of the Image from the UTM to geographic Lat/Lon
    ENVI_CONVERT_PROJECTION_COORDINATES,xMap,yMap,ImgProj,xLon,yLat,SRTMProj
    ; Convert map coordinates of the subset range to pixel coordinates in SRTM
    xLon_Expand = [xLon[0]-0.5, xLon[1]+0.5]
    yLat_Expand = [yLat[0]+0.5, yLat[1]-0.5]
    ENVI_CONVERT_FILE_COORDINATES, SRTM_FID,xSRTM,ySRTM,xLon_Expand,yLat_Expand
    xSRTM = LONG(xSRTM)
    ySRTM = LONG(ySRTM)
    
    ; Adjust the subset extent of the SRTM so as to make it with the spatial 
    ; extent of SRTM files
    IF(xSRTM[0] GE SRTMWidth OR ySRTM[0] GE SRTMHeight OR xSRTM[1] LT 0 $
       OR ySRTM[1] LT 0) THEN RETURN
    IF(xSRTM[0] LT 0) THEN xSRTM[0] = 0
    IF(xSRTM[1] GE SRTMWidth) THEN xSRTM[1] = SRTMWidth-1
    IF(ySRTM[0] LT 0) THEN ySRTM[0] = 0
    IF(ySRTM[1] GE SRTMHeight) THEN ySRTM[1] = SRTMHeight-1
    ; Close the Landsat file
    ENVI_FILE_MNG, ID = TM_FID, /REMOVE
    ; Get the SRTM data in the map range of xDEM and yDEM
    SRTM_DIMS = [-1, xSRTM[0],xSRTM[1], ySRTM[0], ySRTM[1] ]

    ;**************************************************************************
    ; 4) Convert the projection of the SRTM from Geography Lat/Lon to UTM 
    ;    projection of the Landsat image files
    ;**************************************************************************
    TypeSuf  = STRMID(SRTMFile,STRLEN(SRTMFile)-4,4) 
    IF(TypeSuf EQ '.dat' ) THEN FileName = STRMID(SRTMFile,0,STRLEN(SRTMFile)-4) $
    ELSE FileName = SRTMFile
    tmpFile  = FileName + '_tmp'
    ENVI_CONVERT_FILE_MAP_PROJECTION, FID = SRTM_FID, POS=0, DIMS = SRTM_DIMS,$
               O_PROJ = ImgProj, O_PIXEL_SIZE = ImgPixSiz, GRID = [80,80], $
               OUT_NAME=tmpFile, WARP_METHOD=2, RESAMPLING=1, BACKGROUND=0,$
               R_FID=tmp_FID
    ; Close the SRTM file
    ENVI_FILE_MNG, ID = SRTM_FID, /REMOVE

    ;**************************************************************************
    ; 5) SubSet the tmp files and smooth the DEM use median filters
    ;**************************************************************************
    ; Convert map coordinates of to  pixel coordinates of the tmpfile
    ENVI_CONVERT_FILE_COORDINATES, tmp_FID, xPix, yPix, xMap, yMap
    xPix = uint(xPix)
    yPix = uint(yPix)
    DEM_DIMS = [-1L, xPix[0],xPix[0]+ImageWidth-1, yPix[0], yPix[0]+ImageHeight-1]
    ENVI_OUTPUT_TO_EXTERNAL_FORMAT, FID=tmp_FID,POS=[0],DIMS=DEM_DIMS,$
                     OUT_BNAME='DEM', OUT_NAME=DEMFile, /ENVI         
    ; Close the tmp file
    ENVI_FILE_MNG, ID = tmp_FID, /REMOVE, /DELETE
    
    ; remove all the FIDs in the file lists
    FIDS = ENVI_GET_FILE_IDS()
    IF(N_ELEMENTS(FIDS) GE 1) THEN BEGIN
       FOR i = 0, N_ELEMENTS(FIDS) - 1 DO BEGIN
           IF(FIDS[i] NE -1) THEN  ENVI_FILE_MNG, ID=FIDS[i], /REMOVE
       ENDFOR
    ENDIF
    
END
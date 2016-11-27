
;*****************************************************************************
;; $Id:  envi45_config/Program/LakeMappingTools/WATERMASK_CreateLandsatMask
;;
;; Author: Junli LI, Geography Department of UCLA, Los Angeles, CA 90095
;+
;; NAME:
;;   WATERMASK_CreateLandsatMask
;;
;; PURPOSE:
;;   The function create the spatial extent mask file mask for GLOVIS Landsat 
;;   File, the mask need the remove the sea pixels
;;
;; PARAMETERS:
;;
;;   LandsatFile (In) - GLOVIS Landsat file 
;;
;;   MaskFile (in)    - Landsat Extent file
 ;;
;; CALLING CUSTOM-DEFINED FUNCTIONS:  MAIN_LandsatExtentMask
;;
;; MODIFICATION HISTORY:
;;
;;  Written by:  Junli LI, 2009/04/29 06:00 PM
;;  
;-
;*****************************************************************************
;

PRO WATERMASK_CreateLandsatMask, LandsatFile,NDWIFile,Parts,SeaEdges,MaskFile,$
                                 ERROR=STR_ERROR    

    STR_ERROR = ''
    CATCH, Error_status 
    ; This statement begins the error handler: 
    IF Error_status NE 0 THEN BEGIN 
       STR_ERROR = STRING(Error_status) + ' :' + !ERROR_STATE.MSG
       CATCH, /CANCEL 
       RETURN
    ENDIF 
    
    ;**************************************************************************
    ;
    ; 1)  Load the image data and get general image information
    ;
    ;**************************************************************************
    
    ; Get info from input file names, such as PathRow, Sensor and AcqDate
    FileName    = FILE_BASENAME(LandsatFile)
    ; WRS 1/2 Path and Row info
    sPath       = STRMID(FileName,1,3)
    sRow        = STRMID(FileName,5,3)
    ; Sensor
    SensorID    = STRMID(FileName,9,3)
    Sensor      = GLOVIS_SensorType(FileName)
    ; Acq Date
    AcqDate     = STRMID(FileName,13,8)
    
    ; Load the raster file to memory and get the basic image information
    ENVI_OPEN_FILE,LandsatFile,/NO_INTERACTIVE_QUERY,/NO_REALIZE,R_FID=Landsat_FID
    IF(Landsat_FID EQ -1) THEN BEGIN
       STR_ERROR= LandsatFile + ': could not open it, please check it!'
       RETURN
    ENDIF
    ENVI_FILE_QUERY, Landsat_FID,NS=Width,NL=Height,DIMS=DIMS
    ; map information
    MapInfo     = ENVI_GET_MAP_INFO(FID=Landsat_FID)
    ; projection information
    Proj        = ENVI_GET_PROJECTION(FID=Landsat_FID,PIXEL_SIZE=PixSiz,UNITS=Units)
    ; Band info
    Band1       = ENVI_GET_DATA(FID=Landsat_FID, DIMS=DIMS, POS=[0])
    ImageMask   = Band1 GT 0
    
    ; Load the NDWI file
    ENVI_OPEN_FILE, NDWIFile,/NO_INTERACTIVE_QUERY,/NO_REALIZE, R_FID=NDWI_FID
    NDWI = ENVI_GET_DATA(FID=NDWI_FID, DIMS=DIMS, POS=[0])
    IF(SensorID EQ 'LM1' OR SensorID EQ 'LM2' OR SensorID EQ 'LM3' OR $
       SensorID EQ 'LM4' OR SensorID EQ 'LM5' ) THEN BEGIN 
          NDWI = MEDIAN(NDWI, 3) 
    ENDIF
    ENVI_FILE_MNG, ID=NDWI_FID, /REMOVE
    NDWIMask = NDWI GE 0.05
       
    ;**************************************************************************
    ;
    ; 2)  Create the Image Mask
    ;
    ;**************************************************************************
    siz        = SIZE(Parts,/DIMENSIONS)
    PartCnt    = siz[0]
    siz        = SIZE(SeaEdges,/DIMENSIONS)
    VerticeCnt = siz[1]
    
    IF(Parts[0] GE 0) THEN BEGIN
      SeaIdx   = LONARR(Width*Height)
      SeaCount = 0
      iProj= ENVI_PROJ_CREATE(/GEOGRAPHIC)
      FOR i=0L,PartCnt-1 DO BEGIN
         j1   = Parts[i]
         IF(i LT PartCnt-1) THEN j2 = Parts[i+1]-1 ELSE j2 = VerticeCnt-1
         xmap = SeaEdges[0, j1:j2]
         ymap = SeaEdges[1, j1:j2]
         ENVI_CONVERT_PROJECTION_COORDINATES,xmap,ymap,iProj,x_oMap,y_oMap,Proj
         ENVI_CONVERT_FILE_COORDINATES,Landsat_FID, xf, yf, x_oMap, y_oMap
         ; Get the indexes of the whole region, so we can get the region ID
         Idx = POLYFILLV(xf, yf, Width, Height)
         siz = SIZE(Idx,/DIMENSIONS)
         SeaIdx[SeaCount]=Idx
         SeaCount = SeaCount+siz[0]
      ENDFOR
      SeaIdx = SeaIdx[0:SeaCount-1]   
    ENDIF ELSE SeaIdx = [0]
    
    ; Get the Mask of the LandsatFile
    ImageMask=MASK_CreateNonZeroMask(Landsat_FID, NDWIMask, SeaIdx)
    

    ;**************************************************************************
    ;
    ; 2) Create the Mask file
    ;
    ;**************************************************************************
    
    ; [1] Create a classification layer and output it to external format
    CLASS_NAMES     = ['Unclassified','Mask']
    DESCRIP         = 'Landsat Spatial Extent Mask'
    LOOKUP          = [[0,0,0],[0,132,168]]
    BAND_NAME       = ['Spatial Extent']
    FILE_TYPE       = ENVI_FILE_TYPE('ENVI STANDARD')
    IN_MEMORY       = LONARR(1)
    ; Create a classification layer
    ENVI_ENTER_DATA, ImageMask, BNAMES=BAND_NAME, NUM_CLASSES=2, LOOKUP=LOOKUP,$
                CLASS_NAMES=CLASS_NAMES, DESCRIP=DESCRIP, FILE_TYPE=FILE_TYPE,$ 
                MAP_INFO=MapInfo, R_FID=MASK_FID
    ENVI_FILE_QUERY, MASK_FID, DIMS=DIMS
    
    ; [2] Raster-to-Vector file conversion
    EVFMaskFile = STRMID(MaskFile,0,STRLEN(MaskFile)-4) + '_EVF.evf'
    ENVI_DOIT, 'RTV_DOIT', FID=MASK_FID, POS=[0], DIMS=DIMS, L_NAME='MASK', $
                VALUES=1, IN_MEMORY=IN_MEMORY, OUT_NAME=EVFMaskFile
    ENVI_FILE_MNG, ID = MASK_FID, /REMOVE
    
    ; [3] Write the attribute to the vector file
    EVF_FID = ENVI_EVF_OPEN(EVFMaskFile)
    ENVI_EVF_INFO, EVF_FID, NUM_RECS = NUM_RECS
    ENVI_EVF_CLOSE, EVF_FID
    attributes = REPLICATE({Path:'', Row:'', AcqDate:'', Sensor:''}, NUM_RECS)
    FOR i=0L,NUM_RECS-1 DO BEGIN
        attributes[i].Path      = sPath
        attributes[i].Row       = sRow
        attributes[i].AcqDate   = AcqDate
        attributes[i].Sensor    = Sensor
    ENDFOR
    
    ; Wirte the attributes to DBF
    DBFFileName = STRMID(EVFMaskFile, 0, STRLEN(EVFMaskFile)-4)+'.dbf'
    ENVI_WRITE_DBF_FILE, DBFFileName, attributes

    ; [4] Convert the EVF datatype to SHAPE datatype
    EVF_FID = ENVI_EVF_OPEN(EVFMaskFile)
    ENVI_EVF_TO_SHAPEFILE, EVF_FID, MaskFile
    ENVI_EVF_CLOSE, EVF_FID
    FILE_DELETE, EVFMaskFile, /ALLOW_NONEXISTENT
    FILE_DELETE, DBFFileName, /ALLOW_NONEXISTENT
    ; Close the image file
    ENVI_FILE_MNG, ID=Landsat_FID, /REMOVE
    
    STR_ERROR    = ''
END
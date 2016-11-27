
;******************************************************************************
;;
;; $Id: envi45_config/Program/LakeMappingTools/MAPPING_LakeDelineation.pro $
;;
;; Author: Junli LI, Geography Department of UCLA, Los Angeles, CA 90095
;+
;; NAME:
;;   MAPPING_LakeDelineation
;;
;; PURPOSE:
;;   LakeDelineation is a procedure that performs water segmentation on remote 
;;   sensing imagery to get lake mapping layers, and it's used as the succedent 
;;   lake dynamic analysis. Here NDWI(normalized difference water index) is the  
;;   index of automatic water body recognition(larger than 4 pixels). 
;;
;; PARAMETERS:
;;
;;   LandsatFile(in)      - The Landsat file path
;;
;;   NDWIFile(in)         - The NDWI file path
;;
;;   DEMFile(in)          - The DEM file 
;;
;;   SeaEdges(in)         - Sea edge pixels(x,y Map coordinates)
;;
;;   LakeRasterFile(in)   - The lake raster file
;;
;;   LakeVectorFile(in)   - The lake vector file
;;
;;   STR_ERROR(out)       - The ouput string when an error occurs
;;   
;; CALLING PROCEDURES:
;;                                              
;;
;; CALLING CUSTOM-DEFINED FUNCTIONS:
;;                        
;;                        
;; MODIFICATION HISTORY:
;;   Written by:  Junli LI, 2008/04/25 11:40 PM
;-
;******************************************************************************

PRO MAPPING_LakeDelineation, LandsatFile, NDWIFile,DEMFile, SeaEdges,$
                     LakeRasterFile, LakeVectorFile, ERROR = STR_ERROR    
    
    COMMON SHARE
    
    ;**************************************************************************
    ; Establish error handler. When errors occur, the index of the error is
    ; returned in the variable Error_status: 
    ;**************************************************************************
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
    ; 1) Initialize the Common variables
    ;
    ;**************************************************************************
    
    FileName  = FILE_BASENAME(LandsatFile)
    ; WRS 1/2 Path and Row info
    sPathRow  = STRMID(FileName,0,8)
    ; Get the Sensor info
    SensorID  = STRMID(FileName,9,3)
    ; Acq Date
    sAcqDate  = STRMID(FileName,13,8)
    
    ;**************************************************************************
    ;
    ; 2)  Load the image data and get general image information
    ;
    ;**************************************************************************
    
    ; [2] Load the raster file to memory and get the basic image information
    ENVI_OPEN_FILE, LandsatFile, R_FID = Landsat_FID
    IF(Landsat_FID EQ -1) THEN BEGIN
       STR_ERROR = LandsatFile + ': could not open it, please check it!'
       RETURN
    ENDIF
    ; [2.1] Width, Height, Band dimensions,starting sample and row of the image
    ENVI_FILE_QUERY, Landsat_FID, NS=Width, NL=Height, DIMS=ImageDIMS
    ; [2.2] map information
    MapInfo  = ENVI_GET_MAP_INFO(FID=Landsat_FID)
    ; [2.3] projection information
    Proj     = ENVI_GET_PROJECTION(FID=Landsat_FID, PIXEL_SIZE=PS, UNITS=Units)
    
    
    ; Get the TOA reflectance of Band 4
    bRef=GLOVIS_Landsat_Reflectance(Landsat_FID,sAcqDate,SensorID,4,BANDREF=Band4)          
    IF(bRef EQ 0) THEN BEGIN
       STR_ERROR = LandsatFile + ': could not get the reflectance of Band 4!'
       PRINT, STR_ERROR
       RETURN
    ENDIF
    
    ;**************************************************************************
    ;
    ; 3) Load the dem and slope data to get the elevation info for Landsat data
    ;    Only Landsat data have DEM information
    ;    
    ;**************************************************************************
    
    bHaveDEM = FILE_TEST(DEMFile, /READ)
    IF( bHaveDEM ) THEN BEGIN
       bHaveDEM = MAPPING_SubSetDEM_Slope_Shade(DEMFile,Landsat_FID,DEM=DEMBand,$
                                                SLOPE=SlopeBand,SHADE=ShadeBand)
       IF(bHaveDEM) THEN  BEGIN
          ShadeMask = ShadeBand LT SHADE_T
          SlopeMask = SlopeBand LT SLOPE_T*2
          MAPPING_MASKPreprocess,ShadeMask
          MAPPING_MASKPreprocess,SlopeMask
       ENDIF
    ENDIF 
    ;**************************************************************************
    ;
    ; 4) Calculate the Water Index (NDWI)
    ;
    ;**************************************************************************

    IF(FILE_TEST(NDWIFile, /READ)) THEN BEGIN
       ENVI_OPEN_FILE, NDWIFile, R_FID=NDWI_FID
       NDWI = ENVI_GET_DATA(FID=NDWI_FID, DIMS=ImageDIMS, POS=[0])
       IF(SensorID EQ 'LM1' OR SensorID EQ 'LM2' OR SensorID EQ 'LM3' OR $
          SensorID EQ 'LM4' OR SensorID EQ 'LM5' ) THEN BEGIN 
          NDWI = MEDIAN(NDWI, 3) 
       ENDIF
       ENVI_FILE_MNG, ID=NDWI_FID, /REMOVE
    ENDIF ELSE BEGIN
       ENVI_FILE_MNG, ID=NDWI_FID, /REMOVE
       STR_ERROR = NDWIFile + ': could not exists'
       PRINT,STR_ERROR
       RETURN
    ENDELSE
    
    ;**************************************************************************
    ;
    ; 5)Locate sea pixels if SeaEdges is available, and generate image masks
    ;    
    ;**************************************************************************
    siz = SIZE(SeaEdges, /DIMENSIONS)
    IF(siz[1] GT 5) THEN BEGIN
      xmap = SeaEdges[0, *]
      ymap = SeaEdges[1, *]
      iProj= ENVI_PROJ_CREATE(/GEOGRAPHIC)
      ENVI_CONVERT_PROJECTION_COORDINATES, xmap,ymap,iProj,x_oMap,y_oMap,Proj
      ENVI_CONVERT_FILE_COORDINATES, Landsat_FID, xf, yf, x_oMap, y_oMap
      ; Get the indexes of the whole region, so we can get the region ID
      SeaIdx = POLYFILLV(xf, yf, Width, Height)
    ENDIF
    NDWIMask = NDWI GE WATER_T0
    ; Get the Mask of the LandsatFile
    ImageMask=MAPPING_CreateNonZeroMask(Landsat_FID, NDWIMask, SeaIdx)
    IF(bHaveDEM) THEN BEGIN
       ImageMask = ImageMask AND (1-ShadeMask)
    ENDIF
    ; Apply the nonzero on the NDWI
    NDWI  = NDWI * ImageMask
    
    ; Close the image file
    ENVI_FILE_MNG, ID=Landsat_FID, /REMOVE
    
    ;**************************************************************************
    ;
    ; 6) Global Segmentation
    ;    
    ;**************************************************************************
    Global_T        = WATER_T0
    GlobalLakeMask  = (NDWI GE WATER_T0) AND (NDWI NE 0) AND (Band4 LT SNOW_REF)
    IF(bHaveDEM) THEN BEGIN
       idx = WHERE(GlobalLakeMask AND (1-SlopeMask),nCount)
       IF(nCount GT 1) THEN BEGIN
          NDWI[idx] = 0
          ImageMask[idx] = 0
          GlobalLakeMask[idx] = 0 
       ENDIF
       GlobalLakeMask = GlobalLakeMask AND (1-ShadeMask)
    ENDIF
    
    ; Whether there are lake pixels, if there are no water pixels, then return
    LakePix         = TOTAL(GlobalLakeMask)
    IF(LakePix LE 10) THEN BEGIN
       STR_ERROR    = LandsatFile + ': does not have lake pixels!'
       RETURN
    ENDIF

    ; Post processing, remove lakes with less than 4 pixels, Remove the hill shade
    ; and snow info from lake regions,
;    MAPPING_PostSegmentation, GlobalLakeMask, ImageMask, ShadeMask, Band4
    MAPPING_PreSegmentation,GlobalLakeMask,ImageMask,Band4,ShadeBand,SlopeBand
    
    ;**************************************************************************
    ;
    ; 7) Local Segmentation. Make region buffers for each water region, 
    ;    and then perform water segmenation region by region
    ;
    ;**************************************************************************
    MAPPING_LocalSegmentation, TEMPORARY(GlobalLakeMask), TEMPORARY(ImageMask),$
            TEMPORARY(NDWI),DEMBand, ShadeBand,SlopeBand,TEMPORARY(Band4),  $
            Global_T,WATERREGION=WaterRegion,REGIONT=RegionT,REGIONELEV=LakeElev,$
            HALFLAKE = bHalfLake
    nCount = SIZE(RegionT,/DIMENSION)
    if(nCount[0] LE 0) THEN RETURN
    LocalLakeMask   =  WaterRegion NE 0
;     LocalLakeMask   =  GlobalLakeMask

    ;**************************************************************************
    ;
    ; 9) Transfer segmentation result to Raster and vector format
    ;
    ;**************************************************************************

    ; [9.1] Create a classification layer and output it to external format
    CLASS_NAMES     = ['Unclassified','Water']
    DESCRIP         = 'Landsat Lake Mpping Image'
    LOOKUP          = [[0,0,0],[115,222,225]]
    BAND_NAME       = ['Lake Extraction']
    FILE_TYPE       = ENVI_FILE_TYPE('ENVI Classification')
    IN_MEMORY       = LONARR(1)
    ; Create a classification layer
    ENVI_ENTER_DATA, TEMPORARY(LocalLakeMask), BNAMES=BAND_NAME, NUM_CLASSES=2,$
                     CLASS_NAMES=CLASS_NAMES, LOOKUP=LOOKUP, DESCRIP=DESCRIP, $ 
                     FILE_TYPE=FILE_TYPE, MAP_INFO=MapInfo, PIXEL_SIZE=PS,$
                     UNITS=Units,R_FID=LAKE_EXTRACT_FID
    ; Save as a external raster file
    ENVI_OUTPUT_TO_EXTERNAL_FORMAT, FID=LAKE_EXTRACT_FID,POS=[0],DIMS=IMAGEDIMS,$
                     OUT_BNAME=CLASS_NAMES[1], OUT_NAME=LakeRasterFile, /ENVI

    ; [9.2] Raster-to-Vector file conversion
    EVFLakeFile     = LakeRasterFile + '_EVF.evf'
    ENVI_DOIT, 'RTV_DOIT',FID=LAKE_EXTRACT_FID,POS=[0],DIMS=IMAGEDIMS,VALUES=1,$
                 L_NAME=CLASS_NAMES[1],IN_MEMORY=IN_MEMORY, OUT_NAME=EVFLakeFile
    ; [9.3] Write the attribute to the vector file
    EVF_FID = ENVI_EVF_OPEN(EVFLakeFile)
    ENVI_EVF_INFO, EVF_FID, NUM_RECS = NUM_RECS
    ENVI_EVF_CLOSE, EVF_FID
    EVF_ATTRI   = REPLICATE({ImgSource:'',AcqDate:'',NDWI_T:0.0,LakeElev:0L,$
                  HalfLake:0B},NUM_RECS)
    FOR i=0L,NUM_RECS-1 DO BEGIN
        EVF_ATTRI[i].ImgSource = FileName
        EVF_ATTRI[i].AcqDate   = sAcqDate
        EVF_ATTRI[i].NDWI_T = 0.0
        EVF_ATTRI[i].LakeElev  = 0L
        EVF_ATTRI[i].HalfLake  = 0B
    ENDFOR
    ; [9.4] Add the DBF attributes to the shape file
    DBFFileName = STRMID(EVFLakeFile, 0, STRLEN(EVFLakeFile)-4) + '.dbf'
    ENVI_WRITE_DBF_FILE, DBFFileName, EVF_ATTRI

    ; [9.5] Convert the EVF format to SHAPE format
;    LakeVectorFile = LakeRasterFile + '_shp.shp'
    EVF_FID = ENVI_EVF_OPEN(EVFLakeFile)
    ENVI_EVF_TO_SHAPEFILE, EVF_FID, LakeVectorFile
    ENVI_EVF_CLOSE, EVF_FID
    FILE_DELETE, EVFLakeFile, /ALLOW_NONEXISTENT
    FILE_DELETE, DBFFileName, /ALLOW_NONEXISTENT

    ;**************************************************************************
    ;
    ; 10) Add the attribute to the shape file
    ;
    ;**************************************************************************
    
    ; Open a shapefile
    ShapeWater = OBJ_NEW('IDLffShape', LakeVectorFile, /UPDATE)
    ; Get the number of entities so we can parse through them.
    ShapeWater->GetProperty, N_ENTITIES=ShapeEntCount
    ; Read all the entities
    FOR i=0L, ShapeEntCount-1 DO BEGIN

        ; Read the entity i, and get the file coordinates
        ent      = ShapeWater->GetEntity(i)
        xmap     =(*ent.vertices)[0, *]
        ymap     =(*ent.vertices)[1, *]
        ENVI_CONVERT_FILE_COORDINATES, LAKE_EXTRACT_FID, xf, yf, xmap, ymap

        ; Get the indexes of the whole region, so we can get the region ID
        WaterIdx  = POLYFILLV(xf, yf, Width, Height)
        if(WaterIdx[0] eq -1) then continue
        nRegionID = LONG(MEDIAN(WaterRegion[WaterIdx]))
        Lake_T    = RegionT[nRegionID]
        Lake_Elev = LakeElev[nRegionID]
        Lake_Half = bHalfLake[nRegionID]

        ; update the attributes of the entity
        attr   = ShapeWater->getAttributes(i)
        attr.ATTRIBUTE_2 = Lake_T
        attr.ATTRIBUTE_3 = Lake_Elev
        attr.ATTRIBUTE_4 = Lake_Half
        ShapeWater -> SetAttributes, i, attr
        ;Clean-up of pointers
        ShapeWater->DestroyEntity, ent

    ENDFOR
    ; Close the Shapefile.
    OBJ_DESTROY, ShapeWater
        
    ENVI_FILE_MNG, ID = LAKE_EXTRACT_FID, /REMOVE

    ; remove all the FIDs in the file lists
    FIDS = ENVI_GET_FILE_IDS()
    FOR i = 0, N_ELEMENTS(FIDS) - 1 DO BEGIN
        IF(FIDS[i] NE -1) THEN  ENVI_FILE_MNG, ID = FIDS[i], /REMOVE
    ENDFOR

END
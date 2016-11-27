
;*****************************************************************************
;; $Id: envi45_config/Program/LakeMappingTools/Main_LandsatLakeExtraction.pro$
;;
;; Author: Junli LI, Geography Department of UCLA, Los Angeles, CA 90095
;+
;; NAME:
;;   Main_LandsatLakeExtraction
;;
;; PURPOSE:
;;   This procedure gets lake information from Landsat MSS/TM/ETM+ imagery.
;;   It's the main entrance of the procedure,  setting input parameters for  
;;   the WaterExtraction.pro procedure. As hill shade or shadow info can be 
;;   differentiated from water by elevation information, DEM and Slope info
;;   are used during the water extraction. First, we need have a idea which 
;;   UTM zone does the Landsat file(Often have UTM projections) belongs to. 
;;   Then finds the UTM projected DEM file in the directory DEM_UTMZone_DIR 
;;   which has the same map projection with the input landsat file,so as to
;;   get elevation and slope info to remove the influence of hillshades and
;;   shadow. If there are no DEM_UTMZone file that can cover spatial ranges
;;   of the Landsat file, then DEM_LatLon_File(covers all spatial ranges of
;;   If the SLOPE_UTMZone_DIR, DEM_UTMZone_DIR or DEM_LatLon_File are empty
;;   string, it means that no elevation info is used during the procession,  
;;   and hillshades or shadow are not taken as the affected factors of water
;;   recognition
;;
;; PARAMETERS:
;;
;;   Landsat_DIR(in)      - The directory of Landsat files
;;
;;   LakeRaster_DIR(in)   - The ouput directory of lake raster files 
;;
;;   LakeVector_DIR(in)   - The ouput directory of lake vector files 
;;
;;   SHADE_MASK_DIR(in)   - The directroy of hill shade mask of the Landsat file
;;
;;   SHADE_MASK_DIR(in)  - The directroy of DEM files with UTM projection
;;
;;   DEM_LatLon_File(in)  - The DEM files(Whole region) with Lat/Lon projection
;;
;; CALLING CUSTOM-DEFINED FUNCTIONS:  WaterExtraction
;;
;; MODIFICATION HISTORY:
;;
;;  Written by:  Junli LI, 2008/04/04 12:00 AM
;;  Modified  :  Junli LI, 2008/10/08 06:40 PM,
;-
;*****************************************************************************

PRO Main_LandsatLakeExtraction,Landsat_DIR,NDWI_DIR,DEM_DIR,LakeRaster_DIR,$
                               LakeVector_DIR

    ; ########################################################################
    ; Landsat FILE IDs whose extents touch the file boundary.
    ; Imagery in Tibet don't need this parameter
    ShorelineVectorFile = ''
    ; Temporary variables, just for testing
    Landsat_DIR         = 'I:\Kunlun\Landsat\'       
    NDWI_DIR            = 'I:\Kunlun\NDWI\'
    DEM_DIR             = '';I:\Kunlun\DEM\' 
 
    LakeRaster_DIR      = 'I:\Kunlun\Lakes\'
    LakeVector_DIR      = 'I:\Kunlun\Lakes\'   
    ; ########################################################################

    ;**************************************************************************
    ;
    ; 1) Initialize the Common variables
    ;
    ;**************************************************************************
    COMMON SHARE, SMALLREGION,WATER_T0,WATER_MIN,WATER_MAX,SNOW_REF,SLOPE_T,$
           SHADE_T,SIGMA_GAUSS,PEAK_INTERVAL,PEAK_PERCENT,HIST_BINSIZE,NDWI_MIN,$
           NDWI_MAX, BIGLAKE, BUFFER_ZOOM_MIN, BUFFER_ZOOM_MAX
    
    ; [1] for the global segmentation of the whole image
    SMALLREGION  = 4L       ; only lakes more than 4 pixels are used
    WATER_T0     = 0.10     ; initial NDWI threshold for water segmentation

    ; [2] for the local segmetation of the water region
    ;     used for local segmentation of region buffer
    WATER_MIN    = 0.05      ; The minimum NDWI threshold, That is, we suppose
                             ; NDWI less than 0.1 can't be water
    WATER_MAX    = 0.20      ; The maximum NDWI threshold, That is, we suppose 
                             ; NDWI greater than 0.4 must be water
    
    SNOW_REF     = 0.4       ; the snow reflectance
    SLOPE_T      = 15.0      ;
    SHADE_T      = 0.05      ;
    
    ;     histogram analysis for each single region
    SIGMA_GAUSS  = 2.0       ; the kernal size of DOG processing for finding 
                             ; peaks in the one lake region buffer
    PEAK_INTERVAL= 5         ; the interval distance between two peaks
    PEAK_PERCENT = 0.05      ; here suppose the total pixles of one peak in 
                             ; NDWI histogram
    HIST_BINSIZE = 0.02      ; the unit of NDWI(-1.0-1.0) histogram
    NDWI_MIN     = -1.0      ; Minimum of NDWI range which has value [-1.0,1.0]
    NDWI_MAX     = 1.0       ; Maximum of NDWI range

    ; [3] for the buffer region, mainly for statstical analysis of lake buffer
    BIGLAKE         = 20     ; the lakes larger than 100 pixels have sufficient
                             ; samples for histogram analysis of a lake buffer
    BUFFER_ZOOM_MIN = 2.25   ; Big lakes only need to expand 3 times larger
    BUFFER_ZOOM_MAX = 3      ; Small lakes need to expand 4 times larger
    
    
    ;*************************************************************************
    ; Initilize the procedure parameters
    ;*************************************************************************
    
    IF(Landsat_DIR EQ '' OR LakeRaster_DIR EQ '') THEN BEGIN
       MESSAGE, 'The given directory is invalid.'
       RETURN
    ENDIF
     
    ; Find all the Landsat files in the Landsat_DIR
    LandsatFilePaths = FILE_SEARCH(Landsat_DIR,'*.dat', COUNT=FileCount,$
                                   /TEST_READ, /FULLY_QUALIFY_PATH) 
    IF(FileCount LE 0) THEN BEGIN
        PRINT, 'There are no valid Landsat files in the given directory.'
        RETURN
    ENDIF
    
    ; whether DEM or Shade file is used during the process
    bHaveDEM  = FILE_TEST(DEM_DIR,  /DIRECTORY)
    
    ;;%%%%%%%%%%%%%%%%%%%% Load the shoreline vector data %%%%%%%%%%%%%%%%%%%%
    bShoreLine = 0
    IF(FILE_TEST(ShorelineVectorFile,/READ)) THEN BEGIN
       MAPPING_GetPathRow_Shoreline, ShorelineVectorFile, DB_PathRows=PathRows
       bShoreLine = 1
    ENDIF
    ;;%%%%%%%%%%%%%%%%%%%% Load the shoreline vector data %%%%%%%%%%%%%%%%%%%%
    
    ;
    ; Create log file to save the processing logs
    BatchFile        = Landsat_DIR + 'BatchLogFile.txt'
    GET_LUN, LogHFile
    OPENW, LogHFile, BatchFile
    ; Begin to write processing log in the file
    PRINTF,LogHFile,'___________________Begin Procedure_________________'
    PRINTF,LogHFile, SYSTIME()
    PRINTF,LogHFile, 'There are ' + String(FileCount) + $
                     ' Landsat Files altogether to be processed'
    ; Initialize ENVI and store all errors and warnings
    ENVI, /RESTORE_BASE_SAVE_FILES
    ENVI_BATCH_INIT, LOG_FILE = logProcedureFileName
    
    ;***************************************************************************
    ; Loop procedures to extract lake from the landsat scenes
    ;***************************************************************************
    ; Open a shapefile
    IF(bShoreLine) THEN Shoreline_SHP = OBJ_NEW('IDLffShape', ShorelineVectorFile)
    ; Get the number of entities so we can parse through them. 
    nTotalMinutes = 0.0
    FOR i=0L, FileCount-1 DO BEGIN
        
        ;***********************************************************************
        ; (1) Get info from Landsat files
        ;***********************************************************************
        LandsatFile = LandsatFilePaths[i]
        ; Get the base file name (without directory)
        FileName        = FILE_BASENAME(LandsatFile)
        ; Remove '.dat' of the LandsatFile
        FileName        = STRMID(FileName, 0, STRLEN(FileName)-4)

        ; [1.2] Check filenames, which need keep to GLOVIS file naming rules
        ; i.e. P149R038_LM2D19761112 P139R040_LT4D19891110 P139R038_LE7D20001007 
        IF( GLOVIS_FileNamingCheck(FileName) EQ 0) THEN BEGIN
            PRINTF,LogHFile, FileName+'FileNaming rule is invalid. '
            CONTINUE
        ENDIF
        ; Get the Sensor info
        Sensor          = GLOVIS_SensorType(FileName)
        ; WRS 1/2 Path and Row info
        sPathRow        = STRMID(FileName,0,8)
        ; Acq Date
        sAcqDate        = STRMID(FileName,13,8)
        
        ;***********************************************************************
        ; (2) Generate the parameters for lake mapping
        ;***********************************************************************
        ; Check the raster and vector lake file status
        LakeRasterFile  = LakeRaster_DIR + FileName  + '_Lakes'
        LakeVectorFile  = LakeVector_DIR + FileName  + '.shp'
        IF(FILE_TEST(LakeRasterFile, /READ) AND FILE_TEST(LakeVectorFile,/READ))$
        THEN CONTINUE
        ; Check the DEM file status
        DEMFile   = ''
        IF( bHaveDEM ) THEN BEGIN
           ; Check DEM file status
           DEMFile    = DEM_DIR   + 'DEM_'  + sPathRow+'.dat'
           IF(FILE_TEST(DEMFile, /READ) EQ 0) THEN BEGIN
              DEMFile = DEM_DIR  + 'DEM_' + FileName+'.dat'
              IF(FILE_TEST(DEMFile, /READ) EQ 0) THEN DEMFile = ''
           ENDIF 
        ENDIF
        
        ; Check the NDWI file status
        NDWIFile = NDWI_DIR + FileName + '_NDWI'
        STRERR   = ''
        IF(FILE_TEST(NDWIFile, /READ) EQ 0) THEN BEGIN
           IF(Sensor EQ 'ETM') THEN GLOVIS_NDWI_ETM, LandsatFile, NDWIFile, STRERR
           IF(Sensor EQ 'TM')  THEN GLOVIS_NDWI_TM,  LandsatFile, NDWIFile, STRERR
           IF(Sensor EQ 'MSS') THEN GLOVIS_NDWI_MSS, LandsatFile, NDWIFile, STRERR
           IF(STRERR NE '') THEN BEGIN
              PRINTF, LogHFile, 'Error: Creat NDWI of ' +  FileName + ' failed!'
              PRINT, NDWIFile + ' does not exist!'
              CONTINUE
           ENDIF
        ENDIF
        
        ;;%%%%%%%%%%%%%%%%%%% Load the shoreline vector data %%%%%%%%%%%%%%%%%%%
        ; Check with the ShorelineFile. If LandsatFile is located on 
        IF(bShoreLine) THEN BEGIN
           PathRow = STRMID(sPathRow, 1, 3)+STRMID(sPathRow, 5, 3)
           idx_pathrow = WHERE(PathRows EQ PathRow, nCount)
           IF(nCount EQ 1) THEN BEGIN 
              SeaEdges = MAPPING_GetLandMaskCoordinates(Shoreline_SHP,idx_pathrow[0])
           ENDIF ELSE BEGIN
              SeaEdges = [[0],[0]]
;           CONTINUE
           ENDELSE
         ENDIF ELSE SeaEdges = [[0],[0]]
        ;;%%%%%%%%%%%%%%%%%%% Load the shoreline vector data %%%%%%%%%%%%%%%%%%%
                
        ;***********************************************************************
        ; (3) LakeDelineation procedure
        ;***********************************************************************
        time_begin   = SYSTIME(1,/SECONDS)
        PRINTF,LogHFile, 'File '+STRING(i+1)+': ' + FileName
        MAPPING_LakeDelineation, LandsatFile, NDWIFile,DEMFile, SeaEdges,$
                     LakeRasterFile, LakeVectorFile, ERROR = STR_ERROR                 
        ; Write processing logs
        IF(STRCMP(STR_ERROR, '') EQ 0) THEN BEGIN
           PRINTF,LogHFile,STR_ERROR
           PRINTF,LogHFile, '                                              '
           IF(i NE FileCount-1) THEN PRINTF,LogHFile, 'Next File ..........'
           CONTINUE
        ENDIF
        time_end   = SYSTIME(1,/SECONDS)
        PRINTF,LogHFile, 'Time used: '+STRING(time_end-time_begin)+' seconds' 
        PRINTF,LogHFile, '                                              '
        IF(i NE FileCount-1) THEN PRINTF,LogHFile, 'Next File ..........'
        nTotalMinutes = nTotalMinutes + (time_end-time_begin)/60.0
    ENDFOR
    ; Close the Shapefile.
    IF (bShoreLine) THEN OBJ_DESTROY, Shoreline_SHP
    
    PRINTF,LogHFile, 'The total processing time for water extraction is : ' + $
                     STRING(nTotalMinutes) + ' minutes'
    PRINTF,LogHFile, '___________________EndProcedure_________________'
    FREE_LUN, LogHFile
     
END
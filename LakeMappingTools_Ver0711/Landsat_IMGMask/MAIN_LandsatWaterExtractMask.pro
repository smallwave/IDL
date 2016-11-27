;******************************************************************************
;; $Id: envi45_config/Program/LakeMappingTools/Main_LandsatExtentMask.pro$
;;
;; Author: Junli LI, Geography Department of UCLA, Los Angeles, CA 90095
;+
;; NAME:
;;   Main_LandsatExtentMask
;;
;; PURPOSE:
;;   The procedure generate vector extent mask files from Landsat imagery 
;;
;; PARAMETERS:
;;   Landsat_DIR(in) - input Landsat file directory 
;;
;;   NDWI_DIR(in)
;;
;;   LakeMASK_DIR(in)- input DEM file directory
;;
;; OUTPUTS:
;;
;; CALLING CUSTOM-DEFINED FUNCTIONS: 
;;     GetLandsatSensorType
;;     CreateImageMask
;;
;; PROCEDURES OR FUNCTIONS CALLED: 
;;
;; MODIFICATION HISTORY:
;;   Written by:  Junli LI, 2009/04/23 12:00 AM
;-
;******************************************************************************

PRO MAIN_LandsatWaterExtractMask, Landsat_DIR, NDWI_DIR, LandsatMask_DIR

    ; ########################################################################
    ; 
    ; Temporary variables, just for testing
      Landsat_DIR = 'F:\GLOVIS_LandsatETM_NA\ETM\2\'
      NDWI_DIR    = 'F:\GLOVIS_LandsatETM_NA\NDWI\'
      ShorelineVectorFile = 'D:\Users\Junli\envi45_config\Program\LakeMappingTools_Ver0711\Data\WRS2_Landsat_World_Sea.shp'      
      LandsatMask_DIR = 'F:\GLOVIS_LandsatETM_NA\Mask\'
    ;
    ; ########################################################################
    
    ;*************************************************************************
    ; [1] Initilize the procedure parameters
    ;*************************************************************************
    ; Initialize ENVI and store all errors and warnings
    ENVI, /RESTORE_BASE_SAVE_FILES
    ENVI_BATCH_INIT, LOG_FILE = logProcedureFileName
    
    IF(Landsat_DIR EQ '' OR LandsatMask_DIR EQ '') THEN BEGIN
       MESSAGE, 'The given directory is invalid.'
       RETURN
    ENDIF
    LandsatFilePaths = FILE_SEARCH(Landsat_DIR,'*.DAT', COUNT=FileCount,$
                                   /TEST_READ, /FULLY_QUALIFY_PATH) 
    IF(FileCount LE 0) THEN BEGIN
        PRINT, 'There are no valid Landsat files in the given directory.'
        RETURN
    ENDIF
    
    ;*************************************************************************
    ; [2] Get the PathRows of the Landsat files which are connected the Sea
    ;     shorelines, ShorelineVectorFile is the WRS PathRows Extents whose
    ;     boundaries are connected with the sea shoreline worldwide 
    ;*************************************************************************
     MAPPING_GetPathRow_Shoreline, ShorelineVectorFile, DB_PathRows=PathRows
    
    ;***************************************************************************
    ; Loop procedures to extract lake from the landsat scenes
    ;***************************************************************************
    
    ; Open a shapefile
    Shoreline_SHP = OBJ_NEW('IDLffShape', ShorelineVectorFile)
    
    nTotalMinutes = 0.0
    PRINT, 'Start time is: '+ SYSTIME(/UTC)
    FOR i=0L, FileCount-1 DO BEGIN
        ;*************************************************************************
        ; [3] Get the File names for the function parameters
        ;*************************************************************************
        ; 3.1 Landsat file name
        LandsatFile = LandsatFilePaths[i]
        ; Get the base file name (without directory)
        FileName        = FILE_BASENAME(LandsatFile)
        FileName        = STRMID(FileName, 0, STRLEN(FileName)-4)
        PRINT, i+1, ': '+FileName + 'is Processing...'
        IF( GLOVIS_FileNamingCheck(FileName) EQ 0) THEN BEGIN
            PRINT, 'As some parameters are acquired from filename '$
                   + FileName + ', it is not specified name for this procedure.'
            CONTINUE
        ENDIF
        
        ; 3.2  NDWI File Name
        NDWIFile = NDWI_DIR+FileName+'_NDWI'
        
        ; 3.3 Mask Vector File Name
        ExtentMaskFile  = LandsatMask_DIR + FileName  + '_MASK.shp'
        
        ; 3.4 Load the shoreline vector data, and get the FileName
        sPathRow  = STRMID(FileName,0,8)
        PathRow   = STRMID(sPathRow, 1, 3)+STRMID(sPathRow, 5, 3)
        idx_pathrow = WHERE(PathRows EQ PathRow, nCount)
        IF(nCount EQ 1) THEN BEGIN
           MAPPING_GetLandMaskCoordinates,Shoreline_SHP,idx_pathrow[0],$
                                          SEAPARTS=Parts, VERTICES=SeaEdges
        ENDIF ELSE BEGIN
          Parts   = -1
          SeaEdges = [[0],[0]]
          PRINT,  'Does not touch with the sea. ' 
;          CONTINUE
        ENDELSE
        
        ;*************************************************************************
        ; [4] Run the Water Mask Procedure
        ;*************************************************************************
        PRINT, STRTRIM(STRING(i+1),2)+ ': '+FileName + '  is being Processed'
        time_begin  = SYSTIME(1,/SECONDS)
        WATERMASK_CreateLandsatMask,LandsatFile,NDWIFile,Parts,SeaEdges,$
        ExtentMaskFile,ERROR=STR_ERROR 
        ; Write processing logs
        IF(STRCMP(STR_ERROR, '') EQ 0) THEN BEGIN
           PRINT,FileName+'Errors:'+ STR_ERROR
           CONTINUE
        ENDIF
        time_end   = SYSTIME(1,/SECONDS)
        PRINT, 'Processing time: ' +  STRING(time_end-time_begin) + ' seconds'
        IF(i NE FileCount-1) THEN PRINT, 'Next File ..........'
        nTotalMinutes = nTotalMinutes + (time_end-time_begin)/60.0
    ENDFOR
    PRINT, 'The total processing time for water extraction is : ' + $
           STRING(nTotalMinutes) + ' minutes'
    ; Close the Shapefile.
    OBJ_DESTROY, Shoreline_SHP
    PRINT,'End time is: '+ SYSTIME(/UTC)
    PRINT,'WaterMask Finished!'
     
END
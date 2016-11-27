
;******************************************************************************
;; $Id: envi45_config/Program/LakeMappingTools/SRTM_06DEMtoSHADEandSLOPE.pro $
;;
;; Author: Junli LI, Geography Department of UCLA, Los Angeles, CA 90095
;+
;; NAME:
;;   SRTM_06DEMtoSHADEandSLOPE
;;
;; PURPOSE:
;;   Create Hill Shade and Slope from DEM Imagery
;;
;; PARAMETERS:
;;
;; OUTPUTS:
;;
;; CALLING CUSTOM-DEFINED FUNCTIONS: 
;;
;; PROCEDURES OR FUNCTIONS CALLED:  CreateLandsatElevationFile
;;
;; MODIFICATION HISTORY:
;;  Written by:  Junli LI, 2008/05/25 11:40 PM
;;  Written by:  Junli LI, 2008/10/08 12:00 AM
;-
;******************************************************************************

PRO SRTM_06DEMtoSHADEandSLOPE

    ; ############################################################
    ; Temporary variables, just for testing
    ; IN 
    Landsat_DIR  = 'E:\TibetanPlateau_GlacierLakes\Samples\ETM\'
    WRS_SRTM_DIR = 'E:\TibetanPlateau_GlacierLakes\SRTM_Tibet' 
    ; OUT
    DEM_DIR      = 'E:\TibetanPlateau_GlacierLakes\Samples\DEM\'
    SHADE_DIR    = 'E:\TibetanPlateau_GlacierLakes\Samples\SHADE\'
    SLOPE_DIR    = 'E:\TibetanPlateau_GlacierLakes\Samples\SLOPE\'
    ; ############################################################

    ;**************************************************************************
    ;
    ; Get all of the landsat file names of the given Landsat directory
    ;
    ;**************************************************************************

    ; Find MSS, TM, ETM files in the give directory
    LandsatFilePaths = FILE_SEARCH(Landsat_DIR,'*.DAT', COUNT = FileCount, $
                               /TEST_READ, /FULLY_QUALIFY_PATH)
    IF(FileCount LE 0) THEN BEGIN
        Message, 'There are no valid landsat data in the given directory.'
        RETURN
    ENDIF
    ; Initialize ENVI and store all errors and warnings in LogFileBatch.txt
    logProcedureFileName = 'LogFileBatch.txt'
    ENVI, /RESTORE_BASE_SAVE_FILES
    ENVI_BATCH_INIT, LOG_FILE = logProcedureFileName

    ;*************************************************************************
    ;
    ; Loop procedures to create DEM and Slope file for each Landsat file
    ;
    ;*************************************************************************
    PRINT, 'DEM Slope Generation from Landsat Files.....'
    time_begin = SYSTIME(/UTC)
    PRINT, 'time begins' + STRING(time_begin)
    
    FOR i=0, FileCount-1 DO BEGIN
        LandsatFileName = LandsatFilePaths[i]
        ; Remove '.hdr' of the LandsatFileName
        FileName    = STRMID(LandsatFileName, 0, STRLEN(LandsatFileName)-4)
        ; Get the base file name (without directory)
        FileName    = FILE_BASENAME(FileName)
        sPathRow    = STRMID(FileName,0,8)
        SRTM_DEMFile  = WRS_SRTM_DIR ;+'DEM_' + sPathRow+'.dat'
        ; Generate the output file name
        DEMFile     = DEM_DIR   + 'DEM_'   + FileName + '.dat'
        ShadeFile   = SHADE_DIR + 'SHADE_' + FileName + '.dat'
        SlopeFile   = SLOPE_DIR + 'SLOPE_' + FileName + '.dat'
        
        ; subset DEM from SRTM
        SRTM_CreateDEMFromLandsatExt, LandsatFileName, SRTM_DEMFile, DEMFile
        ; Get Solar angles from Landsat files
        GetSolarAnglesFromLandsatMetaFiles,LandsatFileName,SunAzimuth,SunElev
        ; Generate SHADE from DEM
        SRTM_CreateHillShadeFromDEM, DEMFile, ShadeFile, SunAzimuth, SunElev
        ; Generate SLOPE from DEM
        SRTM_CreateSlopeFromDEM, DEMFile, SLOPEFile
        
    ENDFOR
    
    time_end = SYSTIME(/UTC)
    PRINT, 'time ends : ' + STRING(time_end)
END
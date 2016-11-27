
;******************************************************************************
;; $Id: envi45_config/Program/LakeMappingTools/SRTM_05Landsat_DEMSHADE_SubSet.pro $
;;
;; Author: Junli LI, Geography Department of UCLA, Los Angeles, CA 90095
;+
;; NAME:
;;   SRTM_05Landsat_DEMSHADE_SubSet
;;
;; PURPOSE:
;;   This procedure subset DEM and Shade from STRM with the spatial extent of
;;   Landsat Imagery, and DIMS of subset file is same as that of Landsat file
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

PRO SRTM_05Landsat_DEMSHADE_SubSet

    ;**************************************************************************
    ;
    ; Initilize the procedure parameters
    ;
    ;**************************************************************************

    ; Set the dialog to get the parameters
;    Landsat_DIR = Dialog_PickFile(Title='Select Landsat file path:',/DIRECTORY)
;    SRTM_FilePath = Dialog_PickFile(Title='Select SRTM file path:')
;    SLOPE_DIR = Dialog_PickFile(Title='Select the slope file path:',/DIRECTORY)
;    DEM_DIR   = Dialog_PickFile(Title='Select the DEM file path:',  /DIRECTORY)
;    
    ; ############################################################
    ; Temporary variables, just for testing
    Landsat_DIR   = 'D:\TibetanPlateau_GlacierLake\ETM_2000s\ETM\'
    SHADE_DIR     = 'D:\TibetanPlateau_GlacierLake\TM_2005s\SHADE\'
    DEM_DIR       = 'D:\TibetanPlateau_GlacierLake\TM_2005s\DEM\' 
    SRTM_FilePath = 'E:\SRTM\SRTM_Tibet'
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
        FileName        = FILE_BASENAME(LandsatFileName)
        ; Remove '.hdr' of the LandsatFileName
;        FileName        = STRMID(FileName, 0, STRLEN(LandsatFileName)-4)
        ; Get the base file name (without directory)
        
        ; Generate the output file name
        ShadeFile    = 'SHADE_' + FileName
        ShadeFiles   = FILE_SEARCH(SHADE_DIR, ShadeFile, COUNT = ShadeCount, $
                                  /TEST_READ, /FULLY_QUALIFY_PATH)
        DEMFile      = 'DEM_'   + FileName
        DEMFiles     = FILE_SEARCH(DEM_DIR, DEMFile, COUNT = DEMCount, $
                                  /TEST_READ, /FULLY_QUALIFY_PATH)
        IF(ShadeCount EQ 0) THEN  BEGIN
           ShadeFile = SHADE_DIR + 'SHADE_' + FileName
           DEMFile   = DEM_DIR   + 'DEM_'   + FileName
           PRINT, STRTRIM(STRING(i+1),2), ': ', LandsatFileName,' ...'
           time_begin = SYSTIME(1,/SECONDS)
           ; subset DEM from SRTM
           SRTM_CreateDEMFromLandsatExt, LandsatFileName, SRTM_FilePath, DEMFile
           ; Get Solar angles from Landsat files
           GetSolarAnglesFromLandsatMetaFiles,LandsatFileName,SunAzimuth,SunElev
           ; Generate SHADE from DEM
           SRTM_CreateHillShadeFromDEM, DEMFile, ShadeFile, SunAzimuth, SunElev 
           time_end = SYSTIME(1,/SECONDS)
           time_minutes = (time_end-time_begin)/60.0
           PRINT, 'Time used: '+ STRING(time_minutes) + ' minutes'
          
        ENDIF
        
    ENDFOR
    
    time_end = SYSTIME(/UTC)
    PRINT, 'time ends : ' + STRING(time_end)
END
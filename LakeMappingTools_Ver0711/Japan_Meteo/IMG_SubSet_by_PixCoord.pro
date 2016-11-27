
;******************************************************************************
;; $Id: envi45_config/Program/LakeMappingTools/SRTM_05Landsat_DEMSHADE_SubSet.pro $
;;
;; Author: Junli LI, Geography Department of UCLA, Los Angeles, CA 90095
;+
;; NAME:
;;   Main_IMG_SubSet
;;
;; PURPOSE:
;;   This procedure subset IMG file by giving the pixel coords
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
;;  Written by:  Junli LI, 2011/01/20 11:40 PM
;;  Written by:  Junli LI, 2011/01/20 12:00 AM
;-
;******************************************************************************

PRO IMG_SubSet_by_PixCoord

    ;**************************************************************************
    ;
    ; Initilize the procedure parameters
    ;
    ;**************************************************************************

    ; ############################################################
    ; Temporary variables, just for testing
    IMG_DIR   = 'D:\MoonsoonAsia_PrecipiataionData_Japan\APHRODITE\Monthly\'
    SUB_DIR   = 'D:\MoonsoonAsia_PrecipiataionData_Japan\APHRODITE\Monthly1\' 
    SUB_DIMS = [-1, 116,405,92,199]
    ; ############################################################

    ;**************************************************************************
    ;
    ; Get all of the landsat file names of the given Landsat directory
    ;
    ;**************************************************************************

    ; Find MSS, TM, ETM files in the give directory
    IMGFilePaths = FILE_SEARCH(IMG_DIR,'*.DAT', COUNT = FileCount, $
                               /TEST_READ, /FULLY_QUALIFY_PATH)
    IF(FileCount LE 0) THEN BEGIN
        PRINT, 'There are no valid landsat data in the given directory.'
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
    PRINT, 'Subset image files by the giving pixel coordinates.....'
    time_begin = SYSTIME(1,/SECONDS)
     
    FOR i=0, FileCount-1 DO BEGIN
        IMGFile    = IMGFilePaths[i]
        FileName   = FILE_BASENAME(IMGFile)
        ; Generate the output file name
        SUBFile    = SUB_DIR  + FileName
        PRINT, STRTRIM(STRING(i+1),2), ': ', FileName,' ...'
        ; If SUBFile already exists, return
        IF(FILE_TEST(SUBFile, /READ)) THEN RETURN
        ENVI_OPEN_FILE, IMGFile, R_FID = IMG_FID
        ENVI_FILE_QUERY, IMG_FID, NS=NS, NL=NL, NB=NB, BNAMES=BNAMES,DIMS=DIMS
        ENVI_OUTPUT_TO_EXTERNAL_FORMAT, FID=IMG_FID,POS=[0],DIMS=SUB_DIMS,$
             OUT_BNAME=BNAMES, OUT_NAME=SUBFile, /ENVI         
        ; Close the tmp file
        ENVI_FILE_MNG, ID = IMG_FID, /REMOVE 
          
    ENDFOR
    ; remove all the FIDs in the file lists
    FIDS = ENVI_GET_FILE_IDS()
    IF(N_ELEMENTS(FIDS) GE 1) THEN BEGIN
       FOR i = 0, N_ELEMENTS(FIDS) - 1 DO BEGIN
           IF(FIDS[i] NE -1) THEN  ENVI_FILE_MNG, ID=FIDS[i], /REMOVE
       ENDFOR
    ENDIF
    
    time_end = SYSTIME(1,/SECONDS)
    time_minutes = (time_end-time_begin)/60.0
    PRINT, 'Time used: '+ STRING(time_minutes) + ' minutes'    
END
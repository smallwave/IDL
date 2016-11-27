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

PRO MAIN_LandsatExtentMask, Landsat_DIR, LandsatMask_DIR

    ; ########################################################################
    ; 
    ; Temporary variables, just for testing
      Landsat_DIR     = 'H:\CentralAsia1990_reproj\'       
      LandsatMask_DIR = 'H:\CentralAsia1990_mask\'
    ;
    ; ########################################################################
    
    ;*************************************************************************
    ; Initilize the procedure parameters
    ;*************************************************************************
    
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
    ;
    ; Create log file to save the processing logs
    ;
    ;*************************************************************************
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
    nTotalMinutes = 0.0
    FOR i=0, FileCount-1 DO BEGIN

        LandsatFile = LandsatFilePaths[i]
        ; Get the base file name (without directory)
        FileName        = FILE_BASENAME(LandsatFile)
        FileName        = STRMID(FileName, 0, STRLEN(FileName)-4)
        IF( GLOVIS_FileNamingCheck(FileName) EQ 0) THEN BEGIN
            PRINTF,LogHFile, 'As some parameters are acquired from filename '$
                   + FileName + ', it is not specified name for this procedure.'
            CONTINUE
        ENDIF
        
        ; Generate the raster and vector Lake file paths
        ExtentMaskFile  = LandsatMask_DIR + FileName  + '_MASK.shp'
        ;        
        PRINT, STRTRIM(STRING(i+1),2)+ ': '+FileName + '  is being Processed'
        PRINTF,LogHFile, FileName + '  is being Processed'
        time_begin      = SYSTIME(1,/SECONDS)
        PRINTF,LogHFile, 'Start time is: '+ SYSTIME(/UTC)

        MASK_CreateLandsatExtentMask,LandsatFile,ExtentMaskFile,ERROR=STR_ERROR
        
        ; Write processing logs
        IF(STRCMP(STR_ERROR, '') EQ 0) THEN BEGIN
           PRINTF,LogHFile,STR_ERROR
           PRINTF,LogHFile, '                                              '
           IF(i NE FileCount-1) THEN PRINTF,LogHFile, 'Next File ..........'
           CONTINUE
        ENDIF
        time_end   = SYSTIME(1,/SECONDS)
        PRINTF,LogHFile, 'Processing time: ' + $
                              STRING(time_end-time_begin) + ' seconds'
        PRINTF,LogHFile, '                                              '
        IF(i NE FileCount-1) THEN PRINTF,LogHFile, 'Next File ..........'
        nTotalMinutes = nTotalMinutes + (time_end-time_begin)/60.0
    ENDFOR
    
    PRINTF,LogHFile, 'The total processing time for water extraction is : ' + $
                     STRING(nTotalMinutes) + ' minutes'
    PRINTF,LogHFile, 'End time is: '+ SYSTIME(/UTC)
    PRINTF,LogHFile,'___________________EndProcedure_________________'
    FREE_LUN, LogHFile
     
END
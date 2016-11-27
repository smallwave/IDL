;******************************************************************************
;; $Id: envi45_config/Program/LakeMappingTools/Main_Landsat_NDWI.pro $
;;
;; Author: Junli LI, Geography Department of UCLA, Los Angeles, CA 90095
;+
;; NAME:
;;   Main_Landsat_NDWI
;;
;; PURPOSE:
;;   This procedure create the NDWI(Normalized Difference Water Index) file
;;   for lake extraction
;;
;; PARAMETERS:
;;
;;   Landsat_DIR(in)   - The directory of Landsat files
;;
;;   NDWI_DIR(in)      - The directory of ouput NDWI files
;;
;;
;; CALLING CUSTOM-DEFINED FUNCTIONS:  None
;；
;；  PROCEDURES OR FUNCTIONS CALLED
;;
;; MODIFICATION HISTORY:
;;
;;  Written by:  Junli LI, 2009/04/23 09:30 PM
;-
;******************************************************************************

PRO Main_Landsat_NDWI,Landsat_DIR,NDWI_DIR,DataSource

    ; ############################################################
    ; Temporary variables, just for testing
    Landsat_DIR   = 'I:\Kunlun\Landsat\'
    NDWI_DIR      = 'I:\Kunlun\NDWI\'
    DataSource    = 'GLOVIS' ; 'GLOVIS' or 'GLCF'
    ; ############################################################

    ; Find landsat files in the give directory
    LandsatFilePaths  = FILE_SEARCH(Landsat_DIR,'*.dat', COUNT = FileCount, $
                                    /TEST_READ, /FULLY_QUALIFY_PATH)
    ; Initialize ENVI
    PRINT, 'Start time is: ', SYSTIME(/UTC)
    logProcedureFileName = 'Landsat_NDWI.txt'
    ENVI, /RESTORE_BASE_SAVE_FILES
    ENVI_BATCH_INIT, LOG_FILE = logProcedureFileName,/NO_STATUS_WINDOW 
    ENVI_BATCH_STATUS_WINDOW , /OFF  
    
    FOR i=0, FileCount-1 DO BEGIN
        ; Get general information from the landsat file names
        LandsatFile = LandsatFilePaths[i]
        ; Sensor Type
        Sensor       = GetLandsatSensorType(LandsatFile)
        ; Get the base file name (without directory)
        FileName     = FILE_BASENAME(LandsatFile)
        FileName     = STRMID(FileName,0,STRLEN(FileName)-4) 
        ; Generate the output file name
        NDWIFile     = NDWI_DIR + FileName + '_NDWI.dat'
        IF(FILE_TEST(NDWIFile) EQ 0) THEN BEGIN
          ;CreateNDWIFile, LandsatFile,NDWIFile,Sensor,bRadiance,bNDSI
          PRINT, 'NDWI  ', STRTRIM(STRING(i+1),2), ':', LandsatFile,' ...'
          time_begin = SYSTIME(1,/SECONDS)
          STRERR = ''
          IF(Sensor EQ 'ETM') THEN GLOVIS_NDWI_ETM, LandsatFile, NDWIFile, STRERR
          IF(Sensor EQ 'MSS') THEN GLOVIS_NDWI_MSS, LandsatFile, NDWIFile, STRERR
          
          IF(Sensor EQ 'TM')  THEN BEGIN
             IF(DataSource EQ 'GLOVIS') THEN BEGIN
                GLOVIS_NDWI_TM,  LandsatFile, NDWIFile, STRERR
             ENDIF
             IF(DataSource EQ 'GLCF') THEN BEGIN
                GLOVIS_NDWI_TM,  LandsatFile, NDWIFile, STRERR
             ENDIF 
          ENDIF
          
          IF(STRERR NE '') THEN BEGIN
            PRINT,STRERR
            CONTINUE
          ENDIF
          time_end     = SYSTIME(1,/SECONDS)
          time_minutes = (time_end-time_begin)/60.0
          PRINT, 'Total time is: ', time_minutes
          
        ENDIF
    ENDFOR 
    
    PRINT, 'End time is: ', SYSTIME(/UTC)
   
END
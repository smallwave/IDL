
;******************************************************************************
;; $Id: envi45_config/Program/LakeExtraction/PUB_ENVI_to_TIFFs.pro $
;;
;; Author: Junli LI, Geography Department of UCLA, Los Angeles, CA 90095
;+
;; NAME:
;;   PUB_ENVI_to_TIFFs
;;
;; PURPOSE:
;;   The procedure convert ENVI file format to Tiff file format
;;
;; PARAMETERS:
;;
;;   ENVIFile_DIR (in) - the ENVI file directory
;;
;;   TIFF_DIR(in)      - Tiff file Directory
;;
;; OUTPUTS:
;;   Standard Deviation
;;
;; CALLING CUSTOM-DEFINED FUNCTIONS:  HistSegmentation
;;
;; MODIFICATION HISTORY:
;;    Written by:  Junli LI, 2009/04/29 06:00 PM
;-
;******************************************************************************


Pro PUB_ENVI_to_TIFFs, ENVIFile_DIR, TIFF_DIR
  
    ; ############################################################
    ; Temporary variables, just for testing
    ENVIFile_DIR  = 'H:\Tibetan_TM1990\TM\'
    TIFF_DIR      = 'H:\Tibetan_TM1990\TIFFS\'
    ; ############################################################

    ; Find landsat files in the give directory
    ENVIFilePaths  = FILE_SEARCH(ENVIFile_DIR,'*.dat', COUNT = FileCount,$
                                    /TEST_READ, /FULLY_QUALIFY_PATH)
    ; Initialize ENVI
    PRINT, 'Start time is: ', SYSTIME()
    logProcedureFileName = 'Landsat_NDWI.txt'
    ENVI, /RESTORE_BASE_SAVE_FILES
    ENVI_BATCH_INIT, LOG_FILE = logProcedureFileName,/NO_STATUS_WINDOW 
    envi_batch_status_window, /off  
    FOR i=0, FileCount-1 DO BEGIN
      ;Get general information from the landsat file names
      ENVIFileName = ENVIFilePaths[i]
      ENVIFileName = STRMID(ENVIFileName, 0, STRLEN(ENVIFileName)-4)
      FileName     = FILE_BASENAME(ENVIFileName)
      TIFFFileName = TIFF_DIR + FileName + '.tif'    
      ;Load the Landsat Files
      ENVI_OPEN_FILE, ENVIFileName, R_FID = ENVI_FID
      IF(ENVI_FID EQ -1) THEN CONTINUE
      ;Width, Height, Band dimensions,starting sample and row of the image
      ENVI_FILE_QUERY, ENVI_FID, NB=NB, NS=Width, NL=Height, DIMS=DIMS,$
                       BNAMES=BNAMES   
      ; Save as a external raster file
      ENVI_OUTPUT_TO_EXTERNAL_FORMAT, FID=ENVI_FID,POS=LINDGEN(NB),DIMS=DIMS,$
                               OUT_BNAME=BNAMES, OUT_NAME=TIFFFileName, /TIFF     
      ENVI_FILE_MNG, ID=ENVI_FID, /REMOVE
     ENDFOR
END
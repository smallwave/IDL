;*****************************************************************************
;; $Id: envi45_config/Program/LakeMappingTools/PUBLIC_SelectFilesFromTxtFileName
;;
;; Author: Junli LI, Geography Department of UCLA, Los Angeles, CA 90095
;+
;; NAME:
;;   GLOVIS_RadCoeff_ETM
;;
;; PURPOSE:
;;   Load the FileNames to be processed from TxtFileName and find them from 
;;   INFile_DIR, then extract them from INFile_DIR to OUTFile_DIR
;;
;; PARAMETERS:
;;
;;   LandsatMetFile - Landsat meta file info
;;   Gains          - Gains for radiance calibration
;;   Offsets        - Offsets for radiance calibration
;;   SunAzimuth     - sun azimuth angle
;;   SunElev        - sun elevation angle
;;   
;; CALLING PROCEDURES:
;;   GLOVIS_FileHeaderEdit: Edit Envi header file 
;;     
;; CALLING CUSTOM-DEFINED FUNCTIONS:  
;;   
;; MODIFICATION HISTORY:
;;
;;  Written by:  Junli LI, 2009/04/21 03:00 PM
;;  Modified  :  
;;  Modified  : 
;-
;*****************************************************************************

PRO PUBLIC_SelectFilesFromTxtFileName, TxtFileName, INFile_DIR, OUTFile_DIR
    
    ; ########################################################################
    ; Temporary variables, just for testing
    TxtFileName         = 'H:\MosaicProcess\2010_mosaickedImages.txt'       
    INFile_DIR          = 'H:\CentralAsia2010_refl\'
    OUTFile_DIR         = 'H:\CentralAsia2010_refl_selected\' 
    ; ########################################################################
    
    OPENR, hFile, TxtFileName, /GET_LUN
    FILENAMES = ''
    WHILE ~ EOF(hFile) DO BEGIN
       READF, hFile, FILENAMES
       STR_FILENAME = STRTRIM(FILENAMES[0],2)+'*'
       ;Find all the files in INFile_DIR whose names match with STR_FILENAME
       FilePaths = FILE_SEARCH(INFile_DIR,STR_FILENAME, COUNT=FileCount,$
                                   /TEST_READ, /FULLY_QUALIFY_PATH) 
       IF(FileCount LE 0) THEN CONTINUE
       FOR i=0,FileCount-1 DO BEGIN
          FileI = FilePaths[i]
          FileJ = OUTFile_DIR + FILE_BASENAME(FileI)
          FILE_MOVE,FileI,FileJ
       ENDFOR
    ENDWHILE
    FREE_LUN, hFile
    
END
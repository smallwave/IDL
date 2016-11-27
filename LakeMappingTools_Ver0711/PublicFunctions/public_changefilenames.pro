;*****************************************************************************
;; $Id: envi45_config/Program/LakeMappingTools/PUBLIC_SelectFilesFromTxtFileName
;;
;; Author: Junli LI, Geography Department of UCLA, Los Angeles, CA 90095
;+
;; NAME:
;;   GLOVIS_RadCoeff_ETM
;;
;; PURPOSE:
;;   change the file name 
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



PRO PUBLIC_ChangeFileNames,INFile_DIR
    
    ; ########################################################################
    ; Temporary variables, just for testing       
    INFile_DIR         = '/Volumes/D2/tm/1990/TM1990_1/'
    ; ########################################################################
 
     STR_FILENAME = '*.tar.gz'
       ;Find all the files in INFile_DIR whose names match with STR_FILENAME
       FilePaths = FILE_SEARCH(INFile_DIR,STR_FILENAME, COUNT=FileCount,$
                                   /TEST_READ, /FULLY_QUALIFY_PATH) 
       FOR i=0,FileCount-1 DO BEGIN
          FileI = FILE_BASENAME(FilePaths[i])
          FileJ = INFile_DIR+STRMID(FileI, 2, STRLEN(FileI) - 2)
          
          FILE_MOVE,FilePaths[i],FileJ
       ENDFOR
    print,'end'
END
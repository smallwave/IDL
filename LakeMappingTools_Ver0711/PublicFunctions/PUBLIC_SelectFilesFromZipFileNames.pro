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



PRO PUBLIC_SelectFilesFromZipFileNames, TxtFileName, INFile_DIR, OUTFile_DIR
     
    ; ########################################################################
    ; Temporary variables, just for testing
    TxtFileName         = '/Volumes/D2/CentralAsia_Index/CentralAsia2000_Selected.txt'       
    INFile_DIR          = '/Volumes/D2/2000/'
    OUTFile_DIR         = '/Volumes/D2/2000_Selected/' 
    txtMissingFiles     = '/Volumes/D2/CentralAsia_Index/CentralAsia2000_Selected_missing.txt'  
    ; ########################################################################
    
    OPENR, hFile, TxtFileName, /GET_LUN
    OPENW, hSaveFile, txtMissingFiles, /GET_LUN
    gzFilePath = ''
    WHILE ~ EOF(hFile) DO BEGIN
       READF, hFile, gzFilePath
       gzFileName   = FILE_BASENAME(gzFilePath)
       SensorID     = STRMID(gzFileName,0,3)
       Path         = STRMID(gzFileName,3,3)
       Row          = STRMID(gzFileName,6,3)
       AcqDate      = STRMID(gzFileName,9,7)
       sYear        = STRMID(AcqDate,0,4)
       nYear        = LONG(sYear)
       nDays        = LONG(STRMID(AcqDate,4,3))
       sDate        =  sYear+DOY_to_MonthDay(nYear,nDays)
       
       STR_FILENAME = 'P' + Path + 'R'+Row+'_'+SensorID+'D'+sDate+'*'
       
       ;Find all the files in INFile_DIR whose names match with STR_FILENAME
       FilePaths = FILE_SEARCH(INFile_DIR,STR_FILENAME, COUNT=FileCount,$
                                   /TEST_READ, /FULLY_QUALIFY_PATH) 
       IF(FileCount LE 0) THEN BEGIN
         PRINTF, hSaveFile, gzFileName
       ENDIF ELSE BEGIN
         FOR i=0,FileCount-1 DO BEGIN
            FileI = FilePaths[i]
            FileJ = OUTFile_DIR + FILE_BASENAME(FileI)
            FILE_MOVE,FileI,FileJ
         ENDFOR
       ENDELSE
    ENDWHILE
    FREE_LUN, hFile
    FREE_LUN, hSaveFile
    
END
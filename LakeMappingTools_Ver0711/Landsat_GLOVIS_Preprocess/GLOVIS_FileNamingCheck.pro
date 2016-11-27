;*****************************************************************************
;; $Id: envi45_config/Program/LakeMappingTools/GLOVIS_FileNaming
;;
;; Author: Junli LI, Geography Department of UCLA, Los Angeles, CA 90095
;+
;; NAME:
;;   GLOVIS_FileNamingCheck
;;
;; PURPOSE:
;;  Check the landsat files with USGS GLOVIS file naming rules
;;
;*****************************************************************************
;; PARAMETERS:
;;
;;   FileName      - Landsat zip filename which is downloaded from GLOVIS
;;
;; CALLING PROCEDURES:
;;     
;; CALLING CUSTOM-DEFINED FUNCTIONS:  
;;   LandsatLakeMapping : lake delineation main programme
;;
;; MODIFICATION HISTORY:
;;
;;  Written by:  Junli LI, 2009/04/21 11:00 AM
;;  Modified  :  
;;  Modified  : 
;-
;*****************************************************************************

FUNCTION GLOVIS_FileNamingCheck, FileName
   
   FileName= FILE_BASENAME(FileName)
   ; Get the path and row ID from Landsat File name
   sPath   = STRMID(FileName,0,1)
   sRow    = STRMID(FileName,4,1)
   bWRS    = STRCMP(sPath,'P') AND STRCMP(sRow, 'R')
   ; Get the Sensor ID
   sSensor = STRMID(Filename,9,2)
   bSensor = STRCMP(sSensor,'LM') OR STRCMP(sSensor,'LT') OR STRCMP(sSensor,'LE')
   ; Get the Date ID
   sDate   = STRMID(Filename,12,1)
   bDate   = STRCMP(sDate,'D')
   
   IF( bWRS AND bSensor AND bDate) THEN RETURN, 1 ELSE RETURN, 0
   
END
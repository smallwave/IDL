
;*****************************************************************************
;; $Id: envi45_config/Program/LakeMappingTools/GLOVIS_GetSensorIDFromFiles
;;
;; Author: Junli LI, Geography Department of UCLA, Los Angeles, CA 90095
;+
;; NAME:
;;   GLOVIS_GetSensorIDFromFiles
;;
;; PURPOSE:
;;   This function gives the sensor ID from the landsat gz filename
;;   The reason to get the Sensor ID is the different Landsat file format and
;;       meta format, for example, Landsat MSS/TM/ETM+ have different metfiles
;;       and the band file naming rules are also different, we need to handle 
;;       these conditions separately for automatic operations
;;   SensorID (1) MSS( LM1 LM2 LM3 LM4 LM5) (2) TM1990s(LT4 LT5)
;;            (3) TM2000s(LT4 LT5) (4) ETM (LE7)           
;;
;; PARAMETERS:
;;
;;   gzFileName  - Landsat gz filename for a Landsat scene
;;
;; CALLING PROCEDURES:
;;   GLOVIS_LandsatFiles_ZIPtoENVI: Generate ENVI files from GLOVIS zip files 
;;     
;; CALLING CUSTOM-DEFINED FUNCTIONS:  
;;   
;;
;; MODIFICATION HISTORY:
;;
;;  Written by:  Junli LI, 2009/04/21 03:00 PM
;;  Modified  :  
;;  Modified  : 
;-
;*****************************************************************************

FUNCTION GLOVIS_GetSensorIDFromFiles, gzFileName
   
   Sensor     = STRMID(gzFileName,0,3)
   sYear      = STRMID(gzFileName,9,4)
   nYear      = LONG(sYear)
   
   ; Landsat MSS sensor ID
   IF(Sensor EQ 'LM1' OR Sensor EQ 'LM2' OR Sensor EQ 'LM3' OR Sensor EQ 'LM4' $
      OR Sensor EQ 'LM5' ) THEN SensorID = Sensor
   
   ; Landsat TM sensor ID
   IF(Sensor EQ 'LT4' OR Sensor EQ 'LT5') THEN BEGIN
      IF(nYear GT 1980 AND nYear LT 1998) THEN SensorID = 'TM'+'1990s'
      IF(nYear GE 1998) THEN SensorID = 'TM'+'2000s'
   ENDIF
   
   ; Landsat ETM+ sensor ID 
   IF(Sensor EQ 'LE7') THEN SensorID = Sensor

    RETURN, SensorID
END
;******************************************************************************
;; $Id:  envi45_config/Program/LakeMappingTools//GetLandsatSensorType.pro $
;;
;; Author: Junli LI, Geography Department of UCLA, Los Angeles, CA 90095
;+
;; NAME:
;;   GLOVIS_SensorType
;;
;; PURPOSE:
;;   The function get the sensor type from the Landsat file name
;;
;; PARAMETERS:
;;
;;   LandsatFilePath(In)- the landsat single scene directory.
;;
;; OUTPUTS:
;;   Sensor type of Landsat file, 'MSS' 'TM' 'ETM' 
;;
;; CALLING CUSTOM-DEFINED FUNCTIONS:  MODISLakeExtraction LandsatCalibration
;;                                    
;; MODIFICATION HISTORY:
;;   Written by:  Junli LI, 2008/02/15 06:00 PM
;;   Modified  :  Junli LI, 2008/04/01 12:00 AM
;-
;******************************************************************************

Function GLOVIS_SensorType, LandsatFilePath

   ; Get the file name from the full file path
   FileName = FILE_BASENAME(LandsatFilePath)

   ; Find the sensor type from the directroy name
    SensorType    = ''
   ; (1) Sensor Type = 'MSS'
   IF(STRMATCH(FileName,'*_LM*')) THEN BEGIN
       SensorType  = 'MSS'
   ENDIF

   ; (2) Sensor Type = 'TM'
   IF(STRMATCH(FileName,'*_LT*')) THEN BEGIN
       SensorType  = 'TM'
   ENDIF

   ; (3) Sensor Type = 'ETM' LE7
   IF(STRMATCH(FileName,'*_LE*')) THEN BEGIN
        SensorType  = 'ETM'
   ENDIF

   RETURN, SensorType

END
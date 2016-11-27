;******************************************************************************
;; $Id: envi45_config/Program/LakeExtraction/GetLandsatSensorType.pro $
;;
;; Author: Junli LI, Geography Department of UCLA, Los Angeles, CA 90095
;+
;; NAME:
;;   GetLandsatSensorType
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

Function GLCF_SensorType, LandsatFilePath

   ; Get the file name from the full file path
   FileName = FILE_BASENAME(LandsatFilePath)

   ; Find the sensor type from the directroy name
    SensorType    = ''
   ; (1) Sensor Type = 'MSS'
   IF( STRMATCH(FileName,'*_1m*') OR STRMATCH(FileName,'*_2m*') OR $
       STRMATCH(FileName,'*_3m*') OR STRMATCH(FileName,'*_4m*') OR $
       STRMATCH(FileName,'*_5m*') ) THEN BEGIN
       SensorType  = 'MSS'
   ENDIF

   ; (2) Sensor Type = 'TM'
   IF( STRMATCH(FileName,'*_4t*') OR STRMATCH(FileName,'*_5t*') ) THEN BEGIN
       SensorType  = 'TM'
   ENDIF

   ; (3) Sensor Type = 'ETM'
   IF( STRMATCH(FileName,'*_7x*') OR STRMATCH(FileName,'*_7dk*')) THEN BEGIN
        SensorType  = 'ETM'
   ENDIF

   RETURN, SensorType

END
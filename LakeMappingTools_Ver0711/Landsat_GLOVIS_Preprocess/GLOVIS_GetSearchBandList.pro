
;*****************************************************************************
;; $Id: envi45_config/Program/LakeMappingTools/GLOVIS_GetSearchBandList
;;
;; Author: Junli LI, Geography Department of UCLA, Los Angeles, CA 90095
;+
;; NAME:
;;   GLOVIS_GetSearchBandList
;;
;; PURPOSE:
;;   This function gives file band suffix for each kind of Landsat products
;;   different types of Landsat Sensor and different acqusition date have 
;;   releative band file names, we need to define the file search filters for
;;   each type of occasions            
;;
;; PARAMETERS:
;;
;;   gzFileName  -  Landsat gz filename for a Landsat scene
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
;-
;*****************************************************************************

FUNCTION GLOVIS_GetSearchBandList, gzFileName
   
   Sensor     = GLOVIS_GetSensorIDFromFiles(gzFileName)
   
   ; Landsat MSS
   IF(Sensor EQ 'LM1' OR Sensor EQ 'LM2' OR Sensor EQ 'LM3' ) THEN BEGIN
      SearchBandFiles = ['*_B4.tif', '*_B5.tif', '*_B6.tif', '*_B7.tif']
   ENDIF 
   
   IF( Sensor EQ 'LM4' OR Sensor EQ 'LM5' ) THEN BEGIN
      SearchBandFiles = ['*_B1.TIF', '*_B2.TIF', '*_B3.TIF','*_B4.TIF']
   ENDIF
   
   ; Landsat TM 1980s-1990s
   IF(Sensor EQ 'TM1990s' ) THEN BEGIN
      SearchBandFiles = ['*_B1.TIF','*_B2.TIF','*_B3.TIF','*_B4.TIF', $
                         '*_B5.TIF','*_B7.TIF']
   ENDIF
   
   ; Landsat TM 2000s
   IF(Sensor EQ 'TM2000s') THEN BEGIN
      SearchBandFiles = ['*_B10.TIF', '*_B20.TIF', '*_B30.TIF','*_B40.TIF',$
                         '*_B50.TIF','*_B70.TIF']
   ENDIF
   
   ; Landsat ETM+ sensor ID 
   IF(Sensor EQ 'LE7') THEN BEGIN
       SearchBandFiles = ['*_B10.TIF', '*_B20.TIF', '*_B30.TIF','*_B40.TIF',$
                         '*_B50.TIF','*_B70.TIF']
   ENDIF

    RETURN, SearchBandFiles
END
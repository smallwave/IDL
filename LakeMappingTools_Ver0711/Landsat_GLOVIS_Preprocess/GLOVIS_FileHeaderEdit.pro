
;*****************************************************************************
;; $Id: envi45_config/Program/LakeMappingTools/GLOVIS_FileHeaderEdit
;;
;; Author: Junli LI, Geography Department of UCLA, Los Angeles, CA 90095
;+
;; NAME:
;;   GLOVIS_FileHeaderEdit
;;
;; PURPOSE:
;;
;;   Read Landsat imaging info from the LandsatMetFile and write them to the
;;   ENVI file           
;;
;; PARAMETERS:
;;  
;;   FileID         - File Handle of the Landsat ENVI Image File
;;
;;   SensorID       - Landsat Sensor type
;;
;;   LandsatMetFile - Landsat meta file info
;;
;; CALLING PROCEDURES:
;;   GLOVIS_LandsatFiles_ZIPtoENVI: Generate ENVI files from GLOVIS zip files 
;;     
;; CALLING CUSTOM-DEFINED FUNCTIONS:  
;;   GLOVIS_MSSRadCoeff
;;   GLOVIS_TM2000sRadCoeff
;;   GLOVIS_TM1990sRadCoeff
;;   GLOVIS_ETMRadCoeff
;; MODIFICATION HISTORY:
;;
;;  Written by:  Junli LI, 2009/04/21 03:00 PM
;;  Modified  :  
;;  Modified  : 
;-
;*****************************************************************************

PRO GLOVIS_FileHeaderEdit, FileID, SensorID, LandsatMetFile
    
    ; Read the calibration coefficients and sensor-sun angles from meta file
    IF(FILE_TEST(LandsatMetFile, /READ)) THEN BEGIN
       ; MSS meta file
       IF(SensorID EQ 'LM1' OR SensorID EQ 'LM2' OR SensorID EQ 'LM3' OR $
          SensorID EQ 'LM4' OR SensorID EQ 'LM5') THEN BEGIN
         GLOVIS_RadCoeff_MSS, LandsatMetFile, SensorID, Gains=Gains, Offsets=Offsets,$
                             SunAzimuth=SunAzimuth, SunElev=SunElev
         Sensor = 'Landsat MSS'
       ENDIF
       
       ; TM meta file in 1990s
       IF(SensorID EQ 'TM1990s') THEN BEGIN
         GLOVIS_RadCoeff_TM1990s, LandsatMetFile, Gains=Gains, Offsets=Offsets,$
                                 SunAzimuth=SunAzimuth, SunElev=SunElev
         Sensor = 'Landsat TM'
       ENDIF
       
       ; TM meta file in 2000s
       IF(SensorID EQ 'TM2000s') THEN BEGIN
         GLOVIS_RadCoeff_TM2000s, LandsatMetFile, Gains=Gains, Offsets=Offsets,$
                                 SunAzimuth=SunAzimuth, SunElev=SunElev
         Sensor = 'Landsat TM'
       ENDIF
       
       ; ETM+ Meta File
       IF(SensorID EQ 'LE7') THEN BEGIN
         GLOVIS_RadCoeff_ETM, LandsatMetFile, Gains=Gains, Offsets=Offsets,$
                             SunAzimuth=SunAzimuth, SunElev=SunElev
         Sensor = 'Landsat TM'
       ENDIF
       
    ENDIF
    
    ; SensorID Type, Band names, Wavelength Units, Wavelength,FWHM_wavelength
    Wavelength_units= 'Micrometers'
    IF(SensorID EQ 'LM1' OR SensorID EQ 'LM2' OR SensorID EQ 'LM3' OR $
          SensorID EQ 'LM4' OR SensorID EQ 'LM5') THEN BEGIN
        BandNames       = ['Band 1', 'Band 2', 'Band 3', 'Band 4']
        Wavelength      = [0.550000, 0.650000, 0.750000, 0.950000]
        FWHM_wavelength = [0.100000, 0.100000, 0.100000, 0.300000]
    ENDIF ELSE BEGIN
        BandNames       = ['Band 1', 'Band 2', 'Band 3', 'Band 4', 'Band 5', 'Band 7']
        Wavelength      = [0.485000, 0.560000, 0.660000, 0.830000, 1.650000, 2.215000]
        FWHM_wavelength = [0.070000, 0.080000, 0.060000, 0.140000, 0.200000, 0.270000]
    ENDELSE
    ;
    ; Reset the header file
    
     ;Set the header value
    ENVI_ASSIGN_HEADER_VALUE, FID=FileID, KEYWORD ='sensor type',  VALUE = Sensor
    ENVI_ASSIGN_HEADER_VALUE, FID=FileID, KEYWORD ='wavelength units',  VALUE = Wavelength_units
    ENVI_ASSIGN_HEADER_VALUE, FID=FileID, KEYWORD ='band names',  VALUE = BandNames
    ENVI_ASSIGN_HEADER_VALUE, FID=FileID, KEYWORD ='wavelength',  VALUE = Wavelength, PRECISION=6
    ENVI_ASSIGN_HEADER_VALUE, FID=FileID, KEYWORD ='fwhm',  VALUE = FWHM_wavelength, PRECISION=6
    ENVI_ASSIGN_HEADER_VALUE, FID=FileID, KEYWORD ='data gain values',    VALUE = Gains, PRECISION=5
    ENVI_ASSIGN_HEADER_VALUE, FID=FileID, KEYWORD ='data offset values',  VALUE = Offsets, PRECISION=5
    ENVI_ASSIGN_HEADER_VALUE, FID=FileID, KEYWORD ='Sun azimuth angle', VALUE=SunAzimuth, PRECISION=5
    ENVI_ASSIGN_HEADER_VALUE, FID=FileID, KEYWORD ='Sun elevation angle', VALUE=SunElev, PRECISION=5
    ; Write the values to the file header
    ENVI_WRITE_FILE_HEADER, FileID

END
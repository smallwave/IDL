;*****************************************************************************
;; $Id: envi45_config/Program/LakeMappingTools/GLOVIS_RadCoeff_MSS
;;
;; Author: Junli LI, Geography Department of UCLA, Los Angeles, CA 90095
;+
;; NAME:
;;   GLOVIS_RadCoeff_MSS
;;
;; PURPOSE:
;;   Read Landsat MSS sensor radiation info and Satellite-Solar angles from 
;;   the LandsatMetFile
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

PRO GLOVIS_RadCoeff_MSS, LandsatMetFile,SensorID,Gains=Gains,Offsets=Offsets,$
                         SunAzimuth=SunAzimuth, SunElev=SunElev
    
    LM1_Gains = [1.952760,1.574800,1.385830,1.204720]
    LM1_Offset= [0.0,0.0,0.0,0.0]
    
    LM2_Gains = [2.007870,1.385830,1.149610,0.997373]
    LM2_Offset= [8.0,6.0,6.0,3.66667]
    
    LM3_Gains = [2.007870,1.385830,1.149610,1.00000]
    LM3_Offset= [4.0,3.0,3.0,1.0]
       
    LM4_Gains = [1.842520,1.259840,1.078740,0.881890]
    LM4_Offset= [4.0,4.0,5.0,4.0]
    
    LM5_Gains = [2.086610,1.385830,1.125980,0.944882]
    LM5_Offset= [3.0,3.0,5.0,3.0]
    
    OPENR, hFile, LandsatMetFile, /GET_LUN
    ; Read the file until get the solar angles
    str           = ''
    str_Solar     = 'Sun Elevation'
    WHILE ~ EOF(hFile) DO BEGIN
       READF, hFile, str
       IF(STRLEN(str) GT 13) THEN BEGIN
          str1    = STRMID(str,0,13)
          IF(STRCMP(str1,str_Solar) EQ 1) THEN BREAK
       ENDIF
    ENDWHILE
    
    SunElev    = FLOAT(STRMID(str,21,5))
    SunAzimuth = FLOAT(STRMID(str,68,6))
    
    ; Get the Radiance file
    str_Radiance  = 'Algorithm: NASA'
    bFind      = 0
    WHILE ~ EOF(hFile) DO BEGIN
       READF, hFile, str
       IF(STRLEN(str) GE 15) THEN BEGIN
          str1    = STRMID(str,0,15)
          IF(STRCMP(str1,str_Radiance) EQ 1) THEN BEGIN
             bFind = 1
             BREAK
          ENDIF
       ENDIF
    ENDWHILE
    IF(bFind EQ 0) THEN BEGIN
       IF(SensorID EQ 'LM1') THEN BEGIN
          Gains   = LM1_Gains
          Offsets = LM1_Offset 
       ENDIF
       IF(SensorID EQ 'LM2') THEN BEGIN
          Gains   = LM2_Gains
          Offsets = LM2_Offset 
       ENDIF
       IF(SensorID EQ 'LM3') THEN BEGIN
          Gains   = LM3_Gains
          Offsets = LM3_Offset 
       ENDIF
       IF(SensorID EQ 'LM4') THEN BEGIN
          Gains   = LM4_Gains
          Offsets = LM4_Offset 
       ENDIF
       IF(SensorID EQ 'LM5') THEN BEGIN
          Gains   = LM5_Gains
          Offsets = LM5_Offset 
       ENDIF
       RETURN
    ENDIF
    READF, hFile, str  ; ''
    READF, hFile, str  ; 'Band  |  Ref          DN to Radiance          Default'
    READF, hFile, str  ; '      |  Detector    gain       offset       Abs Calib? '
    READF, hFile, str  ; '----------------------------------------------------------'
   
    Gains1   = fltarr(4) ;
    Offsets1 = fltarr(4) ;
    ; Band 4,5,6,7
    READF, hFile, str
    Gains1[0]   = float(strmid(str,20,8))
    Offsets1[0] = float(strmid(str, 32,8))
     READF, hFile, str
    Gains1[1]   = float(strmid(str,20,8))
    Offsets1[1] = float(strmid(str, 32,8))
     READF, hFile, str
    Gains1[2]   = float(strmid(str,20,8))
    Offsets1[2] = float(strmid(str, 32,8))
     READF, hFile, str
    Gains1[3]   = float(strmid(str,20,8))
    Offsets1[3] = float(strmid(str, 32,8))
    FREE_LUN, hFile
    
    Gains   = Gains1
    Offsets = Offsets1 

END
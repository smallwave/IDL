;*****************************************************************************
;; $Id: envi45_config/Program/LakeMappingTools/GLOVIS_RadCoeff_TM1990s
;;
;; Author: Junli LI, Geography Department of UCLA, Los Angeles, CA 90095
;+
;; NAME:
;;   GLOVIS_RadCoeff_TM1990s
;;
;; PURPOSE:
;;   Read Landsat TM sensor radiation info and Satellite-Solar angles from 
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

PRO GLOVIS_RadCoeff_TM1990s, LandsatMetFile, Gains=Gains, Offsets=Offsets, $
                            SunAzimuth=SunAzimuth, SunElev=SunElev

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
    WHILE ~ EOF(hFile) DO BEGIN
       READF, hFile, str
       IF(STRLEN(str) GE 15) THEN BEGIN
          str1    = STRMID(str,0,15)
          IF(STRCMP(str1,str_Radiance) EQ 1) THEN BEGIN
             BREAK
          ENDIF
       ENDIF
    ENDWHILE
    
    READF, hFile, str  ; ''
    READF, hFile, str  ; 'Band  |  Ref          DN to Radiance          Default'
    READF, hFile, str  ; '      |  Detector    gain       offset       Abs Calib? '
    READF, hFile, str  ; '----------------------------------------------------------'
   
    Gains1   = fltarr(6) ;
    Offsets1 = fltarr(6) ;
    FOR i=0,4 DO BEGIN
      READF, hFile, str
      Gains1[i]   = float(strmid(str,20,8))
      Offsets1[i] = float(strmid(str, 32,8))
    ENDFOR
    READF, hFile, str
    READF, hFile, str
    Gains1[5]   = float(strmid(str,20,8))
    Offsets1[5] = float(strmid(str, 32,8)) 
    FREE_LUN, hFile
    
    Gains   = Gains1
    Offsets = Offsets1 

END
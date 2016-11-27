;*****************************************************************************
;; $Id: envi45_config/Program/LakeMappingTools/GLCF_RadCoeff_MSS
;;
;; Author: Junli LI, Geography Department of UCLA, Los Angeles, CA 90095
;+
;; NAME:
;;   GLCF_RadCoeff_MSS
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
;;  Written by:  Junli LI, 2009/06/20 03:00 PM
;;  Modified  :  
;;  Modified  : 
;-
;*****************************************************************************

PRO GLCF_RadCoeff_MSS, LandsatMetFile,Gains=Gains,Offsets=Offsets,$
                       SunAzimuth=SunAzimuth, SunElev=SunElev
    
    OPENR, hFile, LandsatMetFile, /GET_LUN
    
    ;**************************************************************************
    ; [1] Read the sun angles from the meta file
    ;**************************************************************************
    ; Read the file until get the solar angles
    str           = ''
    str_Solar     = 'SUN_ELEVATION'
    WHILE ~ EOF(hFile) DO BEGIN
       READF, hFile, str
       IF(STRLEN(str) GT 13) THEN BEGIN
          str1    = STRMID(str,0,13)
          IF(STRCMP(str1,str_Solar) EQ 1) THEN BREAK
       ENDIF
    ENDWHILE
    
    ; get the Sun Elevation data
    Pos1       = STRPOS(str, '=')+1
    Pos2       = STRPOS(str, ';')
    SunElev    = FLOAT(STRMID(str,Pos1,Pos2-Pos1))
    ; Read the Sun Azimuth data
    READF, hFile, str
    Pos1       = STRPOS(str, '=')+1
    Pos2       = STRPOS(str, ';')
    SunAzimuth = FLOAT(STRMID(str,Pos1,Pos2-Pos1))
    
    ;**************************************************************************
    ; [2] Read the sun angles from the meta file
    ;**************************************************************************
    Gain       = FLTARR(4)
    Offset     = FLTARR(4)
    str        = ''
    ; Band 1
    str_Rad    = 'BAND1_RADIOMETRIC_GAINS/BIAS='
    WHILE ~ EOF(hFile) DO BEGIN
       READF, hFile, str
       IF(STRLEN(str) GT 32) THEN BEGIN
          str1 = STRMID(str,0,29)
          IF(STRCMP(str1,str_Rad) EQ 1) THEN BREAK
       ENDIF
    ENDWHILE
    Pos1       = STRPOS(str, '=')+1
    Pos2       = STRPOS(str, ',')
    Gain[0]    = FLOAT(STRMID(str,Pos1,Pos2-Pos1))
    Pos1       = Pos2+1
    Pos2       = STRPOS(str, ';')
    Offset[0]  = FLOAT(STRMID(str,Pos1,Pos2-Pos1))
    
    ; Band 2
    str_Rad    = 'BAND2_RADIOMETRIC_GAINS/BIAS='
    WHILE ~ EOF(hFile) DO BEGIN
       READF, hFile, str
       IF(STRLEN(str) GT 32) THEN BEGIN
          str1 = STRMID(str,0,29)
          IF(STRCMP(str1,str_Rad) EQ 1) THEN BREAK
       ENDIF
    ENDWHILE
    Pos1       = STRPOS(str, '=')+1
    Pos2       = STRPOS(str, ',')
    Gain[1]    = FLOAT(STRMID(str,Pos1,Pos2-Pos1))
    Pos1       = Pos2+1
    Pos2       = STRPOS(str, ';')
    Offset[1]  = FLOAT(STRMID(str,Pos1,Pos2-Pos1))
    
    ; Band 3
    str_Rad    = 'BAND3_RADIOMETRIC_GAINS/BIAS='
    WHILE ~ EOF(hFile) DO BEGIN
       READF, hFile, str
       IF(STRLEN(str) GT 32) THEN BEGIN
          str1 = STRMID(str,0,29)
          IF(STRCMP(str1,str_Rad) EQ 1) THEN BREAK
       ENDIF
    ENDWHILE
    Pos1       = STRPOS(str, '=')+1
    Pos2       = STRPOS(str, ',')
    Gain[2]    = FLOAT(STRMID(str,Pos1,Pos2-Pos1))
    Pos1       = Pos2+1
    Pos2       = STRPOS(str, ';')
    Offset[2]  = FLOAT(STRMID(str,Pos1,Pos2-Pos1))
    
    ; Band 4
    str_Rad    = 'BAND4_RADIOMETRIC_GAINS/BIAS='
    WHILE ~ EOF(hFile) DO BEGIN
       READF, hFile, str
       IF(STRLEN(str) GT 32) THEN BEGIN
          str1 = STRMID(str,0,29)
          IF(STRCMP(str1,str_Rad) EQ 1) THEN BREAK
       ENDIF
    ENDWHILE
    Pos1       = STRPOS(str, '=')+1
    Pos2       = STRPOS(str, ',')
    Gain[3]    = FLOAT(STRMID(str,Pos1,Pos2-Pos1))
    Pos1       = Pos2+1
    Pos2       = STRPOS(str, ';')
    Offset[3]  = FLOAT(STRMID(str,Pos1,Pos2-Pos1))
    
    FREE_LUN, hFile
    
    Gains   = Gain
    Offsets = Offset 
END
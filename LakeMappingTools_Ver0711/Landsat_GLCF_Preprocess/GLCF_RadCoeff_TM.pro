;*****************************************************************************
;; $Id: envi45_config/Program/LakeMappingTools/GLCF_RadCoeff_TM
;;
;; Author: Junli LI, Geography Department of UCLA, Los Angeles, CA 90095
;+
;; NAME:
;;   GLCF_RadCoeff_TM
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
;;  Written by:  Junli LI, 2009/06/20 03:00 PM
;;  Modified  :  
;;  Modified  : 
;-
;*****************************************************************************

PRO GLCF_RadCoeff_TM, LandsatMetFile,Gains=Gains,Offsets=Offsets,$
                       SunAzimuth=SunAzimuth, SunElev=SunElev
    str = ''
    OPENR, hFile, LandsatMetFile, /GET_LUN
    
    WHILE NOT EOF(hFile) DO BEGIN
      READF, hFile, str
      Pos1        = STRPOS(str, 'SUN_ELEVATION=')
      Pos2        = STRPOS(str, 'SUN_AZIMUTH=')
      If Pos1 Eq -1 And Pos2 Eq -1 Then Continue
      If Pos1 Ne -1 Then Begin
        Pos1        = Pos1 + 14
        SunElev    = FLOAT(STRMID(str,Pos1,3))
      EndIf
      If Pos2 Ne -1 Then Begin
        Pos2 = Pos2+12
        SunAzimuth = FLOAT(STRMID(str,Pos2,3))
        Break
      EndIf
    ENDWHILE
    FREE_LUN, hFile
    
    ;**************************************************************************
    ; [1] Read the radiance info from the meta file
    ;**************************************************************************
    ;
;    Gain       = FLTARR(7)
;    Offset     = FLTARR(7)
    Gains   = [0.67134, 1.32220, 1.04398, 0.87602, 0.12035, 0.05537, 0.06555]
    Offsets = [-1.52000, -2.84000, -1.17000, -1.51000, -0.37000, 15.30300, -0.15000]
;    data gain values = {
; 0.67134, 1.32220, 1.04398, 0.87602, 0.12035, 0.06555}
;data offset values = {
; -1.52000, -2.84000, -1.17000, -1.51000, -0.37000, -0.15000}
;  
;  Thermal Bands
;  data gain values = 0.05537
;  data offset values = 15.30300
; 
    ; Band 1
;    Pos        = STRPOS(str, 'GAINS/BIASES')+15
;    Gain[0]    = FLOAT(STRMID(str,Pos,8))
;    Pos        = Pos + 9
;    Offset[0]  = FLOAT(STRMID(str,Pos,7))
;    ; Band 2
;    Pos        = Pos + 8
;    Gain[1]    = FLOAT(STRMID(str,Pos,8))
;    Pos        = Pos + 9
;    Offset[1]  = FLOAT(STRMID(str,Pos,7))
;    ; Band 3
;    Pos        = Pos + 8
;    Gain[2]    = FLOAT(STRMID(str,Pos,8))
;    Pos        = Pos + 9
;    Offset[2]  = FLOAT(STRMID(str,Pos,7))
;    ; Band 4
;    Pos        = Pos + 8
;    Gain[3]    = FLOAT(STRMID(str,Pos,8))
;    Pos        = Pos + 9
;    Offset[3]  = FLOAT(STRMID(str,Pos,7))
;    ; Band 5
;    Pos        = Pos + 8
;    Gain[4]    = FLOAT(STRMID(str,Pos,8))
;    Pos        = Pos + 9
;    Offset[4]  = FLOAT(STRMID(str,Pos,7))
;    ; Band 6
;    Pos        = Pos + 8
;    Gain[5]    = FLOAT(STRMID(str,Pos,8))
;    Pos        = Pos + 9
;    Offset[5]  = FLOAT(STRMID(str,Pos,7))
;    ; Band 7
;    Pos        = Pos + 8
;    Gain[6]    = FLOAT(STRMID(str,Pos,8))
;    Pos        = Pos + 9
;    Offset[6]  = FLOAT(STRMID(str,Pos,7))
;    
;    Gain1       = FLTARR(6)
;    Offset1     = FLTARR(6)
;    Gain1[0:4]  = Gain[0:4]
;    Offset1[0:4]= Offset[0:4]
;    Gain1[5]    = Gain[6]
;    Offset1[5]  = Offset[6]
;    Gains       = Gain1
;    Offsets     = Offset1
    
    ;**************************************************************************
    ; [2] Read the sun angles from the meta file
    ;**************************************************************************
    ;
    ;Sun Elevation
;    Pos        = STRPOS(str, 'SUN ELEVATION =')+15
;    SunElev    = FLOAT(STRMID(str,Pos,2))
;    ; Sun Azimuth
;    Pos        = STRPOS(str, 'SUN AZIMUTH =')+13
;    SunAzimuth = FLOAT(STRMID(str,Pos,3))

END
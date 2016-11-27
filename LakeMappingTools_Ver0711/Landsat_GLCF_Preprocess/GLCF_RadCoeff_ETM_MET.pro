;*****************************************************************************
;; $Id: envi45_config/Program/LakeMappingTools/GLCF_RadCoeff_ETM_MET
;;
;; Author: Junli LI, Geography Department of UCLA, Los Angeles, CA 90095
;+
;; NAME:
;;   GLCF_RadCoeff_ETM_MET
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
PRO GLCF_RadCoeff_ETM_MET, LandsatMetFile, Gains=Gains,Offsets=Offsets,$
                          SunAzimuth=SunAzimuth, SunElev=SunElev
    ;
    OPENR, hFile, LandsatMetFile, /GET_LUN

    ; Read the file until line by line to find MIN_MAX_RADIANCE
    str           = ''
    stc_Rad       = 'GROUP = MIN_MAX_RADIANCE'
    WHILE ~ EOF(hFile) DO BEGIN
       READF, hFile, str
       str        = STRTRIM(str,2)
       IF(STRCMP(str,stc_Rad) EQ 1) THEN BREAK
    ENDWHILE

    ; Get LMAX_BAND and LMIN_BAND
    LMAX          = FLTARR(9)
    LMIN          = FLTARR(9)
    FOR i=0,8 DO BEGIN
        READF, hFile, str
        str       = STRTRIM(str,2)
        nIdx      = STRPOS(str,'=')
        LMAX[i]   = FLOAT(STRMID(str,nIdx+1,STRLEN(str)-nIdx-1))
        READF, hFile, str
        str       = STRTRIM(str,2)
        nIdx      = STRPOS(str,'=')
        LMIN[i]   = FLOAT(STRMID(str,nIdx+1,STRLEN(str)-nIdx-1))
    ENDFOR

    ; Read the file until line by line to find MIN_MAX_PIXEL_VALUE
    stc_Rad       = 'GROUP = MIN_MAX_PIXEL_VALUE'
    WHILE ~ EOF(hFile) DO BEGIN
       READF, hFile, str
       str        = STRTRIM(str,2)
       IF(STRCMP(str,stc_Rad) EQ 1) THEN BREAK
    ENDWHILE

    ;Get QCALMAX_Band and QCALMIM_Band
    QCALMAX       = FLTARR(9)
    QCALMIN       = FLTARR(9)
    FOR i=0,8 DO BEGIN
        READF, hFile, str
        str        = STRTRIM(str,2)
        nIdx       = STRPOS(str,'=')
        QCALMAX[i] = FLOAT(STRMID(str,nIdx+1,STRLEN(str)-nIdx-1))
        READF, hFile, str
        str        = STRTRIM(str,2)
        nIdx       = STRPOS(str,'=')
        QCALMIN[i] = FLOAT(STRMID(str,nIdx+1,STRLEN(str)-nIdx-1))
    ENDFOR
    
     ; Read the file until line by line to find SUN_AZIMUTH
    stc_Sun       = 'SUN_AZIMUTH'
    WHILE ~ EOF(hFile) DO BEGIN
       READF, hFile, str
       str        = STRTRIM(str,2)
       nIdx       = STRPOS(str,'=')
       IF(nIdx LT 0) THEN CONTINUE
       str1       = STRTRIM(STRMID(str,0,nIdx),2)
       IF(STRCMP(str1,stc_Sun) EQ 1) THEN BEGIN
          SunAzimuth = FLOAT(STRTRIM(STRMID(str,nIdx+1,STRLEN(str)-nIdx-1),2))
          BREAK
       ENDIF
    ENDWHILE
    ; Read the SUN_ELEVATION\
    stc_Sun    = 'SUN_ELEVATION'
    READF, hFile, str
    str        = STRTRIM(str,2)
    nIdx       = STRPOS(str,'=')
    IF(nIdx GT 0) THEN BEGIN
       str1       = STRTRIM(STRMID(str,0,nIdx),2)
       IF(STRCMP(str1,stc_Sun) EQ 1) THEN BEGIN
          SunElev = FLOAT(STRTRIM(STRMID(str,nIdx+1,STRLEN(str)-nIdx-1),2))
       ENDIF
    ENDIF
    FREE_LUN, hFile

    ; Now calculate the gains and Offsets by given the formula
    ;
    ; L(i) = DN(i) * (LMAX(i)-LMIN(i))/(QCALMAX(i)-QCALMIN(i)) + LMIN(i)
    ;
    ; WHERE, L is the radiance value of Band i,
    ;        Gains(i)  = (LMAX(i)-LMIN(i))/(QCALMAX(i)-QCALMIN(i))
    ;        Offsets(i) = LMIN(i)
    FOR i=0,4 DO BEGIN
       Gains[i]   = (LMAX[i]-LMIN[i])/(QCALMAX[i]-QCALMIN[i])
       Offsets[i]  = LMIN[i]
    ENDFOR

    Gains[5]      = (LMAX[7]-LMIN[7])/(QCALMAX[7]-QCALMIN[7])
    Offsets[5]     = LMIN[7]

END
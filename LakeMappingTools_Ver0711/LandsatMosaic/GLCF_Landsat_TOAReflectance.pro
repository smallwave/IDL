
;******************************************************************************
;;
;; $Id: //envi45_config/Program/LakeExtraction/LandsatRadiance.pro $
;;
;; Author: Junli LI, Geography Department of UCLA, Los Angeles, CA 90095
;+
;; NAME:
;;   LandsatRadiance
;;
;; PURPOSE:
;;   WaterExtraction is a procedure that performs water segmentation on remote 
;;   sensing imagery to get lake mapping layers, and it's used as the succedent 
;;   lake dynamic analysis. Here NDWI(normalized difference water index) is the  
;;   index of automatic water body recognition(larger than 4 pixels). The main
;;   idea of this segmentation algorithm is: a relatively low NDWI threshold is
;;   applied to global image segmentaion(NDWI >= 0.2), making sure that most of
;;   the water pixels avaialbe. But different lake 
;;
;; PARAMETERS:
;;
;;   LandsatFile(in) - The Landsat ETM/TM/MSS file
;;
;;   RAD_FID(out)    - Radiance file FID 
;;                        
;; MODIFICATION HISTORY:
;;   Written by:  Junli LI, 2008/04/06 11:40 PM
;;   Modified  :  Junli LI, 2008/11/05 12:00 AM
;-
;******************************************************************************

PRO GLCF_Landsat_TOAReflectance, LandsatFile, ReflFile

    ; 1) Get the acquisition date from Landsat file name
    ;    Acquisition date
    FileName       = FILE_BASENAME(LandsatFile)
    nIndex         = STRPOS(FileName, '_')
    Sat_Type       = STRMID(FileName, nIndex+1,2)
    AcqDate        = STRMID(FileName, nIndex+3,8)
    nYear          = UINT(STRMID(AcqDate, 0,4))
    nMonth         = UINT(STRMID(AcqDate, 4,2))
    nDay           = UINT(STRMID(AcqDate, 6,2))

    ; 2) Load the Landsat file and get the basic info
    ENVI_OPEN_FILE, LandsatFile, R_FID = TM_FID
    ; Get the image basic information of the Landsat images
    ENVI_FILE_QUERY, TM_FID, NB=NB, DIMS=DIMS, BNAMES=BNAMES
    ; [1.4] sun elevation angle
    SunElev   = ENVI_GET_HEADER_VALUE(TM_FID, 'Sun elevation angle', /FLOAT)
    IF(SunElev LE 0.0) THEN RETURN
    INPOS = LINDGEN(NB)
    
    ; 3) For the Landsat MSS data
    IF( Sat_Type EQ '1m' OR Sat_Type EQ '2m' OR Sat_Type EQ '3m' $
       OR Sat_Type EQ '4m' OR Sat_Type EQ '5m') THEN BEGIN

       ; get the calibration information from the acquisition date
       Julian_197507 = JULDAY(nMonth,nDay,nYear)-JULDAY(7,16,1975)
       Julian_197806 = JULDAY(nMonth,nDay,nYear)-JULDAY(6,1,1978)
       Julian_198208 = JULDAY(nMonth,nDay,nYear)-JULDAY(8,26,1982)
       T_198303      = JULDAY(3,31,1983)-JULDAY(8,26,1982)
       Julian_198204 = JULDAY(nMonth,nDay,nYear)-JULDAY(4,6,1982)
       T_198410      = JULDAY(10,8,1984)-JULDAY(8,26,1982)
       ;
       Julian_197602 = JULDAY(nMonth,nDay,nYear)-JULDAY(2,1,1976)
       Julian_198210 = JULDAY(nMonth,nDay,nYear)-JULDAY(10,22,1982)

       ; set the parameter of SAT and DATE which are need in MSSCAL_DOIT
       CASE Sat_Type OF
         ;
         '1m' : BEGIN
                  SAT    = 1
                  DATE   = 0
                END
         '2m' : BEGIN
                  SAT    = 2
                  DATE   = (Julian_197507 LE 0) ? 0 : 1
                END
         '3m' : BEGIN
                  SAT    = 3
                  DATE   = (Julian_197806 LE 0) ? 0 : 1
                END
         '4m' : BEGIN
                  SAT    = 4
                  IF(Julian_198208 LE 0) THEN DATE = 0 $
                  ELSE IF(Julian_198208 GT T_198303) THEN DATE = 2 $
                  ELSE DATE = 1
                END
         '5m' : BEGIN
                  SAT    = 5
                  IF(Julian_198204 LE 0) THEN DATE = 0 $
                  ELSE IF(Julian_198204 GT T_198410) THEN DATE = 2 $
                  ELSE DATE = 1
                END
            ;
       ENDCASE

       ; Perform the MSS calibration
       ; QCAL_DATE - Set it for Landsat-1, 2, or 3 MSS data collected before 
       ;       February 1, 1976; and for Landsat-4 MSS data collected before 
       ;       October 22, 1982. Leave QCAL_DATE unset for all other data.

       ; with QCAL_DATE
       
       IF((Julian_197602 LE 0) OR (Julian_198210 LE 0) ) THEN BEGIN
           ENVI_DOIT, 'MSSCAL_DOIT', FID=TM_FID,POS=INPOS,DIMS=DIMS,CAL_TYPE=1,$
                      DATE=DATE, QCAL_DATE=0, SAT=SAT, SUN_ANGLE=SunElev, $
                      OUT_BNAME=BNAMES, OUT_NAME=ReflFile, R_FID=REF_FID
       ; without QCAL_DATE
       ENDIF ELSE BEGIN
          ENVI_DOIT, 'MSSCAL_DOIT', FID=TM_FID,POS=INPOS,DIMS=DIMS,CAL_TYPE=1,$
                     DATE=DATE, SAT=SAT, OUT_BNAME=BNAMES, SUN_ANGLE=SunElev,$
                     OUT_NAME=ReflFile, R_FID=REF_FID
       ENDELSE
       
    ENDIF

    ; 4) For the Landsat 4 or 5 TM data
    IF(Sat_Type EQ '4t' OR Sat_Type EQ '5t') THEN BEGIN
    
       ; set the parameter of SAT and DATE which are need in TMCAL_DOIT
       ; SAT
       SAT = (Sat_Type EQ '5t') ? 5 : 4
       ; DATE: If date<1983-08-01, set 0,date>1984-01-15 set 2, ELSE set 1
       nJulian        = JULDAY(nMonth,nDay,nYear)-JULDAY(8,1,1983)
       nT             = JULDAY(1,15,1984)-JULDAY(8,1,1983)
       IF(nJulian LE 0)       THEN DATE = 0 $
       ELSE IF(nJulian GE nT) THEN DATE = 2 $
       ELSE                        DATE = 1
       ENVI_DOIT, 'TMCAL_DOIT', FID=TM_FID, DIMS=DIMS, BANDS_PRESENT=INPOS,$
                   POS=INPOS, CAL_TYPE=1, DATE=DATE, SAT=SAT,SUN_ANGLE=SunElev,$
                   OUT_BNAME=BNAMES, OUT_NAME=ReflFile, R_FID=REF_FID
    ENDIF
    
    ; Close the File
    ENVI_FILE_MNG, ID = TM_FID, /REMOVE
    ENVI_FILE_MNG, ID = REF_FID, /REMOVE
END
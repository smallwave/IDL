;*****************************************************************************
;;
;; $Id: envi45_config/Program/LakeMappingTools/GLOVIS_Landsat_TOAReflectance.pro $
;;
;; Author: Junli LI, Geography Department of UCLA, Los Angeles, CA 90095
;+
;; NAME:
;;   GLOVIS_Landsat_TOAReflectance
;;
;; PURPOSE:
;;   The pro caculates the TOA surface reflectance from Landsat MSS/TM/ETM+ 
;;   data by using the calibration coefficient from its envi meta file
;;
;; PARAMETERS:
;;
;;   LandsatFile (in) - The Landsat file to be processed (ENVI standard file).
;;
;;   SensorID(in)     -  
;;
;;   BandIdx       (in) - The Band index to be processed
;;
;;   REF_FID    (out) - The output FileID of the reflectance file
;;
;; MODIFICATION HISTORY:
;;   Written by:  Junli LI, 2009/04/06 11:40 PM
;;   Modified  :  Junli LI, 2009/04/23 12:00 AM
;-
;******************************************************************************

PRO GLOVIS_Landsat_TOAReflectance1,LandsatFile, ReflFile
   
    ; Catch Error
    STR_ERROR = ''
    CATCH, Error_status 
    ; This statement begins the error handler: 
    IF Error_status NE 0 THEN BEGIN 
       STR_ERROR = 'GLOVIS_Landsat_TOAReflectance: '+ STRING(Error_status) + ' :'$
                   + !ERROR_STATE.MSG
       PRINT, STR_ERROR
       CATCH, /CANCEL 
       RETURN
    ENDIF
    
    FileName  = FILE_BASENAME(LandsatFile)
    ; WRS 1/2 Path and Row info
    sPathRow  = STRMID(FileName,0,8)
    ; Get the Sensor info
    SensorID  = STRMID(FileName,9,3)
    ; Acq Date
    AcqDate  = STRMID(FileName,13,8)
    
    ;**************************************************************************
    ;
    ; 1) Set the radiometric calibration coefficient for Landsat MSS TM and ETM+
    ;
    ;**************************************************************************
    
    ; [1.1] Solar irradiance
    IF(SensorID EQ 'LM1') THEN ESun = [1823.0,1559.0,1276.0,880.1]
    IF(SensorID EQ 'LM2') THEN ESun = [1829.0,1539.0,1268.0,886.6]
    IF(SensorID EQ 'LM3') THEN ESun = [1839.0,1555.0,1291.0,887.9]
    IF(SensorID EQ 'LM4') THEN ESun = [1827.0,1569.0,1260.0,866.4]
    IF(SensorID EQ 'LM5') THEN ESun = [1824.0,1570.0,1249.0,853.4]
    IF(SensorID EQ 'LT4') THEN ESun = [1983.0,1795.0,1539.0,1028.0,219.8,83.49]
    IF(SensorID EQ 'LT5') THEN ESun = [1983.0,1796.0,1536.0,1031.0,220.0,83.44]
    IF(SensorID EQ 'LE7') THEN ESun = [1997.0,1812.0,1533.0,1039.0,230.8,84.90]
    
    ; [1.2] Sun-Earth Distance
    Dist_E_S  = FLTARR(366)  
    Dist_E_S  = [0.98331,  0.98330,  0.98330,  0.98330,  0.98330,  0.98332,$
                 0.98333,  0.98335,  0.98338,  0.98341,  0.98345,  0.98349,$  
                 0.98354,  0.98359,  0.98365,  0.98371,  0.98378,  0.98385,$ 
                 0.98393,  0.98401,  0.98410,  0.98419,  0.98428,  0.98439,$  
                 0.98449,  0.98460,  0.98472,  0.98484,  0.98496,  0.98509,$  
                 0.98523,  0.98536,  0.98551,  0.98565,  0.98580,  0.98596,$  
                 0.98612,  0.98628,  0.98645,  0.98662,  0.98680,  0.98698,$  
                 0.98717,  0.98735,  0.98755,  0.98774,  0.98794,  0.98814,$  
                 0.98835,  0.98856,  0.98877,  0.98899,  0.98921,  0.98944,$  
                 0.98966,  0.98989,  0.99012,  0.99036,  0.99060,  0.99084,$  
                 0.99108,  0.99133,  0.99158,  0.99183,  0.99208,  0.99234,$  
                 0.99260,  0.99286,  0.99312,  0.99339,  0.99365,  0.99392,$  
                 0.99419,  0.99446,  0.99474,  0.99501,  0.99529,  0.99556,$  
                 0.99584,  0.99612,  0.99640,  0.99669,  0.99697,  0.99725,$  
                 0.99754,  0.99782,  0.99811,  0.99840,  0.99868,  0.99897,$  
                 0.99926,  0.99954,  0.99983,  1.00012,  1.00041,  1.00069,$  
                 1.00098,  1.00127,  1.00155,  1.00184,  1.00212,  1.00240,$  
                 1.00269,  1.00297,  1.00325,  1.00353,  1.00381,  1.00409,$  
                 1.00437,  1.00464,  1.00492,  1.00519,  1.00546,  1.00573,$  
                 1.00600,  1.00626,  1.00653,  1.00679,  1.00705,  1.00731,$  
                 1.00756,  1.00781,  1.00806,  1.00831,  1.00856,  1.00880,$  
                 1.00904,  1.00928,  1.00952,  1.00975,  1.00998,  1.01020,$  
                 1.01043,  1.01065,  1.01087,  1.01108,  1.01129,  1.01150,$  
                 1.01170,  1.01191,  1.01210,  1.01230,  1.01249,  1.01267,$  
                 1.01286,  1.01304,  1.01321,  1.01338,  1.01355,  1.01371,$  
                 1.01387,  1.01403,  1.01418,  1.01433,  1.01447,  1.01461,$  
                 1.01475,  1.01488,  1.01500,  1.01513,  1.01524,  1.01536,$  
                 1.01547,  1.01557,  1.01567,  1.01577,  1.01586,  1.01595,$  
                 1.01603,  1.01610,  1.01618,  1.01625,  1.01631,  1.01637,$  
                 1.01642,  1.01647,  1.01652,  1.01656,  1.01659,  1.01662,$  
                 1.01665,  1.01667,  1.01668,  1.01670,  1.01670,  1.01670,$  
                 1.01670,  1.01669,  1.01668,  1.01666,  1.01664,  1.01661,$  
                 1.01658,  1.01655,  1.01650,  1.01646,  1.01641,  1.01635,$  
                 1.01629,  1.01623,  1.01616,  1.01609,  1.01601,  1.01592,$  
                 1.01584,  1.01575,  1.01565,  1.01555,  1.01544,  1.01533,$  
                 1.01522,  1.01510,  1.01497,  1.01485,  1.01471,  1.01458,$  
                 1.01444,  1.01429,  1.01414,  1.01399,  1.01383,  1.01367,$  
                 1.01351,  1.01334,  1.01317,  1.01299,  1.01281,  1.01263,$  
                 1.01244,  1.01225,  1.01205,  1.01186,  1.01165,  1.01145,$  
                 1.01124,  1.01103,  1.01081,  1.01060,  1.01037,  1.01015,$  
                 1.00992,  1.00969,  1.00946,  1.00922,  1.00898,  1.00874,$  
                 1.00850,  1.00825,  1.00800,  1.00775,  1.00750,  1.00724,$  
                 1.00698,  1.00672,  1.00646,  1.00620,  1.00593,  1.00566,$  
                 1.00539,  1.00512,  1.00485,  1.00457,  1.00430,  1.00402,$  
                 1.00374,  1.00346,  1.00318,  1.00290,  1.00262,  1.00234,$  
                 1.00205,  1.00177,  1.00148,  1.00119,  1.00091,  1.00062,$  
                 1.00033,  1.00005,  0.99976,  0.99947,  0.99918,  0.99890,$  
                 0.99861,  0.99832,  0.99804,  0.99775,  0.99747,  0.99718,$  
                 0.99690,  0.99662,  0.99634,  0.99605,  0.99577,  0.99550,$  
                 0.99522,  0.99494,  0.99467,  0.99440,  0.99412,  0.99385,$  
                 0.99359,  0.99332,  0.99306,  0.99279,  0.99253,  0.99228,$  
                 0.99202,  0.99177,  0.99152,  0.99127,  0.99102,  0.99078,$  
                 0.99054,  0.99030,  0.99007,  0.98983,  0.98961,  0.98938,$  
                 0.98916,  0.98894,  0.98872,  0.98851,  0.98830,  0.98809,$  
                 0.98789,  0.98769,  0.98750,  0.98731,  0.98712,  0.98694,$  
                 0.98676,  0.98658,  0.98641,  0.98624,  0.98608,  0.98592,$  
                 0.98577,  0.98562,  0.98547,  0.98533,  0.98519,  0.98506,$  
                 0.98493,  0.98481,  0.98469,  0.98457,  0.98446,  0.98436,$  
                 0.98426,  0.98416,  0.98407,  0.98399,  0.98391,  0.98383,$  
                 0.98376,  0.98370,  0.98363,  0.98358,  0.98353,  0.98348,$  
                 0.98344,  0.98340,  0.98337,  0.98335,  0.98333,  0.98331]
                 
    ; [1.3] calibration coeffcients from Landsat ID
    ENVI_OPEN_FILE,  LandsatFile, R_FID = Landsat_FID
    ENVI_FILE_QUERY, Landsat_FID, NB=NB, NS=NS,NL=NL,DIMS=DIMS, BNAMES=BNAMES,$
                     DATA_GAINS=Gains, DATA_OFFSETS=Offsets
                     
    IF(N_ELEMENTS(Gains) EQ 0 OR N_ELEMENTS(Offsets) EQ 0) THEN RETURN
     ; Map information
    MapInfo  = ENVI_GET_MAP_INFO(FID=Landsat_FID)
    ; Projection information
    Proj     = ENVI_GET_PROJECTION(FID=Landsat_FID, PIXEL_SIZE=PS)
    
    ; [1.4] sun elevation angle
    SunElev   = ENVI_GET_HEADER_VALUE(Landsat_FID, 'Sun elevation angle', /FLOAT)
    IF(SunElev LE 0.0) THEN RETURN
    
    ; [1.5] acquisition date
    nYear     = UINT(STRMID(AcqDate, 0,4))
    nMonth    = UINT(STRMID(AcqDate, 4,2))
    nDay      = UINT(STRMID(AcqDate, 6,2))
    nDOY      = JULDAY(nMonth,nDay,nYear) - JULDAY(1,0,nYear)
    
    ;**************************************************************************
    ;
    ; 2) DN values to TOA reflectance
    ;
    ;**************************************************************************     
    ; [2.1] Radiance to Reflectance
    ; 
    ; Calculate the reflectance coefficients
    ;        π*d2*(Gains*DN+Offsets)
    ;  ρ= -----------------------------
    ;              ESun*cosθ
    PI         = 3.14159265                  ; Pi
    d          = Dist_E_S[nDOY-1]            ; Earth-Sun distance
    Gain_REF   = 255.0*Gains*(PI*d*d)/(ESun*COS((90-SunElev)*PI/180))
    Offset_REF = 255.0*Offsets*(PI*d*d)/(ESun*COS((90-SunElev)*PI/180))
    
    ; Load the data
    nBand = BYTARR(NS,NL,NB)
    MASK  = BYTARR(NS,NL)
    MASK[*,*] = 1
    FOR i=0,NB-1 DO BEGIN
        nBand[*,*,i]    = ENVI_GET_DATA(FID=Landsat_FID,DIMS=DIMS, POS=[i])
        MASK  = MASK AND (nBand[*,*,i] GT 0)       
    ENDFOR
    
    FOR i=0,NB-1 DO BEGIN
        Band  = FLOAT((nBand[*,*,i]*Gain_REF[i]+Offset_REF[i])*MASK)
        idx   = WHERE(Band GT 255,nCount)
        IF(nCount GT 0) THEN Band[idx] = 255
        idx   = WHERE(Band LT 0,nCount) 
        IF(nCount GT 0) THEN Band[idx] = 1
        nBand[*,*,i] =  BYTE(Band)
    ENDFOR
    
    ENVI_ENTER_DATA, nBand, MAP_INFO=MapInfo, R_FID=REF_FID
    ENVI_FILE_QUERY, REF_FID, DIMS=nDIMS
    nPOS     = LINDGEN(NB) 
    ENVI_OUTPUT_TO_EXTERNAL_FORMAT, FID=REF_FID,POS=nPOS,DIMS=nDIMS,$
                           OUT_BNAME=BNAMES, OUT_NAME=ReflFile, /ENVI

    ENVI_FILE_MNG, ID = Landsat_FID, /REMOVE
    ENVI_FILE_MNG, ID = REF_FID, /REMOVE
    
END
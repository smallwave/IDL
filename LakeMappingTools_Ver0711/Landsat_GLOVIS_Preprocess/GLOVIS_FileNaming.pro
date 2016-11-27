;*****************************************************************************
;; $Id: envi45_config/Program/LakeMappingTools/GLOVIS_FileNaming
;;
;; Author: Junli LI, Geography Department of UCLA, Los Angeles, CA 90095
;+
;; NAME:
;;   GLOVIS_FileNaming
;;
;; PURPOSE:
;;  This function gives the file naming rule to convert a GLOVIS zip filename
;;  to an ENVI filename
;;
;;  Landsat ETM+ TIFF file naming rule: L71137040_04020001126_B10.TIF
;;  Landsat TM  TIFF file naming rule : L5137039_03920061205_B10.TIF (2000s) 
;;                                      LT4139039008929850_B1.tif    (1990s)
;;  Landsat MSS TIFF file naming rule : LM1149035007319710_B4.tif
;;  GLCF TIFF file naming rule        : P136R40_5t19881025_nn1.tif
;;  Our file name rule                
;;    P***R***_L**DYYYYMMDD
;;    P***     : path number
;;    R***     : Row number
;;    L**      : Landsat Sensor Type,(LM1 LM2 LM3 LM4 LM5 LT4 LT5 LE7)
;;    DYYYYMMDD: Year Month Day
;;    LM1149035007319710_B4.tif      -> P149R035_LM1D19730716
;;    L5137039_03920061205_B10.tif   -> P137R039_LT5D20061205
;;    LT4139039008929850_B1.tif      -> P139R039_LT4D19891016
;;    L71137040_04020001126_B10.TIF  -> P137R040_LE7D20001126
;;  (1)The file naming convention for Landsat 7 GeoTIFF is as follows:
;;     L7fppprrr_rrrYYYYMMDD_AAA.TIF  where:
;;     L7          = Landsat-7 mission
;;     f           = ETM+ data format (1 or 2)
;;     ppp         = starting path of the product
;;     rrr_rrr     = starting and ending rows of the product
;;     YYYYMMDD    = acquisition date of the image
;;     AAA         = file type:
;;     Bi          = band i(i=1,2,3,4,5,6L,6H,7,8)
;;     MTL         = Level-1 metadata
;;     TIF         = GeoTIFF file extension
;;  (2)The file naming convention for other Landsat GeoTIFF is as follows:
;;     LTNppprrrOOYYDOY10_AA.TIF (i.e. )where:
;;     LT          = Landsat Thematic Mapper
;;     N           = satellite number(4 or 5).  
;;     ppp         = starting path of the product
;;     rrr         = starting row of the product
;;     OO          = WRS row offset (set to 00)
;;     YY          = last two digits of the year of acquisition           
;;     DOY         = Julian date of acquisition
;;     1           = instrument mode
;;     0           = instrument multiplexor (MUX) 
;;     AA          = file type:
;;     Bi          = band i (i = 1,2,3,4,5,6,7)
;*****************************************************************************
;; PARAMETERS:
;;
;;   ZipFileName  - Landsat zip filename which is downloaded from GLOVIS
;;
;; CALLING PROCEDURES:
;;   GLOVIS_LandsatFiles_Decompress: Generate ENVI files from GLOVIS zip files 
;;     
;; CALLING CUSTOM-DEFINED FUNCTIONS:  
;;   DOY_to_MonthDay : convert DOY(day of year) number to (Month,Day)
;;
;; MODIFICATION HISTORY:
;;
;;  Written by:  Junli LI, 2009/04/21 11:00 AM
;;  Modified  :  
;;  Modified  : 
;-
;*****************************************************************************

FUNCTION GLOVIS_FileNaming, ZipFileName

   ; get the first two characters of the GLOVIS Zip Filename, which identify 
   ; the Landsat sensor type
   SensorID        = STRMID(ZipFileName,0,2)
   
   IF(SensorID EQ 'LT') THEN SensorID = STRMID(ZipFileName,0,3)
   
   ; MSS file
   IF(SensorID EQ 'LM') THEN BEGIN
      SensorType  = SensorID+STRMID(ZipFileName,2,1) 
      sPath       = 'P' + STRMID(ZipFileName,3,3)
      sRow        = 'R' + STRMID(ZipFileName,6,3)
      sYear       = '19'+ STRMID(ZipFileName,11,2)
      nYear       = FIX(sYear)
      nDays       = FIX(STRMID(ZipFileName,13,3))
      sDays       = DOY_to_MonthDay(nYear,nDays)
      sDate       = 'D'+sYear+sDays
   ENDIF
   
   ; ETM file 
   IF(SensorID EQ 'L7') THEN BEGIN
      SensorType  = 'LE7' 
      sPath       = 'P' + STRMID(ZipFileName,3,3)
      sRow        = 'R' + STRMID(ZipFileName,6,3)
      sDate       = 'D'+STRMID(ZipFileName,13,8)
   ENDIF
   
   ; TM file
   IF(SensorID EQ 'L4' OR SensorID EQ 'LT4' OR SensorID EQ 'L5' OR SensorID EQ 'LT5') THEN BEGIN
      IF(SensorID EQ 'L5' OR SensorID EQ 'LT5') THEN  SensorType='LT5' 
      IF(SensorID EQ 'L4' OR SensorID EQ 'LT4') THEN  SensorType='LT4' 
      IF(SensorID EQ 'L4' OR SensorID EQ 'L5') THEN BEGIN 
         sPath       = 'P' + STRMID(ZipFileName,2,3)
         sRow        = 'R' + STRMID(ZipFileName,5,3)
         sDate       = 'D'+STRMID(ZipFileName,12,8)
      ENDIF ELSE BEGIN
         sPath       = 'P' + STRMID(ZipFileName,3,3)
         sRow        = 'R' + STRMID(ZipFileName,6,3)
         sYear       = '19'+ STRMID(ZipFileName,11,2)
         nYear       = FIX(sYear)
         nDays       = FIX(STRMID(ZipFileName,13,3))
         sDays       = DOY_to_MonthDay(nYear,nDays)
         sDate       = 'D'+sYear+sDays
      ENDELSE
   END
        
    ; Output ENVI File Name
    ENVIFileName       = sPath+sRow+'_'+SensorType+sDate
    
    Return, ENVIFileName
END
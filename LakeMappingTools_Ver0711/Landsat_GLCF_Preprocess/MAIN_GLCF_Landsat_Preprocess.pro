
;*****************************************************************************
;; $Id: envi45_config/Program/LakeMappingTools/MAIN_GLCF_Landsat_Preprocess
;;
;; Author: Junli LI, Geography Department of UCLA, Los Angeles, CA 90095
;+
;; NAME:
;;   MAIN_GLCF_Landsat_Preprocess
;;
;; PURPOSE:
;;   The procedure converts GLOVIS Landsat archives from zip files  to ENVI
;;   standard files. It first unzips the *.gz single-band files of each 
;;   Landsat scene with 7Z decompression software, then stack these single
;;   band layers
;-
;*****************************************************************************
;+
;; PARAMETERS:
;;
;;   Landsat_DIR      - The Landsat file directory
;;
;;   ENVIFile_DIR     - The ENVI file directory 
;;
;; CALLING PROCEDURES:
;;   Main Procedure. This procedure converses the landsat datum downloaded from 
;;   GLCF to ENVI standard formats. It first unzips the *.gz single-band files 
;;   of each Landsat scene, then stack them into one ENVI standard file  
;;     
;; CALLING CUSTOM-DEFINED FUNCTIONS:  
;;   GLOVIS_StackBandFiles : convert DOY(day of year) number to (Month,Day)
;;   GLOVIS_FileNaming
;;
;; MODIFICATION HISTORY:
;;
;;  Written by:  Junli LI, 2008/02/15 06:00 PM
;;  Modified  :  Junli LI, 2008/03/31 12:00 AM, renew the ENVI head files(*.hdr) 
;;               and add Landsat calibration information and sensor information,
;;               so landsat ETM+ data can be calibrated
;;  Modified  :  Junli LI, 2009/02/09 12:00 AM, renew the ENVI head files, and 
;;               sun azimuth and elevation angles are added to the header file,
;;               then landsat file download from GLOVIS are processed
;-
;*****************************************************************************
PRO MAIN_GLCF_Landsat_Preprocess, Landsat_DIR, ENVIFile_DIR
    
  ; Establish error handler. 
  STR_ERROR = ''
  CATCH, Error_status 
  ; This statement begins the error handler: 
  IF Error_status NE 0 THEN BEGIN 
     STR_ERROR = STRING(Error_status) + ' :' + !ERROR_STATE.MSG
     print, STR_ERROR
     CATCH, /CANCEL  
     RETURN
  ENDIF 
  
  ; ###########################################################################
  ; Temporary variables, just for testing
    Landsat_DIR  = 'I:\Kunlun\ZIP_glcf\'
    ENVIFile_DIR = 'I:\Kunlun\Landsat\'
  ; Temporary variables, just for testing  
  ; ###########################################################################
    
  ; If the parameters are not set,then return
  IF(KEYWORD_SET(Landsat_DIR) EQ 0 OR KEYWORD_SET(ENVIFile_DIR) EQ 0) THEN RETURN
  ; Whether Landsat_DIR or ENVIFile_DIR is file directory
  IF( FILE_TEST(Landsat_DIR,/DIRECTORY) EQ 0 OR $
      FILE_TEST(ENVIFile_DIR,/DIRECTORY) EQ 0 ) THEN RETURN
  
  ;**************************************************y*************************
  ;
  ; Get some environmental variables   
  ;
  ;****************************************************************************
  ;
  ; Current working DIRECTORY
  CD, CURRENT = CurrentDirectory
  ; Current Date
  JulianDay   = SYSTIME(/JULIAN)
  CALDAT, JulianDay, Month, Day, Year, Hour, Minute, Second
  StrYear     = STRING(Year,  FORMAT = '(I4)')
  StrMonth    = STRING(Month, FORMAT = '(I2.2)')
  StrDay      = STRING(Day,   FORMAT = '(I2.2)')
  StrHour     = STRING(Hour,  FORMAT = '(I2.2)')
  StrMin      = STRING(Minute,FORMAT = '(I2.2)')
  StrSec      = STRING(Second,FORMAT = '(I2.2)')
  StrDate     = StrYear + StrMonth + StrDay + StrHour + StrMin + StrSec
  logProBatchFile = CurrentDirectory + '\GLCF_ZIPtoENVI_'+ StrDate + '.txt'
  ENVI, /RESTORE_BASE_SAVE_FILES
  ENVI_BATCH_INIT, LOG_FILE = logProBatchFile
  ; Get the file handle of the logProBatchFile
  GET_LUN, PRO_LUN
  OPENW, PRO_LUN, logProBatchFile
  PRINTF,PRO_LUN, 'The Procedure Begins at   : '+STRING(SYSTIME(/UTC))
  PRINTF,PRO_LUN, 'The Landsat   DIRECTORY is: '+Landsat_DIR
  PRINTF,PRO_LUN, 'The ENVI File DIRECTORY is: '+ ENVIFile_DIR
  PRINTF,PRO_LUN, 'Abnormal information are beginning to record........'
  
  ; Restore all the base save files, then Initialize ENVI work environments
  ENVI, /RESTORE_BASE_SAVE_FILES
  ENVI_BATCH_INIT, LOG_FILE = logProcedureFileName
    
  ;****************************************************************************
  ; Find all of the Landsat gz files and convert them to ENVI files
  ;****************************************************************************
  ;
  SceneDIR=FILE_SEARCH(Landsat_DIR,COUNT=SceneCount,'P*',$
                       /TEST_READ, /TEST_DIRECTORY)
  IF(SceneCount LE 0) THEN BEGIN
     PRINT, 'There are no valid GLCF Landsat imagery to be processed.'
     FREE_LUN, PRO_LUN 
     RETURN
  ENDIF
 
  ; Loop by the scene count of landsat images
  FOR i=0,SceneCount-1 DO BEGIN
    
    str = STRTRIM(STRING(i+1),2) + ': ' + SceneDIR[i] + ' is processing'
    PRINT, str
    PRINTF,PRO_LUN,str
    
    ;***************************************************************************
    ; (1)First check each SceneDIR and get the zipped band files to be extracted
    ;  For TM/ETM+ is there are 7 bands(1~7), and for MSS is 4 bands(1~4)
    ;***************************************************************************
    bCheckStatus=GLCF_CheckZippedFileStatus(SceneDIR[i],FileCount=gzFileCount,$
                 FilePaths=gzFilePaths,MetFilePath=LandsatMetaFile,ERR_String)
    ; Write the scene abnormal information
    IF(bCheckStatus EQ 0) THEN BEGIN
       PRINTF,PRO_LUN,ERR_String
       CONTINUE
    ENDIF
    
    ;***************************************************************************
    ; (2) Perform the unzip commands to extract the .gz files
    ;***************************************************************************
    BandFiles = STRARR(gzFileCount)
    FOR j=0,gzFileCount-1 DO BEGIN
       gzFileName = gzFilePaths[j]
       UCommands  = '7z e -tgzip '+gzFileName+' -o'+SceneDIR[i]
       SPAWN, UCommands, /NOSHELL
       BandFiles[j]=STRMID(gzFileName,0,STRLEN(gzFileName)-3) 
    ENDFOR
    
    ;***************************************************************************
    ; (2) Generate the new envi file name
    ;***************************************************************************
    BandFileName = FILE_BASENAME(BandFiles[0])
    Idx1         = STRPOS(BandFileName, 'r')
    Idx2         = STRPOS(BandFileName, '_')
    sPath        = STRMID(BandFileName, 1, Idx1-1)
    sRow         = STRMID(BandFileName, Idx1+1, Idx2-Idx1-1)
    IF(Idx2-Idx1-1 EQ 2) THEN sRow = '0'+sRow
    Idx1         = Idx2+1
    Idx2         = STRPOS(BandFileName, '_',/REVERSE_SEARCH)
    IF(Idx2-Idx1 EQ 10) THEN IdxCount = 2 ELSE IdxCount = 3
    SensorID     = STRMID(BandFileName, Idx1, IdxCount)
    AcqDate      = STRMID(BandFileName, Idx1+IdxCount, 8)
    IF(SensorID EQ '1m' OR SensorID EQ '2m' OR SensorID EQ '3m' OR $
       SensorID EQ '4m' OR SensorID EQ '5m') THEN BEGIN
       SensorType= 'MSS'
       Sensor    = 'LM' + STRMID(SensorID, 0, 1)
    ENDIF
    IF(SensorID EQ '4t' OR SensorID EQ '5t') THEN BEGIN
       SensorType= 'TM'
       Sensor = 'LT' + STRMID(SensorID, 0, 1)
    ENDIF
    IF(SensorID EQ '7dk' ) THEN BEGIN
       SensorType= 'ETM'
       Sensor = 'LE7'
    ENDIF
    
    FileName     = 'P'+sPath+'R'+sRow+'_'+Sensor+'D'+AcqDate+'_GLCF.dat'
    ENVIFileName = ENVIFile_DIR + FileName
    
    ;***************************************************************************
    ; (3) Stacking the Landsat layers in the BandFiles
    ;***************************************************************************
   
    bCheckStatus = GLCF_StackBandFiles(BandFiles,gzFileCount,LandsatMetaFile,$
                                         SensorType, ENVIFileName, ERR_String)
    IF(bCheckStatus EQ 0) THEN BEGIN
      PRINT,ERR_String
      PRINTF,PRO_LUN,ERR_String
      CONTINUE
    ENDIF
    
    ; DELETE the BandFiles
    ;FOR j=0,gzFileCount-1 DO   FILE_DELETE, BandFiles[j]
    
  ENDFOR
 
  FREE_LUN, PRO_LUN

  CD, CURRENT = oldDIR
  IF (oldDIR NE ENVIFile_DIR) THEN CD, DIV_FID
  IF (CurrentDirectory NE ENVIFile_DIR) THEN CD, CurrentDirectory

END
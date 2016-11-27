
;*****************************************************************************
;; $Id: envi45_config/Program/LakeMappingTools/GLOVIS_LandsatFiles_ZIPtoENVI
;;
;; Author: Junli LI, Geography Department of UCLA, Los Angeles, CA 90095
;+
;; NAME:
;;   MAIN_GLOVIS_Landsat_PreProcess
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
;;   Main Procedure
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

PRO MAIN_GLOVIS_Landsat_PreProcess, Landsat_DIR, ENVIFile_DIR

    ; Establish error handler. 
    STR_ERROR = ''
    CATCH, Error_status 
    ; This statement begins the error handler: 
    IF Error_status NE 0 THEN BEGIN 
       STR_ERROR = STRING(Error_status) + ' :' + !ERROR_STATE.MSG
       print, STR_ERROR
       CATCH, /CANCEL 
       IF(PRO_LUN GT 0) THEN FREE_LUN, PRO_LUN 
       
       RETURN
    ENDIF 

    ; Get them from the DIALOG_PICKFILE dialog    
;    IF(N_ELEMENTS(Landsat_DIR) LE 0 OR N_ELEMENTS(ENVIFile_DIR) LE 0) THEN BEGIN
;       Landsat_DIR =DIALOG_PICKFILE(TITLE='Select the landsat directory',$
;                                   /DIRECTORY)
;      ENVIFile_DIR=DIALOG_PICKFILE(TITLE='Select the output directory',$
;                                   /DIRECTORY)
;      IF(Landsat_DIR EQ '' OR ENVIFile_DIR EQ '') THEN RETURN
;      IF(FILE_TEST(Landsat_DIR, /DIRECTORY) EQ 0 OR $
;         FILE_TEST(ENVIFile_DIR,/DIRECTORY) EQ 0) THEN RETURN
;    ENDIF
    
    Landsat_DIR = '/Volumes/D2/tm/zhongya/2000/'
    ENVIFile_DIR= '/Volumes/D2/tm_unzip/2000/'
    IF(KEYWORD_SET(Landsat_DIR) EQ 0 OR KEYWORD_SET(ENVIFile_DIR) EQ 0) THEN RETURN
    
    ;**************************************************y************************
    ;
    ;                      Get some environmental variables   
    ;
    ;***************************************************************************
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
    logProBatchFile = CurrentDirectory + '/GLOVIS_ZIPtoENVI_'+ StrDate + '.txt'
    ENVI, /RESTORE_BASE_SAVE_FILES
    ENVI_BATCH_INIT, LOG_FILE = logProBatchFile
    ; Get the file handle of the logProBatchFile
    GET_LUN, PRO_LUN
    OPENW, PRO_LUN, logProBatchFile
    PRINTF,PRO_LUN, 'Procedure begins at ' + STRING(SYSTIME(/UTC))
    PRINTF,PRO_LUN, 'The Landsat DIRECTORY to be processed is  '+Landsat_DIR
    PRINTF,PRO_LUN, 'The ENVI file DIRECTORY is  ' + ENVIFile_DIR
    PRINTF,PRO_LUN, 'Abnormal information are beginning to record........'
    ;
    ;
    ;***************************************************************************
    ;
    ; Find all of the Landsat gz files and convert them to ENVI files
    ; 
    ;***************************************************************************
    ;
    ; Find all of the Landsat file paths in the input DIRECTORY
    ZipFiles    = FILE_SEARCH(Landsat_DIR, COUNT = nFileCount, '*tar.gz', $
                           /TEST_READ, /FULLY_QUALIFY_PATH)
    IF(nFileCount LE 0) THEN BEGIN
       MESSAGE, 'There are no valid GLS landsat data to be processed.'
       RETURN
    ENDIF
    PRINT, 'GLOVIS_LandsatFiles_ZIPtoENVI begins: ' + SYSTIME(/UTC)
    FOR i=0,nFileCount-1 DO BEGIN 
        
        ;***********************************************************************
        ; {1) Decompress the *.gz files and combine the file by each
        ;***********************************************************************
        
        gzFilePath   = ZipFiles[i]
        gzFileName   = FILE_BASENAME(gzFilePath)
        gzFileName   = STRMID(gzFileName,0,STRLEN(gzFileName)-3) 
        FileName     = STRMID(gzFileName,0,STRLEN(gzFileName)-4) 
        SceneDIR     = ENVIFile_DIR+FileName+'/'
        IF(FILE_TEST(SceneDIR,/DIRECTORY) EQ 0) THEN FILE_MKDIR, SceneDIR
         UCommands   = 'tar -xzvf ' + gzFilePath + ' -C ' + SceneDIR
        ; use SPAWN to execute outer executable program- 7z.exe
        SPAWN, UCommands
        
        ;***********************************************************************
        ; {2) THEN stack the separated band files
        ;***********************************************************************
        
        ; Get the sensor ID, the first three characters of the gz filename
        ; the SensorType values: MSS/TM1990s/TM2000s/ETM
        
        SensorType   = GLOVIS_SensorType(gzFileName)
        SensorID     = GLOVIS_GetSensorIDFromFiles(gzFileName)
        ; Get the band search filters according to their naming rules
        SearchBandFileNames= GLOVIS_GetSearchBandList(gzFileName)
        ; Find each TIFF band file names for one scene 
        IF(SensorType EQ 'MSS') THEN BandCount=4 ELSE BandCount = 6
        TIFFiles = STRARR(BandCount)
        
        ;[2.1] Get the TIFF Files to be processed
        FOR j=0,BandCount-1 DO BEGIN
           TIFFile = FILE_SEARCH(SceneDIR,SearchBandFileNames[j],COUNT=nCount,$
                                 /TEST_READ, /FULLY_QUALIFY_PATH)
           IF(nCount NE 1) THEN BREAK
           TIFFiles[j] = TIFFile[0]
        ENDFOR
        ; if the Loop is break, that means not all the band files are available
        IF(j NE BandCount) THEN BEGIN
           STR_ERROR   = gzFileName + ' : Stacking Band Files Failed!'
           PRINTF,PRO_LUN, STR_ERROR
           CONTINUE
        ENDIF
        
        ;[2.2]  Genereate the ENVI file name
        FileName       = FILE_BASENAME(TIFFiles[0])
        ENVIFileName   = GLOVIS_FileNaming(FileName) 
        ENVIFileName1  = ENVIFile_DIR+ENVIFileName
        ENVIFileName   = ENVIFileName1+'.dat'
        ; [2.3] Get the MetaFiles
        LandsatMetaFile = ENVIFileName1 + '_MTL.txt'
        IF( SensorType EQ 'MSS' OR SensorID EQ 'TM1990s' ) THEN BEGIN
           MetaFile    = FILE_SEARCH(SceneDIR,'*_WO.txt', COUNT=nCount, $
                                    /TEST_READ, /FULLY_QUALIFY_PATH)
           LandsatMetaFile = ENVIFileName1 + '_WO.txt'
        ENDIF
        IF( SensorType EQ 'ETM' OR SensorID EQ 'TM2000s' ) THEN BEGIN
           MetaFile    = FILE_SEARCH(SceneDIR,'*_MTL.txt', COUNT=nCount,$
                                    /TEST_READ, /FULLY_QUALIFY_PATH)
           LandsatMetaFile = ENVIFileName1 + '_MTL.txt'
        ENDIF
        IF(nCount GT 0) THEN FILE_MOVE,MetaFile[0],LandsatMetaFile $
        ELSE LandsatMetaFile=''
      
        ; [2.4] Stacking the Landsat layers in the SceneDirectory[i]
        bCheckStatus=GLOVIS_StackBandFiles(TIFFiles,BandCount,LandsatMetaFile,$
                                           SensorID, ENVIFileName, ERR_String)
        IF (bCheckStatus EQ 0) THEN BEGIN
           PRINTF,PRO_LUN, '                                               '
           PRO_ABMORBAL_STR = ERR_String
           PRINTF,PRO_LUN,PRO_ABMORBAL_STR
           CONTINUE
        ENDIF
        
        ; [2.5] Delete the SceneDIR
        Files = FILE_SEARCH(SceneDIR, COUNT = nCount, '*.*',/TEST_READ, $
                            /FULLY_QUALIFY_PATH)
        ;Delete the files in sub DIRECTORY SceneDIR
        FOR j=0,nCount-1 DO FILE_DELETE, Files[j]
        ; delete the subdirectory file folder
        FILE_DELETE, SceneDIR
    
    ENDFOR
    
    FREE_LUN, PRO_LUN  
    
    PRINT, 'GLOVIS_LandsatFiles_ZIPtoENVI ends: ' + SYSTIME(/UTC)
    
END
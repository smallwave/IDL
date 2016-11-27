;******************************************************************************
;; $Id: envi45_config/Program/LakeMappingTools/GLCF_CheckZippedFileStatus
;;
;; Author: Junli LI, Geography Department of UCLA, Los Angeles, CA 90095
;+
;; NAME:
;;   GLCF_CheckZippedFileStatus
;;
;; PURPOSE:
;;   The function checks whether the zipped files in given directory are $
;;   avaialbe,and get the file path of the *.gz file.
;;
;; PARAMETERS:
;;   SceneDirectory(In)- the landsat single scene directory.
;;
;;   gzFileCount(Out)  - GZ file count in the give directory.
;;
;;   gzFilePaths(Out)  - GZ file paths in the give directory.
;;
;;   ERR_String        - Record error information if errors happen
;;
;; KEYWORDS:
;;   FileCount         - GZ file count in the give directory.
;;
;;   FilePaths         - GZ file paths in the give directory.
;;
;; OUTPUTS:
;;   If the *.gz files in the give directory is avaiable, then return 1, else $
;;   return 0
;;
;; MODIFICATION HISTORY:
;;   Written by:  Junli LI, 2008/02/15 06:00 PM
;;   Modified  :  Junli LI, 2008/04/01 12:00 AM
;-
;******************************************************************************
;
Function GLCF_CheckZippedFileStatus, SceneDirectory, FileCount = gzFileCount, $
              FilePaths = gzFilePaths, MetFilePath = LandsatMetFile, ERR_String

  ;****************************************************************************
  ;
  ; Step 1: Get the type of landsat data which are stored in SceneDirectory
  ;
  ;****************************************************************************
  ;
  SensorType   = GLCF_SensorType(SceneDirectory)
  CASE SensorType OF
      'MSS' : nCount = 4
      'TM'  : nCount = 6
      'ETM' : nCount = 6
  ELSE      : nCount = 6
  ENDCASE
    
  ;****************************************************************************
  ;
  ; Step 2: Find the gz files of Landsat_Directory
  ;
  ;****************************************************************************
  ;
  ; Set the SceneDirectory as current working directory
  CD, current  = CurrentDirectory
  IF(NOT STRCMP(CurrentDirectory,SceneDirectory)) THEN CD, SceneDirectory
  gzFilePaths  = STRARR(nCount)

  ; Loop the SceneDirectory to find the gz files
  ERR_String = ''
  FOR i=0,nCount-1 DO BEGIN
    ; Generate the gz file name by the GLCF name rule
    nindex = i+1
    IF(i EQ 5) THEN nindex = i+2
    sIDX  = STRTRIM(String(nindex),2)
    CASE SensorType OF
      'MSS': gzBandFileString='*_0'+sIDX+String('.tif.gz')
      'TM' : gzBandFileString=String('*_nn')+sIDX+String('.tif.gz')
      'ETM': gzBandFileString=String('*_nn')+sIDX+String('0.tif.gz')
    ENDCASE
    ; Find whether the band file is existing
    gzBandFileName = FILE_SEARCH( gzBandFileString, /FULLY_QUALIFY_PATH )
    ; If the band file does not exist, then return
    IF(gzBandFileName EQ '') THEN BEGIN
      ERR_String = SceneDirectory+' : Band'+STRTRIM(String(i+1))+' is missed'
      RETURN, 0
    ENDIF
    gzFilePaths[i] = gzBandFileName[0]
  ENDFOR
  
  ; Find whether the met file is existing
  LandsatMetFile = FILE_SEARCH( '*.hdr', /FULLY_QUALIFY_PATH )
  LandsatMetFile = LandsatMetFile[0]
  ; If the band file does not exist, then return
  IF(LandsatMetFile EQ '') THEN BEGIN
     ERR_String  = SceneDirectory + ' : lack of meta file'
     RETURN, 0
  ENDIF
  IF(SensorType EQ 'ETM') THEN BEGIN
     LandsatMetFile = STRMID(LandsatMetFile, 0, STRLEN(LandsatMetFile)-4)+'.met'
  ENDIF
  
  gzFileCount = nCount
  IF(NOT STRCMP(CurrentDirectory,SceneDirectory)) THEN  CD, CurrentDirectory
  RETURN, 1

END
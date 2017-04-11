;+
; ;**********************************************************
; Email: wavelet2008@163.com
;
; NAME:
;    D:\workspace\Tech\Code\IDL\DataPreprocessing\Mian_RepairModisLSTByMutilyearData.pro
; PARAMETERS:
;
; Some Path
; Write by :
;    2017-4-11 14:02:53
;;MODIFICATION HISTORY:
;;   Modified and updated  :
;    2017-4-11 17:06:53   search problem
;

PRO MIAN_REPAIRMODISLSTBYMUTILYEARDATA

  COMPILE_OPT idl2
  ;Resore Envi
  ENVI, /RESTORE_BASE_SAVE_FILES
  ENVI_BATCH_INIT, LOG_FILE = logProBatchFile

  ; Define the coefficient array :
  DataPath           =  "D:\Test\"
  OutFilePath        =  "D:\Out\"
  searchYears        =  [2003,2004,2005,2006,2007,2008,2009,2010]
  numberDays         =  3


  ;Check file path
  IF(KEYWORD_SET(DataPath) EQ 0 OR KEYWORD_SET(OutFilePath) EQ 0) THEN RETURN

  ; Define log file to record the error such as incomplete data
  logProBatchFile = OutFilePath + 'logFile.txt'
  ; Get the file handle of the logProBatchFile
  GET_LUN, PRO_LUN
  OPENW, PRO_LUN, logProBatchFile
  PRINTF,PRO_LUN, 'Abnormal information are beginning to record........'

  FOR day = 1, numberDays  DO BEGIN
    startFileTime    = SYSTIME(1)
    strDay           = STRING(Day,FORMAT = '(i3.3)')
    ;step1  search file and get file data
    strSeachDateTime    =  STRARR(4,8)
    ; get string year match
    FOR year = 0, N_ELEMENTS(searchYears) -1 DO BEGIN
      strSeachDateTime[0,year] =  "MOD11A1_" + STRING(searchYears[year],FORMAT = '(i4.4)')+strDay+ "*Day*.tif"
      strSeachDateTime[1,year] =  "MOD11A1_" + STRING(searchYears[year],FORMAT = '(i4.4)')+strDay+ "*Night*.tif"
      strSeachDateTime[2,year] =  "MYD11A1_" + STRING(searchYears[year],FORMAT = '(i4.4)')+strDay+ "*Day*.tif"
      strSeachDateTime[3,year] =  "MYD11A1_" + STRING(searchYears[year],FORMAT = '(i4.4)')+strDay+ "*Night*.tif"
    ENDFOR
    ; search file
    searchFiles = []
    FOR nType = 0, 3 DO BEGIN
      FOR year = 0, N_ELEMENTS(searchYears) -1 DO BEGIN
        searchMatch         =  strSeachDateTime[nType,year]
        searchSingleFiles   =  FILE_SEARCH(DataPath, searchMatch,count=numfiles)
        IF(numfiles EQ 0) THEN RETURN
        searchFiles = [searchFiles,searchSingleFiles]
      ENDFOR
      numfiles      =  N_ELEMENTS(searchFiles)
      IF(nType EQ 0) THEN BEGIN
         strInfo = "MOD11A1_Day " + strDay
      ENDIF ELSE IF (nType EQ 1)  THEN  BEGIN
         strInfo = "MOD11A1_Night "+ strDay
      ENDIF ELSE IF (nType EQ 2)  THEN  BEGIN
         strInfo = "MYD11A1_Day "+ strDay
      ENDIF  ELSE  BEGIN
         strInfo = "MYD11A1_Night "+ strDay
      ENDELSE
      ; process data
      IF(numfiles EQ 0) THEN BEGIN
        STR_INFO = strInfo  + ' : have 0 files!'
        PRINTF,PRO_LUN,STR_INFO
        CONTINUE
      ENDIF
      strFileNames      =  STRARR(numfiles)
      IF(numfiles NE 8) THEN BEGIN
        STR_INFO = strInfo  + ' : have not number 8 files!'
        PRINTF,PRO_LUN,STR_INFO
      ENDIF
      STR_INFO  =  'Current being processed using search ' + strInfo
      PRINT, STR_INFO

      ;step2  open the file
      FOR n = 0, numfiles-1  DO BEGIN
        filename        =  searchFiles[n]
        ENVI_OPEN_FILE, filename, R_FID = fid
        strFileNames[n] = FILE_BASENAME(filename)
        IF fid EQ -1 THEN  RETURN
        IF(n EQ 0) THEN BEGIN
          ENVI_FILE_QUERY, fid, DATA_TYPE=DATA_TYPE, NL=NL, NS=NS,dims=dims,NB=NB,OFFSET=offset,INTERLEAVE=interleave
          map_info        = ENVI_GET_MAP_INFO(fid = fid)
          tempData        = MAKE_ARRAY(NS,NL,numfiles,/UINT)
          sumData         = MAKE_ARRAY(NS,NL,/ULONG)
          numData         = MAKE_ARRAY(NS,NL,/BYTE)
        ENDIF
        temp              = ENVI_GET_DATA(FID = fid,DIMS = dims,pos = 0)
        tempData[*,*,n]   = temp
        sumData           = sumData + temp
        ;calculate the number of ne o value
        numData           = numData + (temp NE 0.0)
      ENDFOR

      ;step3  calculate mean value using multi-year
      numData[WHERE(numData EQ 0.0)] = 1.0
      meanData            = sumData/numData

      FOR n = 0, numfiles-1  DO BEGIN
        ;step4  replace file
        outData  =  tempData[*,*,n]
        outData[WHERE(outData EQ 0.0)] = meanData[WHERE(outData EQ 0.0)]

        ;step5  output file
        OutFile  =  OutFilePath +  strFileNames[n]
        OPENW, HData, OutFile, /GET_LUN
        WRITEU, HData,outData
        FREE_LUN, HData

        ; Edit the envi header file
        ENVI_SETUP_HEAD, FNAME=OutFile,NS=ns,NL=nl,NB=1,INTERLEAVE=interleave,$
          DATA_TYPE=DATA_TYPE,OFFSET=offset,MAP_INFO=map_info,/WRITE,$
          /OPEN,R_FID=Data_FID
      ENDFOR
      ; remove all the FIDs in the file lists
      FIDS = ENVI_GET_FILE_IDS()
      FOR i = 0, N_ELEMENTS(FIDS) - 1 DO BEGIN
        IF(FIDS[i] NE -1) THEN  ENVI_FILE_MNG, ID = FIDS[i], /REMOVE
      ENDFOR

    ENDFOR
    ;print file time consume
    endFileTime = SYSTIME(1)
    STR_INFO  =  'Time consumption at ' + strDay  + ' file is' + STRING(endFileTime-startFileTime)
    PRINT, STR_INFO

  ENDFOR
  FREE_LUN, PRO_LUN

  PRINT, 'Procedure ends at ' + STRING(SYSTIME(/UTC))

END
;+
; ;**********************************************************
; Email: wavelet2008@163.com
;
; NAME:
;    D:\workspace\Tech\Code\IDL\DataPreprocessing\Main_ModisLST2DailyLST.pro
; PARAMETERS:
;    See Zhao et al(2014)
;
; Some Path
; Write by :
;    2017-3-29 13:25:53
;;MODIFICATION HISTORY:
;;   Modified and updated  :
;    2017-4-4
;    2017-4-6
;+--------------------------------------------------------------------------
;| PUB_AcqDate2DOY
;+--------------------------------------------------------------------------
FUNCTION DATE_TO_DOY, sAcqDate

  ; get the year moth day from the string sAcqDate
  nYear     = LONG(STRMID(sAcqDate,0,4))
  nMonth    = LONG(STRMID(sAcqDate,4,2))
  nDay      = LONG(STRMID(sAcqDate,6,2))
  ; calculate the DOY
  nDOY      = JULDAY(nMonth,nDay,nYear)-JULDAY(1,0,nYear)
  RETURN, nDOY
END

;+--------------------------------------------------------------------------
;| Main
;+--------------------------------------------------------------------------
PRO MAIN_MODISLST2DAILYLST

  COMPILE_OPT idl2
  ;Resore Envi
  ENVI, /RESTORE_BASE_SAVE_FILES
  ENVI_BATCH_INIT, LOG_FILE = logProBatchFile
  
  ; Define the coefficient array :
  StartDate          = JULDAY(1,1,2005)
  EndDate            = JULDAY(1,2,2005)
  DataPath           =  "D:\Test\"
  OutFilePath        =  "D:\Out\"

  ; Define other common var :
  Tmax  = 13.0
  Shift = 1.35
  modDayTime         =  10.5
  mydDayTime         =  13.5
  modNightTime       =  22.5
  mydNightTime       =  1.5
  
  ;Check file path
  IF(KEYWORD_SET(DataPath) EQ 0 OR KEYWORD_SET(OutFilePath) EQ 0) THEN RETURN

  ; Define log file to record the error such as incomplete data
  logProBatchFile = OutFilePath + 'logFile.txt'
  ; Get the file handle of the logProBatchFile
  GET_LUN, PRO_LUN
  OPENW, PRO_LUN, logProBatchFile
  PRINTF,PRO_LUN, 'Abnormal information are beginning to record........'
  ;+--------------------------------------------------------------------------
  ;| begin
  ;+--------------------------------------------------------------------------
  ;Select Datas
  ProcessDates       =  TIMEGEN(START=StartDate, FINAL=EndDate,unit="D")
  szDates            =  SIZE(ProcessDates,/N_ELEMENTS)
  FOR m =0, szDates -1 DO BEGIN
    CALDAT,ProcessDates[m],Month, Day, Year
    strDate          =     STRING(Year,FORMAT = '(i4)')      $
      + STRING(Month,FORMAT = '(i2.2)')   $
      + STRING(Day,FORMAT = '(i2.2)')
    nDOY             = DATE_TO_DOY(strDate)
    ;+--------------------------------------------------------------------------
    ;| 01  search file and get file data
    ;+--------------------------------------------------------------------------
    strData = STRING(Year,FORMAT = '(i4)') + STRING(nDOY,FORMAT = '(i3.3)')
    strSeachDateTime = '*' + strData + '*LST*.tif'
    theseFiles=FILE_SEARCH(DataPath, strSeachDateTime,count=numfiles)
    IF(numfiles NE 4) THEN BEGIN
      STR_INFO = strData + ' : have not number 4 files!'
      PRINTF,PRO_LUN,STR_INFO
      CONTINUE
    ENDIF ELSE BEGIN
      STR_INFO  =  'Current being processed at ' + strData  + ' file'
      PRINT, STR_INFO
    ENDELSE
    startFileTime = SYSTIME(1)
    IF (numfiles EQ 4) THEN BEGIN
      FOR n = 0, numfiles-1  DO BEGIN
        filename=theseFiles[n]
        ENVI_OPEN_FILE, filename, R_FID = fid
        IF fid EQ -1 THEN  RETURN
        IF(n EQ 0) THEN BEGIN
          FileNameOut     = FILE_BASENAME(filename)
          FileNameOut     = STRMID(FileNameOut, 0, (STRLEN(FileNameOut)-4))
          ENVI_FILE_QUERY, fid, DATA_TYPE=DATA_TYPE, NL=NL, NS=NS,dims=dims,NB=NB,OFFSET=offset,INTERLEAVE=interleave
          map_info = ENVI_GET_MAP_INFO(fid = fid)
          tempData        =   MAKE_ARRAY(NS,NL,numfiles,/float)
        ENDIF
        tempData[*,*,n] =   ENVI_GET_DATA(FID = fid,DIMS = dims,pos = 0)
      ENDFOR
      startLon         =  map_info.MC[3]
      mapResonlution   =  map_info.PS[0]
      outTemp   =   MAKE_ARRAY(NS,NL,/float)
      ;1  step  caclution declination
      dec = 23.45*SIN(360.0/180.0*!DPI*(284.0+Day)/365.0)
      ;+--------------------------------------------------------------------------
      ;| 02  process file
      ;+--------------------------------------------------------------------------
      FOR i=0,nl-1 DO BEGIN
        ;2  step  caclution the latitule
        ymap  = startLon - i*mapResonlution
        ;3  step  w and t1 t2 t0
        trise = ACOS(TAN(ymap/180.0*!DPI)*TAN(dec/180.0*!DPI))*180.0/!DPI/15.0
        ;Tmax=13.00
        ;shift=1.35
        t1    = trise+Shift
        t2    = 24-t1
        w     = !DPI/(Tmax-t1)
        t0    = (t1+13.00)/2
        ;+--------------------------------------------------------------------------
        ;| 03  process file rows
        ;+--------------------------------------------------------------------------
        FOR j=0,ns-1 DO BEGIN
          temp          =  tempData[j,i,*]*0.02
          ; using the method1
          ;          IF (temp[2] NE 0.0 AND temp[3] NE 0.0 ) THEN BEGIN
          ;            outTemp[j,i]  =  (temp[2] + temp[3])/2.0
          ;          ENDIF
          ; using 3 methods
          index = N_ELEMENTS(WHERE(temp NE 0.0))
          IF(index NE 4) THEN BEGIN
            CONTINUE
          ENDIF
          ;
          a1 = [[SIN(w*(modDayTime-t0)), 1], $
            [SIN(w*(mydDayTime-t0)), 1]]
          ; Define the right-hand side vector b:
          b1 = [temp[0], temp[2]]
          ; Compute and print the solution to ax=b:
          x1 = LA_LINEAR_EQUATION(a1, b1)

          a2 = [[modNightTime, 1], $
            [mydNightTime, 1]]
          ; Define the right-hand side vector b:
          b2 = [temp[1], temp[3]]
          ; Compute and print the solution to ax=b:
          x2 = LA_LINEAR_EQUATION(a2, b2)

          sumLst =0
          FOR t = 0,23 DO BEGIN
            IF (t GE t1 AND t LE t2) THEN BEGIN
              lstday =  SIN(w*(t-t0))*x1[0]+ x1[1]
              sumLst = sumLst+lstday
            ENDIF ELSE BEGIN
              lstnight = t*x2[0]+ x2[1]
              sumLst = sumLst+lstnight
            ENDELSE
          ENDFOR
          outTemp[j,i] = sumLst/24.0
          
        ENDFOR
      ENDFOR
    ENDIF
    ;+--------------------------------------------------------------------------
    ;| 04  output file
    ;+--------------------------------------------------------------------------
    ;3.2   Monthly file names
    OutFile  =  OutFilePath +  FileNameOut + ".tif"
    OPENW, HData, OutFile, /GET_LUN
    WRITEU, HData,outTemp
    FREE_LUN, HData

    ; Edit the envi header file
    ENVI_SETUP_HEAD, FNAME=OutFile,NS=ns,NL=nl,NB=1,INTERLEAVE=interleave,$
      DATA_TYPE=4,OFFSET=offset,MAP_INFO=map_info,/WRITE,$
      /OPEN,R_FID=Data_FID

    ; remove all the FIDs in the file lists
    FIDS = ENVI_GET_FILE_IDS()
    FOR i = 0, N_ELEMENTS(FIDS) - 1 DO BEGIN
      IF(FIDS[i] NE -1) THEN  ENVI_FILE_MNG, ID = FIDS[i], /REMOVE
    ENDFOR
  
    ;print file time consume
    endFileTime = SYSTIME(1)
    STR_INFO  =  'Time consumption at ' + strData  + ' file is' + STRING(endFileTime-startFileTime)
    PRINT, STR_INFO
  ENDFOR
  FREE_LUN, PRO_LUN
  PRINT, 'Procedure ends at ' + STRING(SYSTIME(/UTC))

END
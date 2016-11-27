
PRO Main_SeasonalAverageFromMonthlyData

   ; ########################################################################
   ; Temporary variables, just for test
   ; DIRECTORY where the original files are
   PrecipMonthly_DIR  = 'H:\Precipitation_025deg_MonsoonAsia\Monthly\'
   MonthlyAverage_DIR = 'H:\Precipitation_025deg_MonsoonAsia\Winter\'
   nYears             = [1961,1962,1963,1964,1965,1966,1967,1968,1969,1970,$
                         1971,1972,1973,1974,1975,1976,1977,1978,1979,1980,$
                         1981,1982,1983,1984,1985,1986,1987,1988,1989,1990,$
                         1991,1992,1993,1994,1995,1996,1997,1998,1999,2000,$
                         2001,2002,2003,2004]
   sMonths            = ['10','11','12']
   sFileName          = 'APHRO_MA_025deg_V0902'
   sSeason            = 'Winter'
   ; Temporary variables, just for test
   ; ########################################################################
   
   ;**************************************************************************
   ; Establish error handler. When errors occur, the index of the error is
   ; returned in the variable Error_status: 
   ;**************************************************************************
   ; Establish error handler. 
   STR_ERROR = ''
   CATCH, Error_status 
   ; This statement begins the error handler: 
   IF Error_status NE 0 THEN BEGIN 
      STR_ERROR = STRING(Error_status) + ' :' + !ERROR_STATE.MSG
      PRINT, STR_ERROR
      CATCH, /CANCEL 
      RETURN
   ENDIF 
    
   ; Get them from the DIALOG_PICKFILE dialog    
   IF(N_ELEMENTS(PrecipMonthly_DIR) LE 0) THEN RETURN
   
   ; not valid filepaths
   IF(FILE_TEST(PrecipMonthly_DIR, /DIRECTORY) EQ 0) THEN RETURN
       
   ; Initialize ENVI and store all errors and warnings
   ENVI, /RESTORE_BASE_SAVE_FILES
   ENVI_BATCH_INIT, LOG_FILE = logProcedureFileName
   
   ; Get the file count from the input dir
   PrecipFiles = FILE_SEARCH(PrecipMonthly_DIR, COUNT = nFileCount, '*.dat', $
                             /TEST_READ, /FULLY_QUALIFY_PATH)
   IF(nFileCount LE 0) THEN BEGIN
       MESSAGE, 'There are no valid Precip data to be processed.'
       RETURN
   ENDIF
    
   ;**************************************************************************
   ;
   ; 2) Get the files to be processed
   ;
   ;**************************************************************************
   ; 
   PRINT, 'Meteo data processing begins: ' + SYSTIME(/UTC)
   nYearCount  = SIZE(nYears, /DIMENSION)
   nYearCount  = nYearCount[0]
   nMonthCount = SIZE(sMonths,/DIMENSION)
   nMonthCount = nMonthCount[0]
   ;
   FOR i=0L,nYearCount[0]-1 DO BEGIN 
       
       ;**********************************************************************
       ; (1) Get one precipatation file and its basic info
       ;**********************************************************************
       
       sYear      = STRTRIM(STRING(nYears[i]),2)
       sYearFile  = sFileName + '_' + sYear

       ; Get the First File
       PrecipFile     = PrecipMonthly_DIR +sYearFile+sMonths[0] +'.dat'
       MonthlyAveFile = MonthlyAverage_DIR+sYearFile+'_'+sSeason+'.dat'
       
       PRINT, STRTRIM(STRING(i+1),2)+': '+PrecipFile+' is being processed'
       ; Test the existance of the PrecipFile
       IF(FILE_TEST(PrecipFile,/READ) EQ 0) THEN GOTO, NEXT_LOOP
       ENVI_OPEN_FILE,  PrecipFile, R_FID=Precip_FID
       ENVI_FILE_QUERY, Precip_FID, NB=NB, NS=NS,NL=NL,DIMS=DIMS
       iMap  = ENVI_GET_MAP_INFO(FID=Precip_FID)
       nBand      = ENVI_GET_DATA(FID=Precip_FID,DIMS=DIMS, POS=[0])
       ENVI_FILE_MNG, ID=Precip_FID, /REMOVE
       ; Loop Procedure
       ;**********************************************************************
       ; (2) Loop Procedure to calculate the average seasonal precipation
       ;**********************************************************************
       PrecipAve  = nBand
       FOR j=1,nMonthCount-1 DO BEGIN
           PrecipFile = PrecipMonthly_DIR+sYearFile+sMonths[j]+'.dat'
           IF(FILE_TEST(PrecipFile,/READ) EQ 0) THEN GOTO, NEXT_LOOP
           ENVI_OPEN_FILE,  PrecipFile, R_FID = Precip_FID
           ENVI_FILE_QUERY, Precip_FID, NB=NB, NS=NS1,NL=NL1,DIMS=DIMS
           nBand     = ENVI_GET_DATA(FID=Precip_FID,DIMS=DIMS, POS=[0])
           ENVI_FILE_MNG, ID=Precip_FID, /REMOVE 
           IF(NS NE NS1 OR NL NE NL1) THEN GOTO, NEXT_LOOP
           PrecipAve = CombinePrecipData(PrecipAve,nBand)
       ENDFOR
       
       idx   = WHERE(PrecipAve GE 0, nCount)
       IF(nCount GT 0) THEN PrecipAve[idx] = PrecipAve[idx]/nMonthCount
       
       ;*********************************************************************
       ; (5) Save the daily data to ENVI standard file
       ;*********************************************************************
       OPENW, hData,MonthlyAveFile, /GET_LUN  
       WRITEU, hData,PrecipAve
       FREE_LUN, hData 
       ; Edit the envi header file
       ENVI_SETUP_HEAD, FNAME=MonthlyAveFile,NS=NS,NL=NL,NB=1,INTERLEAVE=0,$  
           DATA_TYPE=4,OFFSET=0,MAP_INFO=iMap,BNAMES=['SeasonalPrecip'],/WRITE,$
           /OPEN,R_FID=Data1_FID
       ENVI_FILE_MNG, ID=Data1_FID, /REMOVE
       
    NEXT_LOOP:
       Print, 'Next Year: '
         
   ENDFOR

END
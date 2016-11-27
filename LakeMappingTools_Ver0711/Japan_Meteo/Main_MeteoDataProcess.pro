;******************************************************************************
;;
;; $Id: envi45_config/Program/LakeMappingTools/Main_MeteoDataProcess.pro $
;;
;; Author: Junli LI, Geography Department of UCLA, Los Angeles, CA 90095
;+
;; NAME:
;;   Main_MeteoDataProcess
;;
;; PURPOSE:
;;  Convert original daily precipiataion data to envi raster file which is 
;;  produced by  Research Institute for Humanity and Nature & Meteorological
;;  Research Institute of Japan Meteorological Agency
;;  
;; Production introduction
;; (1) The Products
;;     The product we release is 0.5x0.5 and 0.25x0.25 degree gridded data over 
;;   Monsoon Asia (APHRO_MA_V0902). 
;;     The gridded fields of daily precipitation are defined by interpolating
;;   rain-gauge observations obtained from meteorological and hydrological and
;;   stations over the region.  We used new daily precipitation climatology 
;;   interpolated the ratio of the daily precipitation to climatology in 0.05
;;   degree grid resolution, then multiply each gridded ratio by each gridded
;;   climatology value day by day.  After that, we re-grid the 0.05 degree 
;;   analysis to both 0.5 degree and 0.25 degree grids.  
;;     A new indicator is introduced to represent the reliability of interpolated
;;   data. Each re-gridded 0.50(0.25) degree grid box consists of 100(25) grid
;;   boxes of 0.05 degree. So we calculate the ratio of 0.05 degree grid(s)
;;   containing station(s)[RSTN], which represents the reliability of the daily
;;   precipitation fields.
;; 
;; (2) Spatial Coverage
;;     Coverage   :  60.0E - 150.0E;  0.0N - 55.0N
;;     Resolution :  0.5 degree and 0.25 degree latitude/longitude
;;
;; (3) Time
;;     Coverage   :  January 1, 1961 - December 31, 2004
;;
;; (4) Units
;;     Precipitation :  mm/day
;;     Ratio of 0.05 grid box contatining station(s) :  %
;; (5) Missing Code
;;     Precipitation :  -99.9
;;     Ratio of 0.05 grid box contatining station(s) :  -99.9
;; (6) Structure of Data files
;;     Every file contains daily fields for 365 (366 for leap years) days. These
;;     daily fields are arranged according to Julian calendar.  
;;     Daily fields (data arrays) hold information on precipitation and rain gauge
;;     station. The array for the precipitation amounts comes first, followed by
;;     that the ratio of 0.05 degree grid box containing rain gauge. In case of 
;;     0.50 degree grid file, each field consists of a data array of
;;     180 (in longitudes) x 110 (in latitudes) elements. The first element is
;;     for a grid box at the southwest corner centered at [60.25E, 0.25N],  the 
;;     second at [60.75E, 0.25N], ..., the 180th at [149.75E, 0.25N]
;;
;;     The data files are written in PLAIN DIRECT ACCESS BINARY. Each element
;;     (both precipitation and rain gauge information) is written in 4-byte 
;;     floating real number in 'LITTLE_ENDIAN' byte order. You need to swap the
;;     byte order to big_endian if you are working with a workstation other than
;;     a linux machine.  There is no 'space', 'end of record', or 'end of file'
;;     marks in between. The size of a file (0.5-degree grid) is: 
;;     4 byte x 180 x 110 x 2 fields x 365 days =57,816,000 bytes for a non-leap
;;     year, and 57,974,400 bytes for a leap year.
;;
;; PARAMETERS:
;;
;;
;; MODIFICATION HISTORY:
;;   Written by:  Junli LI, 2009/06/15 11:40 PM
;-
;******************************************************************************

PRO Main_MeteoDataProcess

   ; ########################################################################
   ; Temporary variables, just for test
   ; DIRECTORY where the original files are
   Meteo_DIR          = 'D:\MoonsoonAsia_PrecipiataionData_Japan\APHRODITE\Russia\'
   
   ; Daily files, Monthly files, Yearly files 
   PrecipDaily_DIR    = 'D:\MoonsoonAsia_PrecipiataionData_Japan\APHRODITE\Daily\'
   PrecipMonthly_DIR  = 'D:\MoonsoonAsia_PrecipiataionData_Japan\APHRODITE\Monthly\'
   PrecipYearly_DIR   = 'D:\MoonsoonAsia_PrecipiataionData_Japan\APHRODITE\Yearly\'
   
   ; Here we just test as gridsize = 0.25deg, if the Gridsize = 0.5deg, then use the parameters below
   ; GridSize  = 0.25: nx=360 ny=220 StartX=60.125 StartY=54.875
   ; GridSize  = 0.25: nx=180 ny=110 StartX=60.250 StartY=54.750 
   
   GridSize           = 0.25   ; 0.5
   nx                 = 720L   ; 180L
   ny                 = 200L   ; 110L
   ; start point
   StartX             = 15.125 ; 60.250  
   StartY             = 83.875 ; 54.750 
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
   IF(N_ELEMENTS(Meteo_DIR) LE 0 OR N_ELEMENTS(PrecipDaily_DIR) LE 0 OR $
      N_ELEMENTS(PrecipMonthly_DIR) LE 0 OR N_ELEMENTS(PrecipYearly_DIR) LE 0) $
   THEN RETURN
   
   ; not valid filepaths
   IF( FILE_TEST(Meteo_DIR, /DIRECTORY) EQ 0 OR $
       FILE_TEST(PrecipDaily_DIR,/DIRECTORY) EQ 0 OR $
       FILE_TEST(PrecipMonthly_DIR,/DIRECTORY) EQ 0 OR $
       FILE_TEST(PrecipYearly_DIR,/DIRECTORY) EQ 0) $
   THEN RETURN
       
   ; Initialize ENVI and store all errors and warnings
   ENVI, /RESTORE_BASE_SAVE_FILES
   ENVI_BATCH_INIT, LOG_FILE = logProcedureFileName
   
   ;**************************************************************************
   ;
   ; 1) Initialize the Common variables
   ;
   ;**************************************************************************
  
   NonLeapMonth=[30,58,89,119,150,180,211,242,272,303,333,364] 
   LeapMonth   =[30,59,90,120,151,181,212,243,273,304,334,365]
   ; prepare for the envi file header, 0.25deg and 0.5deg are different
   ; Projection
   iProj = ENVI_PROJ_CREATE(/GEOGRAPHIC)
   ; Create the map information  
   ps    = [GridSize, GridSize]
   mc    = [0.25D, 0.25D, StartX, StartY]
   Datum = 'WGS-84'
   Units = ENVI_TRANSLATE_PROJECTION_UNITS ('Degrees') 
   iMap  = ENVI_MAP_INFO_CREATE(/GEOGRAPHIC,MC=MC,PS=PS,PROJ=iProj,UNITS=Units)
  
   ; Get the file count from the input dir
   MeteoFiles = FILE_SEARCH(Meteo_DIR, COUNT = nFileCount, '*.*', $
                           /TEST_READ, /FULLY_QUALIFY_PATH)
    IF(nFileCount LE 0) THEN BEGIN
       MESSAGE, 'There are no valid meteo data to be processed.'
       RETURN
    ENDIF
    
   ;**************************************************************************
   ;
   ; 2) Get the files to be processed
   ;
   ;**************************************************************************
    
    PRINT, 'Meteo data processing begins: ' + SYSTIME(/UTC)
    
    nDataMonth = FLTARR(nx,ny)
    nDataYear  = FLTARR(nx,ny)
    FOR i=0L,nFileCount-1 DO BEGIN 
        
        ;***********************************************************************
        ; (1) Get one original precipatation file 
        ;***********************************************************************
        MeteoFile     = MeteoFiles[i]
        MeteoFileName = FILE_BASENAME(MeteoFile)
        sYear         = STRMID(MeteoFileName,STRLEN(MeteoFileName)-4,4)
        nYear         = UINT(sYear)
        NewFile       = STRMID(MeteoFileName,0,STRLEN(MeteoFileName)-5)+'_'+sYear
        IF(nYear MOD 4 EQ 0) THEN nDays = 366 ELSE nDays = 365
        IF(nYear MOD 4 EQ 0) THEN nMonths = LeapMonth ELSE nMonths = NonLeapMonth
        
        PRINT, STRTRIM(STRING(i+1),2)+': '+MeteoFileName+' is being processed'
        
        ;***********************************************************************
        ; (2) Generate the output daily(monthly,yearly) file names
        ;***********************************************************************
        
        ; Daily file names
        sPrecipDailyFiles   = STRARR(nDays)
        sRationDailyFiles   = STRARR(nDays)
        FOR j=0,nDays-1 DO BEGIN
           sDays      = STRTRIM(STRING(j+1),2)
           if(j+1 LT 10) THEN sDays = '00'+sDays
           if(j+1 GE 10 AND j+1 LT 100) THEN sDays = '0'+sDays
           sPrecipDailyFiles[j]  = PrecipDaily_DIR+NewFile+sDays+'_Rain'
           sRationDailyFiles[j] = PrecipDaily_DIR+NewFile+sDays+'_Samp'
        ENDFOR
        
        ; Monthly file names
        sPrecipMonthlyFiles   = STRARR(12)
        FOR j=0,11 DO BEGIN
           sMonths    = STRTRIM(STRING(j+1),2)
           if(j+1 LT 10) THEN sMonths = '0'+sMonths
           sPrecipMonthlyFiles[j]  = PrecipMonthly_DIR+NewFile+sMonths
        ENDFOR
        
        ; Yearly file names
        sPrecipYearlyFile = PrecipYearly_DIR+NewFile+'.dat'
        
       ; Read the meteo data and save as ENVI files
       OPENR, hMeteo, MeteoFile, /GET_LUN
       
       ;***********************************************************************
       ; (3) Loop procedure to get daily precipitation data from original file
       ;***********************************************************************
       k = 0
       nDataMonth[*,*] = 0.0
       nDataYear[*,*]  = 0.0
       FOR j=0L,nDays-1 DO BEGIN
         
         ;*********************************************************************
         ; (4) Get the daily data
         ;*********************************************************************
         ; calculate the start position to read the file
         iStart = LONG(j*8L*nx*ny) 
         ; Precipitation daily data
         data1  = READ_BINARY(hMeteo,DATA_DIMS=[nx,ny],DATA_START=iStart,$
                           DATA_TYPE=4,ENDIAN='little')
         ; reverse the data to fit the expression of IDL image varialbles
         data1  = REVERSE(data1, 2)
         
         ; Ratio of 0.05 grid box contatining station
         iStart = LONG((j*8L+4L)*nx*ny) 
         data2=READ_BINARY(hMeteo,DATA_DIMS=[nx,ny],DATA_START=iStart,$
                           DATA_TYPE=4,ENDIAN='little')
         data2  = REVERSE(data2, 2)
         
         ;*********************************************************************
         ; (5) Save the daily data to ENVI standard file
         ;*********************************************************************
         OPENW, HData1, sPrecipDailyFiles[j], /GET_LUN  
         WRITEU, HData1,data1
         FREE_LUN, HData1 
         ; Edit the envi header file
         ENVI_SETUP_HEAD, FNAME=sPrecipDailyFiles[j],NS=nx,NL=ny,NB=1,INTERLEAVE=0,$  
              DATA_TYPE=4,OFFSET=0,MAP_INFO=iMap,BNAMES=['Daily_Precip'],/WRITE,$
              /OPEN,R_FID=Data1_FID
         ENVI_FILE_MNG, ID=Data1_FID, /REMOVE
         
;         ; save the ratio file
;         OPENW, HData2, sRationDailyFiles[j], /GET_LUN  
;         WRITEU, HData2,TEMPORARY(data2)
;         FREE_LUN, HData2 
;         ; Edit the envi header file
;         ENVI_SETUP_HEAD, FNAME=sRationDailyFiles[j],NS=nx,NL=ny,NB=1,INTERLEAVE=0,$  
;              BNAMES=['Ratio of 0.05 grid box contatining station'],DATA_TYPE=4,$
;              OFFSET=0,MAP_INFO=iMap,/WRITE,/OPEN,R_FID=Data2_FID       
;         ENVI_FILE_MNG, ID=Data2_FID, /REMOVE
          
         ;*********************************************************************
         ; (6) Save the monthly data to ENVI standard file
         ;********************************************************************* 
         IF(j LT nMonths[k]) THEN nDataMonth = CombinePrecipData(nDataMonth,Data1)
         IF(j EQ nMonths[k]) THEN BEGIN
            ; save the monthly file
            OPENW,  HDataM, sPrecipMonthlyFiles[k], /GET_LUN  
            WRITEU, HDataM, nDataMonth
            FREE_LUN, HDataM 
            ; Edit the envi header file
            ENVI_SETUP_HEAD, FNAME=sPrecipMonthlyFiles[k],NS=nx,NL=ny,NB=1,$  
                 INTERLEAVE=0, DATA_TYPE=4,OFFSET=0,MAP_INFO=iMap,/WRITE,$
                 /OPEN,BNAMES=['Monthly_Precip'],R_FID=DataM_FID
            ENVI_FILE_MNG, ID=DataM_FID, /REMOVE
            ; the next month
            nDataYear       = CombinePrecipData(nDataYear,nDataMonth)
            nDataMonth[*,*] = 0.0
            k               = k+1
         ENDIF
       ENDFOR
       
       ;*********************************************************************
       ; (7) Save the yearly data to ENVI standard file
       ;********************************************************************* 
       OPENW,   HDataY, sPrecipYearlyFile, /GET_LUN  
       WRITEU,  HDataY,nDataYear
       FREE_LUN,HDataY 
       ; Edit the envi header file
       ENVI_SETUP_HEAD,FNAME=sPrecipYearlyFile,NS=nx,NL=ny,NB=1,INTERLEAVE=0,$
            DATA_TYPE=4,OFFSET=0,MAP_INFO=iMap,BNAMES=['Yearly_Precip'],/WRITE,$
            /OPEN,R_FID=DataY_FID
       ENVI_FILE_MNG, ID=DataY_FID, /REMOVE
       ; remove the meteo file
       FREE_LUN, hMeteo 
   ENDFOR

END

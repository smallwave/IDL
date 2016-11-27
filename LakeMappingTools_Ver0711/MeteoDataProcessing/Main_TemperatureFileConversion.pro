PRO Main_TemperatureFileConversion

   DailyFileDIR = 'E:\Tibet_OtherData\Meteological Data in China\TibetanTemperature\Daily\'
   MonthFileDIR = 'E:\Tibet_OtherData\Meteological Data in China\TibetanTemperature\'
   StationFile  = 'E:\Tibet_OtherData\Meteological Data in China\TibetanTemperature\Station.txt'
   
   ; Open the single station
   OPENR, Handle_Station, StationFile, /GET_LUN
   nID = UINT(0)
   sStationName = ''
   WHILE ~ EOF(Handle_Station) DO BEGIN

      READF, Handle_Station, nID, sStationName
      StationID     = STRTRIM(STRING(UINT(nID)),2)
      
      ; original daily file 
      DailyFileName = 't'+StationID+'.day'
      FilePaths  = FILE_SEARCH(DailyFileDIR,DailyFileName, COUNT = FileCount, $
                              /TEST_READ, /FULLY_QUALIFY_PATH)
      IF(FileCount LE 0) THEN CONTINUE
      DailyFile    = FilePaths[0]
      MonthlyFile  = DailyFileDIR+'T'+StationID+'_Month.txt'
      LoadDailyTemperature, DailyFile, MonthlyFile, sStationName
;      
      ; original monthly file
;      MonthFileName = 't'+StationID+'.mon'
;      FilePaths  = FILE_SEARCH(MonthFileDIR,MonthFileName, COUNT = FileCount, $
;                              /TEST_READ, /FULLY_QUALIFY_PATH)
;      IF(FileCount LE 0) THEN CONTINUE
;      MonthFile     = FilePaths[0]
;      MonthlyFile   = STRMID(MonthFile, 0, STRLEN(MonthFile)-4)+'_Monthly.txt'
;      LoadMonthTemperature, MonthFile, MonthlyFile, sStationName

   ENDWHILE

   FREE_LUN, Handle_Station

END
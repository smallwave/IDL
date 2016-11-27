PRO CreateTxtFileFromBinaryFile

   DailyFileDIR = 'E:\TibetanPrecip\Daily\'
   MonthFileDIR = 'E:\TibetanPrecip\Month\'
   StationFile  = 'E:\TibetanPrecip\Station.txt'
   ; Open the single station
   OPENR, Handle_Station, StationFile, /GET_LUN
   nID = UINT(0)
   sStationName = ''
   WHILE ~ EOF(Handle_Station) DO BEGIN

      READF, Handle_Station, nID, sStationName
      StationID     = STRTRIM(STRING(UINT(nID)),2)
      DailyFileName = 'R'+StationID+'.day'
      FilePaths  = FILE_SEARCH(DailyFileDIR,DailyFileName, COUNT = FileCount, $
                              /TEST_READ, /FULLY_QUALIFY_PATH)
      IF(FileCount LE 0) THEN CONTINUE
      DailyFileName = FilePaths[0]
      MonthFileName = MonthFileDIR+'R'+StationID+'_Month.txt'
      ;LoadDailyPrecip, DailyFileName, MonthFileName, sStationName
      ;LoadMonthPrecip, DailyFileName, MonthFileName, sStationName
      

   ENDWHILE

   FREE_LUN, Handle_Station

END
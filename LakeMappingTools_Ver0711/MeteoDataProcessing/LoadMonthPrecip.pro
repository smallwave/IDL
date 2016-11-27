PRO LoadMonthPrecip, MonthFile, MonthlyFile, StationName

;    DailyFile   = 'E:\TibetanPrecip\R55228.day'
;    MonthlyFile = 'E:\TibetanPrecip\R55228_Month.txt'
;    StationName = 'MangYa'
    ; Create the monthly file for save the results
    OPENW, Handle_Month, MonthlyFile, /GET_LUN
    sHeader = ['ID','Station','YEAR','JAN','FEB','MAR','APR','MAY','JUN',$
               'JUL','AUG','SEP','OCT','NOV','DEC','TOTAL']
    sFormatH= '(A5,2x,A12,2x,A4,2x,A5,2x,A5,2x,A5,2x,A5,2x,A5,2x,A5,2x,A5,2x,A5,2x,A5,2x,A5,2x,A5,2x,A5,2x,A5)'
    sFormatD= '(I5,2x,A12,2x,I4,2x,I5,2x,I5,2x,I5,2x,I5,2x,I5,2x,I5,2x,I5,2x,I5,2x,I5,2x,I5,2x,I5,2x,I5,2x,I5)'
    PRINTF,Handle_Month, sHeader, Format=sFormatH

    ; Open the single station
    OPENR, Handle_Day, MonthFile, /GET_LUN
    CurrentYear   = 0
    PreicpMonth   = INTARR(12)

    ; Read the first record
    READF, Handle_Day, sID, nYear, nMonth, nPrecip
    nYear       = UINT(nYear)
    nMonth      = UINT(nMonth)
    nPrecip     = UINT(nPrecip)

    CurrentID   = UINT(sID)
    CurrentYear = UINT(nYear)
    PreicpMonth[nMonth-1] = nPrecip


    WHILE ~ EOF(Handle_Day) DO BEGIN

      READF, Handle_Day, sID, nYear, nMonth, nPrecip
      nYear       = UINT(nYear)
      nMonth      = UINT(nMonth)
      nPrecip     = UINT(nPrecip)

      IF(nYear NE CurrentYear) THEN BEGIN
        ; If the Year changes, save the record
        PreicpYear     = UINT(TOTAL(PreicpMonth))
        PRINTF,Handle_Month,CurrentID,StationName,CurrentYear,PreicpMonth,PreicpYear,Format=sFormatD
        CurrentYear    = UINT(nYear)
        CurrentID      = UINT(sID)
        PreicpMonth[*] = 0
      ENDIF ELSE BEGIN
         PreicpMonth[nMonth-1] = nPrecip
      ENDELSE

    ENDWHILE


   FREE_LUN, Handle_Month
   FREE_LUN, Handle_Day

END

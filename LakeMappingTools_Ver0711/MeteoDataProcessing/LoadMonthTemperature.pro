PRO LoadMonthTemperature, MonthFile, MonthlyFile, StationName

    ; Create the monthly file for save the results
    OPENW, Handle_Month, MonthlyFile, /GET_LUN
    sHeader = ['ID','Station','YEAR','JAN','FEB','MAR','APR','MAY','JUN',$
               'JUL','AUG','SEP','OCT','NOV','DEC','TOTAL']
    sFormatH= '(A2,2x,A12,2x,A4,2x,A5,2x,A5,2x,A5,2x,A5,2x,A5,2x,A5,2x,A5,2x,A5,2x,A5,2x,A5,2x,A5,2x,A5,2x,A5)'
    sFormatD= '(I5,2x,A12,2x,I4,2x,I5,2x,I5,2x,I5,2x,I5,2x,I5,2x,I5,2x,I5,2x,I5,2x,I5,2x,I5,2x,I5,2x,I5,2x,I5)'
    PRINTF,Handle_Month, sHeader, Format=sFormatH

    ; Open the single station
    OPENR, Handle_Day, MonthFile, /GET_LUN
    CurrentYear   = 0
    PreicpMonth   = INTARR(12)

    ; Read the first record
    READF, Handle_Day, sID, nYear, nMonth, nPrecip
    IF(nPrecip GT 32000) THEN nPrecip = 0
    nYear       = UINT(nYear)
    nMonth      = UINT(nMonth)
    nPrecip     = FIX(nPrecip)

    CurrentID   = UINT(sID)
    CurrentYear = UINT(nYear)
    PreicpMonth[nMonth-1] = nPrecip


    WHILE ~ EOF(Handle_Day) DO BEGIN

      READF, Handle_Day, sID, nYear, nMonth, nPrecip
      IF(nPrecip GT 32000) THEN nPrecip = 0
      nYear       = UINT(nYear)
      nMonth      = UINT(nMonth)
      nPrecip     = FIX(nPrecip)

      IF(nYear NE CurrentYear) THEN BEGIN
        ; If the Year changes, save the record
        idx        = where(PreicpMonth NE 0,nCount)
        PreicpYear = ROUND(TOTAL(PreicpMonth)*1.0/nCount)
        PRINTF,Handle_Month,CurrentID,StationName,CurrentYear,PreicpMonth,PreicpYear,Format=sFormatD
        CurrentYear    = UINT(nYear)
        CurrentID      = UINT(sID)
        PreicpMonth[*] = 0  
        PreicpMonth[nMonth-1] = nPrecip
      ENDIF ELSE BEGIN
        PreicpMonth[nMonth-1] = nPrecip
      ENDELSE

    ENDWHILE
    idx        = where(PreicpMonth NE 0,nCount)
    PreicpYear = ROUND(TOTAL(PreicpMonth)*1.0/nCount)
    PRINTF,Handle_Month,CurrentID,StationName,CurrentYear,PreicpMonth,PreicpYear,Format=sFormatD

   FREE_LUN, Handle_Month
   FREE_LUN, Handle_Day

END

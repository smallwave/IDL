
FUNCTION DOY_to_MonthDay, nYear, nDays
    
    Juldays    = JULDAY(1,0,nYear)+nDays
    CALDAT, Juldays, Month,Day
    sMonth  = STRTRIM(Month,2)
    IF(Month LT 10) THEN sMonth = '0'+sMonth
    sDays  = STRTRIM(Day,2)
    IF(Day LT 10) THEN sDays   = '0'+sDays
    
    MonthDay = sMonth + sDays
    
    RETURN, MonthDay
    
END
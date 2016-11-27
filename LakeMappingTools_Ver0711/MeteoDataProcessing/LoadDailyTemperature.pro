PRO LoadDailyTemperature, DailyFile, MonthlyFile, StationName

;    DailyFile   = 'E:\TibetanPrecip\R55228.day'
;    MonthlyFile = 'E:\TibetanPrecip\R55228_Month.txt'
;    StationName = 'MangYa'
    ; Create the monthly file for save the results
    OPENW, Handle_Month, MonthlyFile, /GET_LUN
    sHeader = ['ID','Station','YEAR','JAN','FEB','MAR','APR','MAY','JUN',$
               'JUL','AUG','SEP','OCT','NOV','DEC','TOTAL','01DAY','02DAY',$
               '03DAY','04DAY','05DAY','06DAY','07DAY','08DAY','09DAY','10DAY',$
               '11DAY','12DAY']
    sFormatH= '(A2,2x,A12,2x,A4,2x,A5,2x,A5,2x,A5,2x,A5,2x,A5,2x,A5,2x,A5,2x,A5,2x,A5,2x,A5,2x,A5,2x,A5,2x,A5,2x,A5,2x,A5,2x,A5,2x,A5,2x,A5,2x,A5,2x,A5,2x,A5,2x,A5,2x,A5,2x,A5,2x,A5)'
    sFormatD= '(I5,2x,A12,2x,I4,2x,I5,2x,I5,2x,I5,2x,I5,2x,I5,2x,I5,2x,I5,2x,I5,2x,I5,2x,I5,2x,I5,2x,I5,2x,I5,2x,I5,2x,I5,2x,I5,2x,I5,2x,I5,2x,I5,2x,I5,2x,I5,2x,I5,2x,I5,2x,I5,2x,I5)'
    PRINTF,Handle_Month, sHeader, Format=sFormatH

    ; Open the single station
    OPENR, Handle_Day, DailyFile, /GET_LUN
    CurrentYear   = 0
    CurrentMonth  = 0
    Days          = 0
    SurfTemp      = INTARR(31)
    SurfTempMonth = INTARR(12)
    RecordDays    = INTARR(12)

    ; Read the first record
    READF, Handle_Day, sID, nYear, nMonth, nDay, nSurfTemp
    nYear       = UINT(nYear)
    nMonth      = UINT(nMonth)
    nDay        = UINT(nDay)
    nSurfTemp   = FIX(nSurfTemp)
    CurrentID   = UINT(sID)
    CurrentYear = UINT(nYear)
    CurrentMonth= UINT(nMonth)

    IF(nSurfTemp GE 32000) THEN BEGIN
       IF(nSurfTemp EQ 32744 OR nSurfTemp EQ 32766) THEN SurfTemp[nDay-1]=0
    ENDIF
    IF(nSurfTemp LT 30000)  THEN BEGIN
       SurfTemp[nDay-1]       = nSurfTemp
       RecordDays[nMonth-1]   = RecordDays[nMonth-1]+1
    ENDIF

    WHILE ~ EOF(Handle_Day) DO BEGIN
      
      READF, Handle_Day, sID, nYear, nMonth, nDay, nSurfTemp
      nYear                   = UINT(nYear)
      nMonth                  = UINT(nMonth)
      nDay                    = UINT(nDay)
      nSurfTemp               = FIX(nSurfTemp)

      IF(nYear NE CurrentYear) THEN BEGIN
        ; If the Year changes, save the record
        ; If the month changes, it indicates current month records are
        SurfTempMonth[CurrentMonth-1] = ROUND(TOTAL(SurfTemp)/RecordDays[CurrentMonth-1])
        SurfTemp[*]            = 0
        CurrentMonth           = nMonth
        
        idx = WHERE(SurfTempMonth NE 0,nCount)
        PreicpYear      = FIX(TOTAL(SurfTempMonth)*1.0/nCount)
        PRINTF,Handle_Month,CurrentID,StationName,CurrentYear,SurfTempMonth,PreicpYear,RecordDays,Format=sFormatD
        CurrentYear           = nYear
        CurrentID             = UINT(sID)
        SurfTempMonth[*]      = 0
        RecordDays[*]         = 0
        SurfTemp[*]           = 0
        
      ENDIF

      IF(nMonth NE CurrentMonth) THEN BEGIN
        ; If the month changes, it indicates current month records are
        SurfTempMonth[CurrentMonth-1] = ROUND(TOTAL(SurfTemp)/RecordDays[CurrentMonth-1])
        SurfTemp[*]            = 0
        CurrentMonth           = nMonth
        ; the new month record
        IF(nSurfTemp EQ 32744 OR nSurfTemp EQ 32766) THEN BEGIN
            SurfTemp[nDay-1]   = 0
        ENDIF ELSE BEGIN
           SurfTemp[nDay-1]    = nSurfTemp
           RecordDays[nMonth-1]= RecordDays[nMonth-1]+1
        ENDELSE
        
        
      ENDIF ELSE BEGIN
        ; the new month record
        IF(nSurfTemp EQ 32744 OR nSurfTemp EQ 32766) THEN BEGIN
           SurfTemp[nDay-1]    = 0
        ENDIF ELSE BEGIN
           SurfTemp[nDay-1]    = nSurfTemp
           RecordDays[nMonth-1]= RecordDays[nMonth-1]+1
        ENDELSE
      ENDELSE

    ENDWHILE
    
    SurfTempMonth[CurrentMonth-1] = ROUND(TOTAL(SurfTemp)/RecordDays[CurrentMonth-1])
    idx = WHERE(SurfTempMonth NE 0,nCount)
    SurfTempYear     = FIX(TOTAL(SurfTempMonth)*1.0/nCount)
    PRINTF,Handle_Month,CurrentID,StationName,CurrentYear,SurfTempMonth,SurfTempYear,RecordDays,Format=sFormatD


   FREE_LUN, Handle_Month
   FREE_LUN, Handle_Day

END

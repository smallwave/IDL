

PRO LoadDailyPrecip, DailyFile, MonthlyFile, StationName

;    DailyFile   = 'E:\TibetanPrecip\R55228.day'
;    MonthlyFile = 'E:\TibetanPrecip\R55228_Month.txt'
;    StationName = 'MangYa'
    ; Create the monthly file for save the results
    OPENW, Handle_Month, MonthlyFile, /GET_LUN
    sHeader = ['ID','Station','YEAR','JAN','FEB','MAR','APR','MAY','JUN',$
               'JUL','AUG','SEP','OCT','NOV','DEC','TOTAL','01DAY','02DAY',$
               '03DAY','04DAY','05DAY','06DAY','07DAY','08DAY','09DAY','10DAY',$
               '11DAY','12DAY']
    sFormatH= '(A5,2x,A12,2x,A4,2x,A5,2x,A5,2x,A5,2x,A5,2x,A5,2x,A5,2x,A5,2x,A5,2x,A5,2x,A5,2x,A5,2x,A5,2x,A5,2x,A5,2x,A5,2x,A5,2x,A5,2x,A5,2x,A5,2x,A5,2x,A5,2x,A5,2x,A5,2x,A5,2x,A5)'
    sFormatD= '(I5,2x,A12,2x,I4,2x,I5,2x,I5,2x,I5,2x,I5,2x,I5,2x,I5,2x,I5,2x,I5,2x,I5,2x,I5,2x,I5,2x,I5,2x,I5,2x,I5,2x,I5,2x,I5,2x,I5,2x,I5,2x,I5,2x,I5,2x,I5,2x,I5,2x,I5,2x,I5,2x,I5)'
    PRINTF,Handle_Month, sHeader, Format=sFormatH

    ; Open the single station
    OPENR, Handle_Day, DailyFile, /GET_LUN
    CurrentYear   = 0
    CurrentMonth  = 0
    Days          = 0
    Precip        = INTARR(31)
    PreicpMonth   = INTARR(12)
    RecordDays    = INTARR(12)

    ; Read the first record
    READF, Handle_Day, sID, nYear, nMonth, nDay, nPrecip
    nYear       = UINT(nYear)
    nMonth      = UINT(nMonth)
    nDay        = UINT(nDay)
    nPrecip     = UINT(nPrecip)
    CurrentID   = UINT(sID)
    CurrentYear = UINT(nYear)
    CurrentMonth= UINT(nMonth)

    IF(nPrecip GE 32000) THEN BEGIN

       IF(nPrecip EQ 32744 OR nPrecip EQ 32766) THEN Precip[nDay-1]=0
       IF(nPrecip EQ 32700) THEN BEGIN
          Precip[nDay-1]=0
          RecordDays[nMonth-1]= RecordDays[nMonth-1]+1
       ENDIF
       IF(nPrecip LT 32700) THEN BEGIN
          Precip[nDay-1]=nPrecip-32000
          RecordDays[nMonth-1]= RecordDays[nMonth-1]+1
       ENDIF
    ENDIF
    IF(nPrecip GE 31000 AND nPrecip LT 32000) THEN BEGIN
       Precip[nDay-1]      = nPrecip-31000
       RecordDays[nMonth-1]= RecordDays[nMonth-1]+1
    ENDIF
    IF(nPrecip LT 31000 AND nPrecip GE 30000) THEN BEGIN
       Precip[nDay-1]      = nPrecip-30000
       RecordDays[nMonth-1]= RecordDays[nMonth-1]+1
    ENDIF
    IF(nPrecip LT 30000)  THEN BEGIN
       Precip[nDay-1]      = nPrecip
       RecordDays[nMonth-1]= RecordDays[nMonth-1]+1
    ENDIF

    WHILE ~ EOF(Handle_Day) DO BEGIN

      READF, Handle_Day, sID, nYear, nMonth, nDay, nPrecip
      nYear       = UINT(nYear)
      nMonth      = UINT(nMonth)
      nDay        = UINT(nDay)
      nPrecip     = UINT(nPrecip)

      IF(nYear NE CurrentYear) THEN BEGIN
        ; If the Year changes, save the record
        PreicpYear     = UINT(TOTAL(PreicpMonth))
        PRINTF,Handle_Month,CurrentID,StationName,CurrentYear,PreicpMonth,PreicpYear,RecordDays,Format=sFormatD
        CurrentYear    = nYear
        CurrentID   = UINT(sID)
        PreicpMonth[*] = 0
        RecordDays[*]  = 0
        Precip[*]      = 0
      ENDIF

      IF(nMonth NE CurrentMonth) THEN BEGIN
        ; If the month changes, it indicates current month records are
        PreicpMonth[CurrentMonth-1] = TOTAL(Precip)
        Precip[*]      = 0
        CurrentMonth= nMonth
        ; the new month record
        IF(nPrecip GE 32000) THEN BEGIN
           IF(nPrecip EQ 32744 OR nPrecip EQ 32766) THEN Precip[nDay-1]=0
           IF(nPrecip EQ 32700) THEN BEGIN
              Precip[nDay-1]=0
              RecordDays[nMonth-1]= RecordDays[nMonth-1]+1
           ENDIF
           IF(nPrecip LT 32700) THEN BEGIN
              Precip[nDay-1]=nPrecip-32000
              RecordDays[nMonth-1]= RecordDays[nMonth-1]+1
           ENDIF
        ENDIF
        IF(nPrecip GE 31000 AND nPrecip LT 32000) THEN BEGIN
           Precip[nDay-1]      = nPrecip-31000
           RecordDays[nMonth-1]= RecordDays[nMonth-1]+1
        ENDIF
        IF(nPrecip LT 31000 AND nPrecip GE 30000)  THEN BEGIN
           Precip[nDay-1]      = nPrecip-30000
           RecordDays[nMonth-1]= RecordDays[nMonth-1]+1
        ENDIF
        IF(nPrecip LT 30000)  THEN BEGIN
           Precip[nDay-1]      = nPrecip
           RecordDays[nMonth-1]= RecordDays[nMonth-1]+1
        ENDIF
      ENDIF ELSE BEGIN
        ; the new month record
        IF(nPrecip GE 32000) THEN BEGIN
           IF(nPrecip EQ 32744 OR nPrecip EQ 32766) THEN Precip[nDay-1]=0
           IF(nPrecip EQ 32700) THEN BEGIN
              Precip[nDay-1]=0
              RecordDays[nMonth-1]= RecordDays[nMonth-1]+1
           ENDIF
           IF(nPrecip LT 32700) THEN BEGIN
              Precip[nDay-1]=0;nPrecip-32000
              RecordDays[nMonth-1]= RecordDays[nMonth-1]+1
           ENDIF
        ENDIF
        IF(nPrecip GE 31000 AND nPrecip LT 32000) THEN BEGIN
           Precip[nDay-1]      = nPrecip-31000
           RecordDays[nMonth-1]= RecordDays[nMonth-1]+1
        ENDIF
        IF(nPrecip LT 31000 AND nPrecip GE 30000)  THEN BEGIN
           Precip[nDay-1]      = nPrecip-30000
           RecordDays[nMonth-1]= RecordDays[nMonth-1]+1
        ENDIF
        IF(nPrecip LT 30000)  THEN BEGIN
           Precip[nDay-1]      = nPrecip
           RecordDays[nMonth-1]= RecordDays[nMonth-1]+1
        ENDIF
      ENDELSE

    ENDWHILE
    PreicpYear     = UINT(TOTAL(PreicpMonth))
    PRINTF,Handle_Month,CurrentID,StationName,CurrentYear,PreicpMonth,PreicpYear,RecordDays,Format=sFormatD


   FREE_LUN, Handle_Month
   FREE_LUN, Handle_Day

END

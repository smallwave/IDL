
FUNCTION GenerateFileName, FileName

   SensorID       = STRMID(FileName,0,2)
   
   IF(SensorID EQ 'LT') THEN SensorID = STRMID(FileName,0,3)
   
   ; MSS file
   IF(SensorID EQ 'LM') THEN BEGIN
      SensorType  = STRMID(FileName,2,1) +'m' 
      sPath       = 'p' + STRMID(FileName,3,3)
      sRow        = 'r' + STRMID(FileName,6,3)
      sYear       = '19'+ STRMID(FileName,11,2)
      nYear       = FIX(sYear)
      nDays       = FIX(STRMID(FileName,13,3))
      sDays       = DOY_to_MonthDay(nYear,nDays)
      sDate       = sYear+sDays
   ENDIF
   
   ; ETM file 
   IF(SensorID EQ 'L7') THEN BEGIN
      SensorType  = '7dk' 
      sPath       = 'p' + STRMID(FileName,3,3)
      sRow        = 'r' + STRMID(FileName,6,3)
      sDate       = STRMID(FileName,13,8)
   ENDIF
   
   ; TM file
   IF(SensorID EQ 'L4' OR SensorID EQ 'LT4' OR SensorID EQ 'L5' OR SensorID EQ 'LT5') THEN BEGIN
      IF(SensorID EQ 'L5' OR SensorID EQ 'LT5') THEN  SensorType='5tk' 
      IF(SensorID EQ 'L4' OR SensorID EQ 'LT4') THEN  SensorType='4tk' 
      IF(SensorID EQ 'L4' OR SensorID EQ 'L5') THEN BEGIN 
         sPath       = 'p' + STRMID(FileName,2,3)
         sRow        = 'r' + STRMID(FileName,5,3)
         sDate       = STRMID(FileName,12,8)
      ENDIF ELSE BEGIN
         sPath       = 'p' + STRMID(FileName,3,3)
         sRow        = 'r' + STRMID(FileName,6,3)
         sYear       = '19'+ STRMID(FileName,11,2)
         nYear       = FIX(sYear)
         nDays       = FIX(STRMID(FileName,13,3))
         sDays       = DOY_to_MonthDay(nYear,nDays)
         sDate       = sYear+sDays
      ENDELSE
   END
        
    ; Output ENVI File Name
    FileName       = sPath+sRow+'_'+SensorType+sDate
    
    Return, FileName
END
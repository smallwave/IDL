;+--------------------------------------------------------------------------
;| PUB_AcqDate2DOY
;+--------------------------------------------------------------------------
FUNCTION DATE_TO_DOY, sAcqDate

  ; get the year moth day from the string sAcqDate
  nYear     = LONG(STRMID(sAcqDate,0,4))
  nMonth    = LONG(STRMID(sAcqDate,4,2))
  nDay      = LONG(STRMID(sAcqDate,6,2))
  ; calculate the DOY
  nDOY      = JulDay(nMonth,nDay,nYear)-JulDay(1,0,nYear)
  RETURN, nDOY
END

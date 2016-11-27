
FUNCTION MODIS_DATE, MOD_TYPE, nYear, sDATE=sDATE
     
    ;leap-year or not
    nLeap  = ((nYear MOD 4) EQ 0)
    sDATE8 =['001','009','017','025','033','041','049','057','065','073','081',$
             '089','097','105','113','121','129','137','145','153','161','169',$
             '177','185','193','201','209','217','225','233','241','249','257',$
             '265','273','281','289','297','305','313','321','329','337','345',$
             '353','361']
    siz    = SIZE(sDATE8)
    nCount = siz[1]/2
    IDX    = LINDGEN(nCount)*2
    sDATE16= sDate8[IDX]
    ;
    CASE MOD_TYPE OF
        'MCD43B3' : sDATE = (nYear EQ 2000)? sDATE8(8:45) : sDATE8
        'MOD11A2' : sDATE = (nYear EQ 2000)? sDATE8(8:45) : sDATE8
        'MOD12Q1' : sDATE = ['001']
        'MOD13Q1' : sDATE = (nYear EQ 2000)? sDATE16(3:22) : sDATE16
        'MOD13A2' : sDATE = (nYear EQ 2000)? sDATE16(3:22) : sDATE16
        'MOD15A2' : sDATE = (nYear EQ 2000)? sDATE8(6:45) : sDATE8
        'MOD17A2' : sDATE = (nYear EQ 2000)? sDATE8(8:45) : sDATE8
    ELSE          : RETURN, 0
    ENDCASE
    sDATE = 'A' + STRTRIM(STRING(nYear),2) + sDATE
    RETURN, 1
END
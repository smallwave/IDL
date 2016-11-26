;+
; ;**********************************************************
; Author: wuxb
; Email: wavelet2008@163.com
;
; NAME:
;    D:\workspace\Tech\Code\IDL\ENVI_IDL4.7\SoilTextureProduce\DataPreprocessing\SoilProcessCode.pro
; PARAMETERS:
; Some Path
; Write by :
;    2016-11-25 13:25:53
;;MODIFICATION HISTORY:
;;   Modified  :  2016-11-26
;
PRO SOILPROCESSCODE

  ENVIFilePaths = "D:/worktemp/Permafrost(FrostModel)/Data/Soil/DaiSoilTexture"
  OutFilePath   = "D:/worktemp/Permafrost(FrostModel)/Data/Soil/DaiSoilTextureOut"
  IF STRLEN(ENVIFilePaths) EQ 0 THEN RETURN

  ;Define soil depths
  soilDepth  = [0.045,0.046,0.075,0.123,0.204,0.336,0.554]

  ;Envi open file
  ENVI_OPEN_FILE, ENVIFilePaths, r_fid=fid, /no_interactive_query, /no_realize
  IF fid EQ -1 THEN  RETURN
  ENVI_FILE_QUERY, fid, file_type=file_type, NL=NL, NS=NS,dims=dims,NB=NB
  soilData =  INTARR(NS,NL,NB)
  FOR b=0,nb-1,1 DO BEGIN
    soilData[*,*,b] = ENVI_GET_DATA(FID = fid,POS = b,DIMS = dims)
  ENDFOR

  ;DEFINE OUTPUT ARRAY
  outArray =  INTARR(NS,NL)

  ;read and  process
  FOR i =0, ns-1 DO BEGIN
    FOR j= 0, nl-1 DO BEGIN
      soilType    =  soilData[i,j,*]
      usoilType   =  soilType[UNIQ(soilType, SORT(soilType))]
      nusoilType  =  N_ELEMENTS(usoilType)
      sumDepths   =  0.0
      outputType  =  7
      ;get the type to represent the cell
      FOR k =0, nusoilType-1 DO BEGIN
        sumDepth = TOTAL(soilDepth[WHERE(soilType EQ usoilType[k])])
        IF (sumDepth GT sumDepths) THEN BEGIN
          sumDepths      =  sumDepth
          outArray[i,j]  =  usoilType[k]
        ENDIF
      ENDFOR
    ENDFOR
  ENDFOR

  OPENW, HData, OutFilePath, /GET_LUN
  WRITEU, HData,outArray
  FREE_LUN, HData
  map_info = ENVI_GET_MAP_INFO(fid=fid)

  ENVI_SETUP_HEAD,FNAME=OutFilePath,NS=NS,NL=NL,NB=1,INTERLEAVE=0,$
    DATA_TYPE=2,OFFSET=0,MAP_INFO=map_info,/WRITE,$
    /OPEN,R_FID=Data_FID

END
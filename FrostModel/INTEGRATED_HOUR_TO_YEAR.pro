;*******************************************************************************
; PURPOSE:
;  Convert CMORPTH to UNZIP
;
; INPUTS:
; CMORPTHDirectory: input file path.
; UNZIPDirectory: output file path.
;
; OUTPUTS:
; envi
;
; AUTHOR:
; wuxb
;
; MODIFICATION HISTORY:
; 2016.11.28
; 2016.11.30   update add  half hour to one hour
;
;*******************************************************************************
PRO  INTEGRATED_HOUR_TO_YEAR

    CMORPTHDirectory   = 'D:\worktemp\Permafrost(FrostModel)\Data\Prec\TempUnZip\'
    OutYearFile        = 'D:\worktemp\Permafrost(FrostModel)\Data\Prec\PrecYear\QTP.dat'
    
    IF(KEYWORD_SET(CMORPTHDirectory) EQ 0) THEN RETURN

    HoursFiles    = FILE_SEARCH(CMORPTHDirectory, COUNT = nFileCount, '*.dat', $
      /TEST_READ, /FULLY_QUALIFY_PATH)
    IF(nFileCount LE 0) THEN BEGIN
      MESSAGE, 'There are no valid GLS CMORPTH data to be processed.'
      RETURN
    ENDIF
    
    ENVI_OPEN_FILE, HoursFiles[0], r_fid=fid, /no_interactive_query, /no_realize
    IF fid EQ -1 THEN  RETURN
    ENVI_FILE_QUERY,fid,data_type=data_type,interleave=interleave, nl=nl, ns=ns,offset=offset,dims=dims
    map_info=ENVI_GET_MAP_INFO(fid=fid)
    OutYear = FLTARR(ns,nl)
    ENVI_FILE_MNG, ID=fid,/REMOVE


    FOR i=0,nFileCount-1 DO BEGIN
      ;***********************************************************************
      ; {1) open file
      ;***********************************************************************
      hourFilePath   = HoursFiles[i]
      ENVI_OPEN_FILE, hourFilePath, r_fid=fid, /no_interactive_query, /no_realize
      IF fid EQ -1 THEN  RETURN
      ;***********************************************************************
      ; {2) get date
      ;***********************************************************************
      data =ENVI_GET_DATA(fid=fid,pos=[0],dims=dims)
      data(WHERE(data < 0)) = 0
      ENVI_FILE_MNG, ID=fid,/REMOVE
      ;***********************************************************************
      ; {3) add data to year
      ;***********************************************************************
      OutYear =  OutYear + data
    ENDFOR
    
    OutYear    =  REVERSE(OutYear, 2)
    
    ;3.2   Monthly file names
    OPENW, HData, OutYearFile, /GET_LUN
    WRITEU, HData,OutYear
    FREE_LUN, HData

    ; Edit the envi header file
    ENVI_SETUP_HEAD, FNAME=OutYearFile,NS=ns,NL=nl,NB=1,INTERLEAVE=interleave,$
      DATA_TYPE=data_type,OFFSET=offset,MAP_INFO=map_info,/WRITE,$
      /OPEN,R_FID=Data_FID
      
    ENVI_FILE_MNG, id = r_fid, /REMOVE
END
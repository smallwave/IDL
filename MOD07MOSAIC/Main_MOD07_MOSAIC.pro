;;      MAIN_RS_IMAGE_PRO_SYS
;; PURPOSE:
;;     MOD07_HDF_TO_TIFF
;;
;; MODIFICATION HISTORY:
;;
;;  Write  :  XiaoBo WU,2016 09 13
;   Update :  Xiaobo WU,2016 09 15   add Mosaic
;-
;*****************************************************************************

;+--------------------------------------------------------------------------
;| Main_MOD07_MOSAIC
;+--------------------------------------------------------------------------
PRO Main_MOD07_MOSAIC, MODISDirectory = MODISDirectory, $
  ENVIDirectory = ENVIDirectory
  
  RESOLVE_ROUTINE, 'PUB_AcqDate2DOY' 
  RESOLVE_ROUTINE, 'GEOREF_MOSAIC_SETUP'
  RESOLVE_ROUTINE, 'MOD07_HDF_TO_ENVI'
  RESOLVE_ROUTINE, 'MODIS_Resize'
  RESOLVE_ROUTINE, 'MODIS_Mosaic'

  ENVI, /RESTORE_BASE_SAVE_FILES
  ENVI_BATCH_INIT, /NO_STATUS_WINDOW
  
  
  ;dir
  HDFDirectory       = 'D:\\In\\'
  TIFFDirectory      = 'D:\\Out\\'
  MosaicDirectory    = 'D:\\Mosaic\\'
  ; var
  ExtractionVar      = ['Total_Ozone']
  ; time
  StartDate          = JULDAY(1,1,2012)
  EndDate            = JULDAY(1,2,2012)

  ;Select Datas
  ProcessDates       =  TIMEGEN(START=StartDate, FINAL=EndDate,unit="D")
  szDates            = SIZE(ProcessDates,/N_ELEMENTS)
  FOR i =0, szDates -1 DO BEGIN
    CALDAT,ProcessDates[i],Month, Day, Year
    strDate          =     STRING(Year,FORMAT = '(i4)')      $
      + STRING(Month,FORMAT = '(i2.2)')   $
      + STRING(Day,FORMAT = '(i2.2)')
    nDOY             = PUB_AcqDate2DOY(strDate)

    ;+--------------------------------------------------------------------------
    ;| 01 
    ;+--------------------------------------------------------------------------
    strSeachDateTime = '*A' + STRING(Year,FORMAT = '(i4)') + STRING(nDOY,FORMAT = '(i3.3)') + '*.hdf'
    MODISFilePaths = FILE_SEARCH(HDFDirectory,strSeachDateTime, COUNT = nCount, /TEST_READ, /FULLY_QUALIFY_PATH)
    IF(nCount LE 0) THEN BEGIN
      RETURN
    ENDIF
    IF(MOD07_HDF_TO_ENVI(MODISFilePaths,TIFFDirectory,ExtractionVar) EQ 0) THEN BEGIN
      PRINT, strSeachDateTime + "with error in convert to tiff"
    ENDIF
    ;+--------------------------------------------------------------------------
    ;| 02
    ;+--------------------------------------------------------------------------
    strSeachDateTime = '*A' + STRING(Year,FORMAT = '(i4)') + STRING(nDOY,FORMAT = '(i3.3)') + '*.dat'
    MODISFilePaths = FILE_SEARCH(HDFDirectory,strSeachDateTime, COUNT = nCount, /TEST_READ, /FULLY_QUALIFY_PATH)
    IF(nCount LE 0) THEN BEGIN
      RETURN
    ENDIF
    IF(MODIS_Resize(MODISFilePaths,TIFFDirectory) EQ 0) THEN BEGIN
      PRINT, strSeachDateTime + "with error in Resize"
    ENDIF
    ;+--------------------------------------------------------------------------
    ;| 03
    ;+--------------------------------------------------------------------------
    strSeachDateTime = '*A' + STRING(Year,FORMAT = '(i4)') + STRING(nDOY,FORMAT = '(i3.3)') + '*.tif'
    MODISFilePaths = FILE_SEARCH(TIFFDirectory,strSeachDateTime, COUNT = nCount, /TEST_READ, /FULLY_QUALIFY_PATH)
    IF(nCount LE 0) THEN BEGIN
      RETURN
    ENDIF
    IF(MODIS_Mosaic(MODISFilePaths,MosaicDirectory,ExtractionVar) EQ 0) THEN BEGIN
      PRINT, strSeachDateTime + "with error in Mosaic"
    ENDIF


  ENDFOR  ; date
  
  ENVI_BATCH_EXIT
  
END
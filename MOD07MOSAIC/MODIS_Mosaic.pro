;+--------------------------------------------------------------------------
;| MODIS_Mosaic
;+--------------------------------------------------------------------------

FUNCTION MODIS_Mosaic, MODISFilePaths, Mosaic_DIR, ExtractionVar

  FileCount  = SIZE(MODISFilePaths,/N_ELEMENTS)
  IF(FileCount LE 0) THEN RETURN, 0

  ;**************************************************************************
  ; [1] Load SRTM files and generate mosaic parameters
  ;**************************************************************************
  FIDS = LONARR(FileCount)
  DIMS = FLTARR(5,FileCount)
  see_through_val = BYTARR(FileCount)
  use_see_through = INTARR(FileCount)
  ; Open the first file
  MODISFilePath= MODISFilePaths[0]
  MODISFile   = STRMID(MODISFilePath, 0, (STRLEN(MODISFilePath)-4))
  ; Get the output filename
  FileName      = FILE_BASENAME(MODISFile)
  FileMosaic    = FILE_BASENAME(Mosaic_DIR)
  ; Version: 'V4' or 'V5'
  nIndex      = STRPOS(FileName, '_')
  ProductVer  = STRMID(FileName, 0,nIndex)
  ; Path Row: h**v**
  FileName    = STRMID(FileName, 9,8)
  File        = ProductVer+'_'+FileName
  OutFile     = Mosaic_DIR + File + '_' + ExtractionVar + '_Mongolia.dat'
  ENVI_OPEN_FILE, MODISFilePath, R_FID = MODIS_FID
  IF(MODIS_FID EQ -1) THEN GOTO, EndPro
  FIDS[0]    = MODIS_FID
  use_see_through[*,0]=[1L]
  ENVI_FILE_QUERY, MODIS_FID, NB=NB, DIMS=iDIMS, DATA_TYPE=DATA_TYPE, $
    BNAMES = BNAMES
  DIMS[*,0]  = iDIMS
  Proj       = ENVI_GET_PROJECTION(FID = MODIS_FID,PIXEL_SIZE=PIXEL_SIZE)
  POS  = LONARR(NB,FileCount)            ; Pos
  POS[*,0] = LINDGEN(NB)
  ; Open the other files
  FOR i=1L, FileCount-1 DO BEGIN
    MODISFilePath= MODISFilePaths[i]
    ; MODISFilePath= STRMID(MODISFilePath, 0, STRLEN(MODISFilePath)-4)
    ; Load the SRTM file and get the basic image information
    ENVI_OPEN_FILE, MODISFilePath, R_FID = MODIS_FID
    IF(MODIS_FID EQ -1) THEN GOTO, EndPro
    FIDS[i]    = MODIS_FID
    see_through_val[i] = 0
    use_see_through[i] = 1
    ; Width, Height, Band Count, dimensions, Data type of the image
    ENVI_FILE_QUERY, MODIS_FID, NB=NB, DIMS=iDIMS, DATA_TYPE=DATA_TYPE
    DIMS[*,i]  = iDIMS
    POS[*,i]   = LINDGEN(NB)
  ENDFOR

  ;**************************************************************************
  ;
  ; [2] call georef_mosaic_setup to calculate the xsize, ysize, x0, y0,
  ;    and map_info structure, input parameters are FIDs, dims and pixel size
  ;
  ;**************************************************************************
  GEOREF_MOSAIC_SETUP, FIDS=FIDS, DIMS, PIXEL_SIZE, XSIZE=XSIZE, YSIZE=YSIZE,$
    X0=X0, Y0=Y0, MAP_INFO=MAP_INFO

  ;**************************************************************************
  ;
  ; [3] call mosaic_doit, Use a background value of 0 and set the output data
  ;     and mapinfo structure, input parameters are FIDs, dims and pixel size
  ;     type to Integer (16 bits)
  ;
  ;**************************************************************************

  ENVI_DOIT, 'MOSAIC_DOIT', FID=FIDS, POS=POS, DIMS=DIMS, X0=X0, Y0=Y0, $
    XSIZE=XSIZE, YSIZE=YSIZE, GEOREF=1, BACKGROUND=0, $
    MAP_INFO=MAP_INFO, PIXEL_SIZE=PIXEL_SIZE, OUT_DT=DATA_TYPE, $
    SEE_THROUGH_VAL=see_through_val, USE_SEE_THROUGH=use_see_through,$
    OUT_NAME=OutFile, R_FID=MOSAIC_ID

  FOR i=0L, FileCount-1 DO BEGIN
    ENVI_FILE_MNG, ID=FIDS[i], /REMOVE
  ENDFOR

  ENVI_FILE_MNG, ID=MOSAIC_ID, /REMOVE

  RETURN, 1

  EndPro:
  FOR j=0L,i-1 DO BEGIN
    ENVI_FILE_MNG, ID = FIDS[j], /REMOVE
  ENDFOR

  RETURN, 1

END
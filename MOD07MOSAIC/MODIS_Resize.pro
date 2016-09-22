;+--------------------------------------------------------------------------
;| MODIS_Resize
;+--------------------------------------------------------------------------
FUNCTION MODIS_Resize, MODISFilePaths,TIFFDirectory

  FileCount  = SIZE(MODISFilePaths,/N_ELEMENTS)
  IF(FileCount LE 0) THEN RETURN, 0

  ; Calculate the output pixel size, default method 2
  method = 1
  CASE method OF
    1: BEGIN
      ; Method 1: using minium pixel size of all MOYD low cloud bands
      psarr = DBLARR(2, FileCount)
      FOR i = 0, FileCount - 1 DO BEGIN
        fname = MODISFilePaths[i]
        ENVI_OPEN_DATA_FILE, fname, r_fid = fid
        IF (fid EQ -1) THEN RETURN,0

        map_info = ENVI_GET_MAP_INFO(fid = fid)
        psarr[*, i] = map_info.ps[0:1]

        ENVI_FILE_MNG, id = fid, /REMOVE
      ENDFOR
      ; Minium pixel size
      IF FileCount EQ 1 THEN out_ps = psarr ELSE out_ps = MIN(psarr, DIMENSION = 2)
    END
    2: BEGIN
      ; Method 2: using latitude of study area centroid to calculate pixel size
      ; Bounding rectangle of study area
      BoundingRect = ['118.5', '114.5', '36', '40']
      lat = DOUBLE(BoundingRect[2:3])
      ; Earth radius in KM
      R = 6371007.181/1000
      ; Parellel circle radius in KM
      r = R*COS(ABS(MEAN(lat)/180*!PI))
      ; Degrees per KM
      out_ps = [360/(2*!PI*r), 360/(2*!PI*r)]
    END
  ENDCASE

  FOR i = 0, FileCount - 1 DO BEGIN
    fname = MODISFilePaths[i]
    ENVI_OPEN_DATA_FILE, fname, r_fid = fid
    IF (fid EQ -1) THEN RETURN, 0 

    ENVI_FILE_QUERY, fid, dims = dims, nb = nb
    pos = LINDGEN(nb)

    map_info = ENVI_GET_MAP_INFO(fid = fid)
    ps = map_info.ps[0:1]
    ; Caculate the rebin factors for x and y
    IF (ps[0] NE out_ps[0]) OR (ps[1] NE out_ps[1]) THEN rfact = out_ps/ps ELSE rfact = [1, 1]

    fbname = FILE_BASENAME(fname, '.dat')
    out_name = TIFFDirectory + fbname + '_R.tif'
    PRINT, out_name
    ENVI_DOIT, 'RESIZE_DOIT', fid = fid, pos = pos, dims = dims, interp = 0, rfact = rfact, $
      out_name = out_name, r_fid = r_fid

    ENVI_FILE_MNG, id = fid, /REMOVE,/DELETE
    ENVI_FILE_MNG, id = r_fid, /REMOVE
  ENDFOR
  RETURN,1
END
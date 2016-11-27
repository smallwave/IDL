; program to estimate mosaic parameters

PRO GEOREF_MOSAIC_SETUP, FIDS=FIDS, DIMS, OUT_PS, XSIZE=XSIZE, YSIZE=YSIZE, $
                         X0=X0, Y0=Y0, MAP_INFO=MAP_INFO

    ; some basic error checking
    ;
    IF N_ELEMENTS(FIDS) LT 2 THEN BEGIN
       XSIZE = -1
       YSIZE = -1
       X0 = -1
       Y0 = -1
       RETURN
    ENDIF

    ; - compute the size of the output mosaic (XSIZE and YSIZE)
    ; - store the map coords of the UL corNEr of each image since you'll NEed it later
    nfiles       = N_ELEMENTS(FIDS)
    UL_corNErs_X = DBLARR(nfiles)
    UL_corNErs_Y = DBLARR(nfiles)
    east  = -1e34
    west  = 1e34
    north = -1e34
    south = 1e34
    FOR i=0,nfiles-1 DO BEGIN
        pts = [ [DIMS[1,i], DIMS[3,i]],   $ ; UL
                [DIMS[2,i], DIMS[3,i]],   $ ; UR
                [DIMS[1,i], DIMS[4,i]],   $ ; LL
                [DIMS[2,i], DIMS[4,i]] ]    ; LR

        ENVI_CONVERT_FILE_COORDINATES, FIDS[i], pts[0,*], pts[1,*], $
                                       xmap, ymap, /TO_MAP
        UL_corNErs_X[i] = xmap[0]
        UL_corNErs_Y[i] = ymap[0]
        east  = east  > MAX(xmap)
        west  = west  < MIN(xmap)
        north = north > MAX(ymap)
        south = south < MIN(ymap)
    ENDFOR

    XSIZE = east - west
    YSIZE = north - south
    XSIZE_pix = ROUND( XSIZE/OUT_PS[0] )
    YSIZE_pix = ROUND( YSIZE/OUT_PS[1] )

    ; to make things easy, create a temp image that's got a header
    ; that's the same as the output mosaic image
    ;
    proj     = ENVI_GET_PROJECTION(FID=FIDS[0])
    MAP_INFO = ENVI_MAP_INFO_CREATE(proj=proj, mc=[0,0,west,north], PS=OUT_PS)
    temp     = BYTARR(10,10)
    ENVI_ENTER_DATA, temp, MAP_INFO=MAP_INFO, /no_realize, R_FID=tmp_fid

    ; find the x and y offsets FOR the images
    ;
    X0 = LONARR(nfiles)
    Y0 = LONARR(nfiles)
    FOR i=0,nfiles-1 DO BEGIN
        ENVI_CONVERT_FILE_COORDINATES, tmp_fid, xpix, ypix, UL_corNErs_X[i], UL_corNErs_Y[i]
        xPix = LONG(xPix)
        yPix = LONG(yPix)
        IF((xPix MOD 1200) NE 0) THEN xPix = xPix + 1
        IF((yPix MOD 1200) NE 0) THEN yPix = yPix + 1
        X0[i] = xpix
        Y0[i] = ypix
    ENDFOR

;    print, 'FIDS = ', FIDS
;    print, 'DIMS = ', DIMS
;    print, 'OUT_PS = ', OUT_PS
;    print, 'XSIZE = ', XSIZE
;    print, 'YSIZE = ', YSIZE
;    print, 'X0 = ', X0
;    print, 'Y0 = ', Y0
;    print, 'MAP_INFO = ', MAP_INFO

    ; delete the tmp file
    ;
    ENVI_FILE_MNG , ID=tmp_fid, /remove, /no_warning

END


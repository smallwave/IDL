PRO MODIS_MASK, MODIS_FID, MASKFILE, SUBFILE

    ENVI_FILE_QUERY, MODIS_FID, NB = NB, DIMS=MODIS_DIMS, BNAMES=BNAMES

    ENVI_OPEN_FILE, MASKFILE, R_FID = MASK_FID
    ENVI_FILE_QUERY, MASK_FID,NS=Width,NL=Height,DIMS=MASK_DIMS
    Mapinfo = ENVI_GET_MAP_INFO(FID = MASK_FID)
    Proj    = ENVI_GET_PROJECTION(FID = MASK_FID, PIXEL_SIZE = PixSiz)

    ; Make the MODIS be the same size as MASK File, so we need to get
    ; the spatial extent of MODIS file
    MASK_xPix = [0, Width-1]
    MASK_yPix = [0, Height-1]
    ENVI_CONVERT_FILE_COORDINATES, MASK_FID, MASK_xPix, MASK_yPix, $
                                   MASK_xMap, MASK_yMap,/TO_MAP
    ; Convert it to the pix coordinates of the MODIS file
    ENVI_CONVERT_FILE_COORDINATES, MODIS_FID, MODIS_xPix, MODIS_yPix,$
                                   MASK_xMap, MASK_yMap
    ;
    MODIS_xPix = LONG(MODIS_xPix)
    MODIS_yPix = LONG(MODIS_yPix)
    DIMS  = [-1,MODIS_xPix[0],MODIS_xPix[1],MODIS_yPix[0],MODIS_yPix[1]]
    POS = LINDGEN(NB)
    ENVI_OUTPUT_TO_EXTERNAL_FORMAT, FID = MODIS_FID, DIMS = DIMS, POS = POS,$
                           OUT_BNAME =BNAMES, /ENVI, OUT_NAME=SUBFILE
    ENVI_FILE_MNG, ID=MASK_FID, /REMOVE

END
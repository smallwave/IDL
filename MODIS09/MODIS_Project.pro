PRO MODIS_Project,MosaicFile,SubsetFile,MASK_FILE
    
    ;MosaicFile = 'E:\MODIS_Shen\test\MOD13A2_A2006353.dat'
    ;SubsetFile = 'E:\MODIS_Shen\test\MOD13A2_A2006353_reproj.dat'
    ;MASK_FILE  = 'E:\MODIS_DATA\MidAsia_Mask\MidAsia_Mask'   
           
    ENVI_OPEN_FILE,MosaicFile,R_FID=MODIS_FID
    ENVI_FILE_QUERY,MODIS_FID,NB=NB,DIMS=MODIS_DIMS,BNAMES=BNAMES,DATA_TYPE=DT
    
    ENVI_OPEN_FILE, MASK_FILE,R_FID=MASK_FID
    ENVI_FILE_QUERY, MASK_FID,NS=NS_M,NL=NL_M,DIMS=MASK_DIMS
    Mapinfo = ENVI_GET_MAP_INFO(FID=MASK_FID)
    Proj    = ENVI_GET_PROJECTION(FID=MASK_FID, PIXEL_SIZE=PixSiz)
    
    ; First convert the MODIS file to the projection of MASK file
    POS     = LINDGEN(NB)
    FileName   = STRMID(MosaicFile, 0, STRLEN(MosaicFile)-4)
    ProjectFile = FileName+'_proj'
    ENVI_CONVERT_FILE_MAP_PROJECTION, FID=MODIS_FID, POS=POS, DIMS=MODIS_DIMS, $
          O_PROJ=Proj, O_PIXEL_SIZE=PixSiz, GRID=[100,100], WARP_METHOD=0,$
          RESAMPLING=1,OUT_BNAME=BNAMES, BACKGROUND=0,$
          OUT_NAME=ProjectFile,R_FID=Prj_FID
    ; delete the MODIS file
    ENVI_FILE_MNG, ID=MODIS_FID, /REMOVE
    
    ; Make the MODIS be the same size as MASK File, so we need to get
    ; the spatial extent of MODIS file
    MASK_xPix = [0, NS_M-1]
    MASK_yPix = [0, NL_M-1]
    ENVI_CONVERT_FILE_COORDINATES, MASK_FID, MASK_xPix, MASK_yPix, $
                                   MASK_xMap, MASK_yMap,/TO_MAP
    ; Convert it to the pix coordinates of the MODIS file
    ENVI_CONVERT_FILE_COORDINATES, Prj_FID, MODIS_xPix, MODIS_yPix,$
                                   MASK_xMap, MASK_yMap
    ;
    MODIS_xPix = LONG(MODIS_xPix)
    MODIS_yPix = LONG(MODIS_yPix)
    DIMS  = [-1,MODIS_xPix[0],MODIS_xPix[0]+NS_M-1,MODIS_yPix[0],MODIS_yPix[0]+NL_M-1]
    
    IF(DT EQ 1) THEN nData = BYTARR(NS_M,NL_M,NB)
    IF(DT EQ 2) THEN nData = INTARR(NS_M,NL_M,NB)
    IF(DT EQ 3) THEN nData = LONARR(NS_M,NL_M,NB)
    IF(DT EQ 4) THEN nData = FLTARR(NS_M,NL_M,NB)
    IF(DT EQ 5) THEN nData = DBLARR(NS_M,NL_M,NB)
          
    
    MASK  = ENVI_GET_DATA(FID=MASK_FID,DIMS=MASK_DIMS,POS=0)
    FOR i=0,NB-1 DO BEGIN
      Data = ENVI_GET_DATA(FID=Prj_FID,DIMS=DIMS,POS=i)
      nData[*,*,i] = Data * MASK
    ENDFOR
    
    ENVI_ENTER_DATA, nData, BNAMES=BNAMES, MAP_INFO=MapInfo,R_FID=Sub_FID
    ENVI_OUTPUT_TO_EXTERNAL_FORMAT,FID=Sub_FID,DIMS=MASK_DIMS,POS=POS,$
          OUT_BNAME=BNAMES, /ENVI,OUT_NAME=SubsetFile
    ENVI_FILE_MNG, ID=Sub_FID,/REMOVE,/DELETE
    ENVI_FILE_MNG, ID=Prj_FID,/REMOVE,/DELETE
    
END
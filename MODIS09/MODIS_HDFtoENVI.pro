;;
;-
;******************************************************************************************************************

PRO MODIS_HDFtoENVI, MODISDirectory, ENVIDirectory
   
;   MODISDirectory = 'D:\LeiYM\MODIS09GHK\'
;   ENVIDirectory  = 'D:\LeiYM\MODIS\'
   
   MODISFilePaths = FILE_SEARCH(MODISDirectory,'*.hdf', COUNT = nCount, /TEST_READ, /FULLY_QUALIFY_PATH)

   IF(nCount LE 0) THEN RETURN
   FOR i=0, nCount-1 DO BEGIN

      MODISFile   = MODISFilePaths[i]
      FileName    = FILE_BASENAME(MODISFile)
      FileName    = STRMID(FileName, 0, STRLEN(FileName)-4)
      nIndex      = STRPOS(FileName, '.', /REVERSE_SEARCH)
      FileName    = STRMID(FileName, 0, nIndex)
      ; Version: 'V4' or 'V5'
      nIndex      = STRPOS(FileName, '.', /REVERSE_SEARCH)
      ProductVer  = STRMID(FileName, nIndex+1,3)
      FileName    = STRMID(FileName, 0, nIndex)
      ; Path Row: h**v**
      nIndex      = STRPOS(FileName, '.', /REVERSE_SEARCH)
      PathRow     = STRMID(FileName, nIndex+1,6)
      FileName    = STRMID(FileName, 0, nIndex)
      ; Date
      nIndex      = STRPOS(FileName, '.', /REVERSE_SEARCH)
      ProductDate = STRMID(FileName, nIndex+1,8)
      ProductType = STRMID(FileName, 0, nIndex)
      FileName    = ProductType + '_' + ProductDate + '_' + PathRow + '_' + ProductVer

      IF(ProductType EQ 'MOD09GHK' OR ProductType EQ 'MOD09GQK' OR ProductType EQ 'MOD09GQ'  OR $
         ProductType EQ 'MOD09GA'  OR ProductType EQ 'MOD09A1'  OR ProductType EQ 'MYD09GHK' OR $
         ProductType EQ 'MYD09GQK' OR ProductType EQ 'MYD09GQ'  OR ProductType EQ 'MYD09GA'  OR $
         ProductType EQ 'MYD09A1'  OR ProductType EQ 'MOD11A1'  OR ProductType EQ 'MOD11A2'  OR $
         ProductType EQ 'MOD12Q1'  OR ProductType EQ 'MOD13Q1'  OR ProductType EQ 'MOD13A1'  OR $
         ProductType EQ 'MOD15A2'  OR ProductType EQ 'MOD17A2'  OR ProductType EQ 'MOD17A3'  OR $
         ProductType EQ 'MCD43A3'  OR ProductType EQ 'MOD13A2'  OR ProductType EQ 'MCD43B3'  OR $ 
         ProductType EQ 'MOD44A') THEN BEGIN
      ENDIF ELSE BEGIN
         CONTINUE
      ENDELSE
      ; the output file name
      OutputFile = ENVIDirectory+FileName

      ;
      ; Generate the parameters for CONVERT_MODIS_DATA
      ;
      ; INPUT FILE
      IN_FILE  = MODISFile
      ; OUT_ROOT
      OUT_PATH = ENVIDirectory
      ; OUTPUT FILE NAME
      OUT_ROOT = FileName
      ; OUTPUT SDS NAME: GD_NAME and SD_NAMES
      GetMODISCoeff, ProductType, GD_NAME = GD_NAME, SD_NAMES = SD_NAMES, DATA_TYPE = DT
      ;Output method schema :0 = Standard, 1 = Reprojected, 2 = Standard and reprojected
      OUT_METHOD = 0
      BACKGROUND = 0
      FILL_REPLACE_VALUE = 0

      ; Begin convert MODIS data to img format
      CONVERT_MODIS_DATA, IN_FILE=IN_FILE, GD_NAME=GD_NAME, SD_NAMES=SD_NAMES,$
                          OUT_METHOD=OUT_METHOD, BACKGROUND=BACKGROUND, /GRID,$
                          OUT_PATH=OUT_PATH,OUT_ROOT=OUT_ROOT,/HIGHER_PRODUCT,$
                          INTERP_METHOD=6,FILL_REPLACE_VALUE=FILL_REPLACE_VALUE

      MODISFile = OutputFile+'_Grid_2D.img'
      OutputFile = OutputFile +'.dat'
      ; Now begin to convert the HDF file format to ENVI file format
      ; Load the MODIS file
      ENVI_OPEN_FILE, MODISFile, R_FID = MODIS_FID
      ENVI_FILE_QUERY, MODIS_FID, NB = BandCount, DIMS=DIMS
      MODIS_Proj  = ENVI_GET_PROJECTION(FID=MODIS_FID, PIXEL_SIZE=PixSiz)
      ; Generate the parameters that need to process
      POS      = LINDGEN(BandCount)
      
      ;************************************************************************* 
      ;; For each product, process it individually
      ;*************************************************************************
      CASE ProductType OF
         ; [1] MOD09 500m
         'MOD09GA' OR 'MOD09GHK' : BEGIN
             OUT_BNAME= ['Band1','Band2','Band3','Band4','Band5','Band6','Band7']
             FID = [MODIS_FID,MODIS_FID,MODIS_FID,MODIS_FID,MODIS_FID,MODIS_FID]
             STACK_DIMS     = LONARR(5,BandCount)
             FOR j=0,BandCount-1 DO BEGIN
                 STACK_DIMS[0,j] = DIMS
             ENDFOR
             ENVI_DOIT, 'ENVI_LAYER_STACKING_DOIT',FID=FID,POS=POS,OUT_DT=DT,$
               DIMS=STACK_DIMS,OUT_PROJ=MODIS_Proj,OUT_PS=PixSiz,INTERP=0,$
               OUT_BNAME=OUT_BNAME,OUT_NAME=OutputFile, R_FID=R_FID
             ENVI_FILE_MNG, ID = R_FID, /REMOVE
          END
         'MOD09A1' OR 'MYD09A1': BEGIN
             OUT_BNAME= ['Band1','Band2','Band3','Band4','Band5','Band6','Band7',$
                         'Sun Zenith Angle','Day of Year']
             FID = [MODIS_FID,MODIS_FID,MODIS_FID,MODIS_FID,MODIS_FID,MODIS_FID,$
                    MODIS_FID,MODIS_FID,MODIS_FID]
             STACK_DIMS     = LONARR(5,BandCount)
             FOR j=0,BandCount-1 DO BEGIN
                 STACK_DIMS[0,j] = DIMS
             ENDFOR
             POS = [0,1,2,3,4,5,6,7,8]
             ENVI_DOIT, 'ENVI_LAYER_STACKING_DOIT',FID=FID,POS=POS,OUT_DT=DT,$
               DIMS=STACK_DIMS,OUT_PROJ=MODIS_Proj,OUT_PS=PixSiz,INTERP=0,$
               OUT_BNAME=OUT_BNAME,OUT_NAME=OutputFile, R_FID=R_FID
             ENVI_FILE_MNG, ID = R_FID, /REMOVE
         END
         'MYD09A1': BEGIN
             OUT_BNAME= ['Band1','Band2','Band3','Band4','Band5','Band6','Band7',$
                         'Sun Zenith Angle','Day of Year']
             FID = [MODIS_FID,MODIS_FID,MODIS_FID,MODIS_FID,MODIS_FID,MODIS_FID,$
                    MODIS_FID,MODIS_FID,MODIS_FID]
             STACK_DIMS     = LONARR(5,BandCount)
             FOR j=0,BandCount-1 DO BEGIN
                 STACK_DIMS[0,j] = DIMS
             ENDFOR
             POS = [0,1,2,3,4,5,6,7,8]
             ENVI_DOIT, 'ENVI_LAYER_STACKING_DOIT',FID=FID,POS=POS,OUT_DT=DT,$
               DIMS=STACK_DIMS,OUT_PROJ=MODIS_Proj,OUT_PS=PixSiz,INTERP=0,$
               OUT_BNAME=OUT_BNAME,OUT_NAME=OutputFile, R_FID=R_FID
             ENVI_FILE_MNG, ID = R_FID, /REMOVE
         END
         ; [2] MOD09 250m 
         'MOD09GQ' OR 'MOD09GQK': BEGIN
            OUT_BNAME= ['Band Red','Band NIR']
            FIDs     = LONARR(BandCount) + MODIS_FID
            ENVI_DOIT, 'CF_DOIT', FID=FIDs, POS=POS, DIMS=DIMS, REMOVE=1,$
                       OUT_DT=DT, OUT_BNAME=OUT_BNAME, OUT_NAME=OutputFile, $
                       R_FID = R_FID
         END
;         ; MOD15
;         'MOD15A1' OR 'MOD15A2' : BEGIN
;            
;         END
         ; MOD43 or MCD43
         'MCD43A3' OR 'MCD43B3': BEGIN
            POS = [2,3,0,1,4,5,6,7,8,9]
            OUT_BNAME = SD_NAMES
            FIDs      = LONARR(BandCount) + MODIS_FID
            ENVI_DOIT, 'CF_DOIT', FID=FIDs, POS=POS, DIMS=DIMS, REMOVE=1,$
                       OUT_DT=DT, OUT_BNAME=OUT_BNAME, OUT_NAME=OutputFile, $
                       R_FID = R_FID
         END
         ; Other datasets
         ELSE : BEGIN
           OUT_BNAME = SD_NAMES
           FIDs      = LONARR(BandCount) + MODIS_FID
           ENVI_DOIT, 'CF_DOIT', FID=FIDs, POS=POS, DIMS=DIMS, REMOVE=1,$
                       OUT_DT=DT, OUT_BNAME=OUT_BNAME, OUT_NAME=OutputFile, $
                       R_FID = R_FID
         END
      ENDCASE
      ENVI_FILE_MNG, ID = MODIS_FID, /REMOVE, /DELETE
   ENDFOR
   ; Close all the open Files
    FIDS = ENVI_GET_FILE_IDS()
    FOR i = 0, N_ELEMENTS(FIDS) - 1 DO BEGIN
        IF(FIDS[i] NE -1) THEN  ENVI_FILE_MNG, ID = FIDS[i], /REMOVE
    ENDFOR
END

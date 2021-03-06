
;******************************************************************************
;; $Id: envi45_config/Program/LakeMappingTools/SRTM_02DEMGridFilesMosaic.pro$
;;
;; Author: Junli LI, Geography Department of UCLA, Los Angeles, CA 90095
;+
;; NAME:
;;   SRTM_02DEMGridFilesMosaic
;;
;; PURPOSE:
;;   The procedure mosaic all the DEM grid files(1 degree* 1 degree ) 
;;
;; PARAMETERS:
;;   DEMGrid_DIR(in)    - input DEM grid file directory
;;
;;   DEM_MosaicFile(in) - input mosaic dem file path
;;
;; OUTPUTS:
;;
;; CALLING CUSTOM-DEFINED FUNCTIONS: 
;;
;; PROCEDURES OR FUNCTIONS CALLED:
;;
;; MODIFICATION HISTORY:
;;   Written by:  Junli LI, 2009/04/23 12:00 AM
;-
;******************************************************************************

PRO SRTM_02DEMGridFilesMosaic, DEMGrid_DIR, DEM_MosaicFile
   
    ; ############################################################
    DEMGrid_DIR = 'H:\TibetanPlateau_DEM1\'
    DEM_MosaicFile = 'H:\TibetanPlateau_DEM\SRTM_Tibet'
    ; ############################################################
    
    IF( FILE_TEST(DEMGrid_DIR, /DIRECTORY) EQ 0) THEN BEGIN
        MESSAGE, 'The given directory is invalid.'
        RETURN
    ENDIF
    ; Find SRTM files in the give directory
    SRTMFilePaths  = FILE_SEARCH(DEMGrid_DIR,'*.hdr', COUNT = FileCount,$
                                 /TEST_READ, /FULLY_QUALIFY_PATH)

    ;**************************************************************************
    ;
    ; [1] Load SRTM files and generate mosaic parameters
    ;
    ;**************************************************************************
 
    FIDS = LONARR(FileCount)      ; FIDs of SRTM files to be mosaiced
    POS  = LONARR(1,FileCount)    ; Pos
    DIMS = FLTARR(5,FileCount)    ; DIMS
    use_see_through = LONARR(1,FileCount)
    see_through_val = LONARR(1,FileCount)
    DATA_TYPE       = 2
    
    ; Open the DEM files
    FOR i=0L, FileCount-1 DO BEGIN
        SRTMFilePath= SRTMFilePaths[i]
        SRTMFilePath= STRMID(SRTMFilePath, 0, STRLEN(SRTMFilePath)-4)
         ; [2] Load the SRTM file and get the basic image information
         ENVI_OPEN_FILE, SRTMFilePath, R_FID = SRTM_FID
         IF(SRTM_FID EQ -1) THEN GOTO, EndPro
         FIDS[i]    = SRTM_FID
         use_see_through[*,i]=[1L]
         ; Width, Height, Band Count, dimensions, Data type of the image
         ENVI_FILE_QUERY, SRTM_FID, NS = iWidth, NL = iHeight, DIMS = iDIMS, $
                          DATA_TYPE = DATA_TYPE
         DIMS[*,i]  = iDIMS
         IF(i EQ 0) THEN BEGIN
            ; PixSize 
            Proj    = ENVI_GET_PROJECTION(FID = SRTM_FID,PIXEL_SIZE=PIXEL_SIZE)
         ENDIF
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
               OUT_NAME=DEM_MosaicFile, R_FID=MOSAIC_ID
               
    ENVI_FILE_MNG , ID=MOSAIC_ID, /REMOVE
  
EndPro:
   FOR j=0L,i-1 DO BEGIN
       ENVI_FILE_MNG, ID = FIDS[j], /REMOVE
   ENDFOR
   PRINT, 'Mosaic processing Finished'
END
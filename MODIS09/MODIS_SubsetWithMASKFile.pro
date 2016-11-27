
;*****************************************************************************
;;
;; $Id: /MidAsia_ETProject/MODIS_Parameters/MODIS_SubsetWithMASKFile.pro $
;;
;; Author: Junli LI, Geography Department of UCLA, Los Angeles, CA 90095
;+
;; NAME:
;;   MODIS_SubsetWithMASKFile
;;
;; PURPOSE:
;;   Subset the MODIS file with the spatial extent of the Mask File 
;; PARAMETERS:
;;
;;   MODIS_FILE (in) - The MODIS File need to be subset
;;
;;   MASKFILE(in)    - The MASK File with use its spatial extent to subset MODIS
;;
;;   PixSize(in)     - The output pixel resolution 
;;
;;   SubsetFile(in)  - The output subseted MODIS file
;;
;; MODIFICATION HISTORY:
;;   Written by:  Junli LI, 2009/12/31 11:40 PM
;-
;******************************************************************************

PRO MODIS_SubsetWithMASKFile,MODIS_FILE,MASKFILE,SubsetFile,PixSize
    
    ;***************************************************************************
    ; Here an example is given to show how to use the Lansat file to subset the 
    ; MODIS file
    ; Attention: all the input imagery should have the ENVI standard file format
    ; that means, *.hdr are ENVI header files and *.dat are the binary files
;    MODIS_File = 'D:\Test_Data\MODIS_FUSION\MOD09_A2000258_h24v04_004_FU.dat'
;    MASKFILE   = 'D:\Test_Data\p143r031_le7d20000917.dat'
;    SubsetFile = 'D:\Test_Data\MOD09_A2000258_h24v04_004_FU_REPJ.dat'
;    PixSize     = [250,250]
    ;***************************************************************************
    
    ENVI_OPEN_FILE,MODIS_FILE,R_FID=MODIS_FID
    ENVI_FILE_QUERY,MODIS_FID,NB=NB,DIMS=MODIS_DIMS,BNAMES=BNAMES,DATA_TYPE=DT
    
    ENVI_OPEN_FILE, MASKFILE,R_FID=MASK_FID
    ENVI_FILE_QUERY, MASK_FID,NS=NS_M,NL=NL_M,DIMS=MASK_DIMS
    Mapinfo = ENVI_GET_MAP_INFO(FID=MASK_FID)
    Proj    = ENVI_GET_PROJECTION(FID=MASK_FID, PIXEL_SIZE=PixSize)
    
    ; First convert the MODIS file to the projection of MASK file
    POS     = LINDGEN(NB)
    FileName   = STRMID(MODIS_FILE, 0, STRLEN(MODIS_FILE)-4)
    ProjectFile = FileName+'_proj'
    ENVI_CONVERT_FILE_MAP_PROJECTION, FID=MODIS_FID, POS=POS, DIMS=MODIS_DIMS, $
          O_PROJ=Proj, O_PIXEL_SIZE=PixSize, GRID=[100,100], WARP_METHOD=2,$
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
    DIMS  = [-1,MODIS_xPix[0],MODIS_xPix[1]-1,MODIS_yPix[0],MODIS_yPix[1]-1]
    ENVI_FILE_QUERY,Prj_FID,NB=NB,DIMS=Prj_DIMS,BNAMES=BNAMES
    POS = LINDGEN(NB)
    ENVI_OUTPUT_TO_EXTERNAL_FORMAT,FID=Prj_FID,DIMS=DIMS,POS=POS,$
          OUT_BNAME=BNAMES, /ENVI,OUT_NAME=SubsetFile
    ENVI_FILE_MNG, ID=Prj_FID,/REMOVE,/DELETE
    ; Close all the open Files
    FIDS = ENVI_GET_FILE_IDS()
    FOR i = 0, N_ELEMENTS(FIDS) - 1 DO BEGIN
        IF(FIDS[i] NE -1) THEN  ENVI_FILE_MNG, ID = FIDS[i], /REMOVE
    ENDFOR
END
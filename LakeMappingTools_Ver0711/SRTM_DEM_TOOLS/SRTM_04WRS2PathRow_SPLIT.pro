;*****************************************************************************
;; $Id: envi45_config/Program/LakeExtraction/SRTM_04WRS2PathRow_SPLIT.pro $
;;
;; Author: Junli LI, Geography Department of UCLA, Los Angeles, CA 90095
;+
;; NAME:
;;   SRTM_04WRS2PathRow_SPLIT
;;
;; PURPOSE:
;;   This procedure generate DEM subset files from the WRS Paht ROW info
;;   1) have a (Path, ROW) info
;;   2) find the feature in shape file - WRS_VectorFile, and get its spatial
;;      extent
;;   3) 
;;
;; PARAMETERS:
;;
;;   DEMFile(in)        - The DEM File with Lat/Long Projection
;;
;;   DEM_SubFile(in)    - The Subset file from DEM 
;;
;;   UTMZoneN(in)       - UTM Zone Number(Tibet are in range of UTM North
;;                        44 45 46, so the UTMZoneN is 44, 45, 46)
;;
;;   LatLong_RANGEs(in) - The ouput directory of lake vector files 
;;
;; MODIFICATION HISTORY:
;;
;;  Written by:  Junli LI, 2008/10/08 11:00 AM
;;  Modified  :  Junli LI, 2008/10/08 06:40 PM,
;-
;*****************************************************************************
PRO SRTM_04WRS2PathRow_SPLIT,SRTMFile,WRS_VectorFile,WRS_Path,WRS_Row,DEM_SubDIR
    
    ;;########################################################################
    ;;************************* For procedure test *************************** 
     SRTMFile       = 'D:\SRTM_CentralAsia\CentralAsia_SRTM.dat'
     WRS_VectorFile = 'E:\ENVI_SETTINGS_JLI\IDL\LakeMappingTools_Ver0711\Data\WRS2_Landsat_World.shp'
     WRS_Path       = [157,157,158,158,159,159]
     WRS_Row        = [ 34, 35, 34, 35, 34, 35]
;     WRS_Path       = [135,135,135,136,136,136,136,136,136,136,$
;                       137,137,137,137,137,137,137,137,138,138,$
;                       138,138,138,138,138,138,138,139,139,139,$
;                       139,139,139,139,139,139,140,140,140,140,$
;                       140,140,140,140,140,141,141,141,141,141,$
;                       141,141,141,141,141,141,142,142,142,142]
;     WRS_Row        = [ 30, 31, 32, 29, 30, 31, 32, 33, 34, 35,$
;                        28, 29, 30, 31, 32, 33, 34, 35, 27, 28,$
;                        29, 30, 31, 32, 33, 34, 35, 27, 28, 29,$
;                        30, 31, 32, 33, 34, 35, 27, 28, 29, 30,$
;                        31, 32, 33, 34, 35, 25, 26, 27, 28, 29,$
;                        30, 31, 32, 33, 34, 35, 26, 27, 28, 29]
     
     DEM_SubDIR     = 'D:\SRTM_CentralAsia\WRS2\'
    ;************************* For procedure test *************************** 
    ; ########################################################################
    
    ; 
    ;*************************************************************************
    ;
    ; (1) Load Shape file - WRS_VectorFile to get attribute 'WRSPR', this
    ;     attribute help us to find the spatial feature of pPathrRow(i.e p001r021)
    ;
    ;*************************************************************************
    ; Open a shapefile
    WRS_FID = OBJ_NEW('IDLffShape', WRS_VectorFile, /UPDATE)
    ; Get the number of entities so we can parse through them.
    WRS_FID->GetProperty, N_ENTITIES=WRSEntCount,ATTRIBUTE_NAMES=Attr_NAMES
    ; Get the info for all attribute. 
    idx = WHERE(Attr_Names EQ 'WRSPR',nCount)
    IF(nCount LE 0) THEN BEGIN
        OBJ_DESTROY, WRS_FID
        RETURN
    ENDIF
    Attr = WRS_FID->GetAttributes(/ALL) 
    sPathRow = Attr.ATTRIBUTE_0
    
    ;*************************************************************************
    ;
    ; (2) Find the spatial extent from shape features by each given (Path, Row)  
    ;
    ;*************************************************************************
    ; Load the SRTM file
    ENVI_OPEN_FILE, SRTMFile, R_FID = SRTM_FID
    ENVI_FILE_QUERY, SRTM_FID, NS = NS, NL = NL
    ; input projection from the DEM file
    iProj = ENVI_GET_PROJECTION(FID=SRTM_FID,PIXEL_SIZE=PS)
    
    nCount = SIZE(WRS_Path, /dimension)
    FOR i=0,nCount[0]-1 DO BEGIN
      ; Find the Feature that connect with the (Path,Row)
      iPathRow = PUB_GetPathRowID(WRS_Path[i],WRS_Row[i])
      idx = WHERE(sPathRow EQ iPathRow, nCount)
      IF(nCount LE 0) THEN CONTINUE
      ; Generate the output PathRow DEM File
      DEMFile = 'DEM_P'+STRMID(iPathRow,0,3)+'R'+STRMID(iPathRow,3,3)
      DEMFile = DEM_SubDIR + DEMFile
      ; Get the feature index
      idx_PathRow = idx[0]
      ; Get the central Point of (Path ROW),
      ; CTR_LON and CTR_LAT is the 5th and 6th attribute
      attr = WRS_FID->GetAttributes(idx_PathRow)
      CtrLon = attr.ATTRIBUTE_5
      CtrLat = attr.ATTRIBUTE_6 
      ; Create the output projcet accordinate the center point of the WRS
      UTM_Prj = PUB_CreateUTMProjFromLatLon(CtrLat, CtrLon)
        
      ; Get the spatial extent of one WRS unit
      ent      = WRS_FID->GetEntity(idx_PathRow)
      xMap     =(*ent.vertices)[0, *]
      yMap     =(*ent.vertices)[1, *]
      
      xMap_min = MIN(xMap)-0.20
      yMap_min = MIN(yMap)-0.20
      xMap_max = MAX(xMap)+0.20
      yMap_max = MAX(yMap)+0.20
      xMap1    = [xMap_min, xMap_max, xMap_max, xMap_min, xMap_min]
      yMap1    = [yMap_min, yMap_min, yMap_max, yMap_max, yMap_min]
      ;Convert the map coordinates to pixel coordinates of the SRTM image
      ENVI_CONVERT_FILE_COORDINATES, SRTM_FID, xPix, yPix, xMap1, yMap1
      ; create the DIMS
      xPix   = LONG(xPix)
      yPix   = LONG(yPix)
      DIMS = [-1,MIN(xPix),MAX(xPix),MIN(yPix),MAX(yPix)]
      ;
      ENVI_CONVERT_FILE_MAP_PROJECTION, FID = SRTM_FID, POS=0, DIMS = DIMS,$
               O_PROJ = UTM_Prj, O_PIXEL_SIZE = [90,90], GRID = [25,25], $
               OUT_NAME=DEMFile, WARP_METHOD=2, RESAMPLING=1, BACKGROUND=0,$
               R_FID=tmp_FID
    
     ENVI_FILE_MNG, ID = tmp_FID, /REMOVE
      
    ENDFOR
    
     ENVI_FILE_MNG, ID = SRTM_FID, /REMOVE
    ; Close the SHAPE FILE
    OBJ_DESTROY, WRS_FID
    
END
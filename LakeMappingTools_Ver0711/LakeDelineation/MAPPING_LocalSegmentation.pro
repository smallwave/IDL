
;*****************************************************************************
;; $Id: envi45_config/Program/LakeMappingTool/MAPPING_LocalSegmentation.pro $
;;
;; Author: Junli LI, Geography Department of UCLA, Los Angeles, CA 90095
;+
;; NAME:
;;   MAPPING_LocalSegmentation
;;
;; PURPOSE:
;;   The procedure performs water segementation in local scale based on global
;;   segmentation result. Firstly, it find the region buffer and calculates 
;;   the segmentation threshold in the buffer. Secondly, after segmentation is
;;   processed, then compare region's areas and threshold. Selected the ones 
;;   changes greately and perform the segementation on these region again,until
;;   all the regions change little 
;;
;; PARAMETERS:
;;   WaterMask(in)   -  global segmentation result.
;;   ImageMask(in)   -  the valid region of image
;;   NDWI(in)        -  Normal Difference Water Index(ImageMask applied)
;;   Global_T(in)    -  the global segmentation threshold
;;   DEM(in)         -  the dem of the image
;;   WaterRegion(out)-  the output lake regions with the label
;;   RegionT(out)    -  the threshold of local segmentation
;;   WaterElev(out)  -  the elevation of each lake region
;;   bHalfLake(out)  -  whether regions intersect with image boundary
;;
;; OUTPUTS:
;;
;;   the final result of the segmentation and water properity of each lake
;;
;; CALLING CUSTOM-DEFINED FUNCTIONS:  WaterExtraction
;;
;; PROCEDURES OR FUNCTIONS CALLED:   
;;    
;;
;; MODIFICATION HISTORY:
;;  Written by:  Junli LI, 2008/04/07 12:30 PM
;;  Modified by:  Junli LI, 2008/10/08 12:00 AM
;-
;*****************************************************************************

PRO MAPPING_LocalSegmentation, WaterMask,ImageMask,NDWI,DEM,ShadeBand,SlopeBand, $
      Band4,Global_T,WATERREGION=WaterRegion,REGIONT=RegionT,REGIONELEV=LakeElev,$
      HALFLAKE=bHalfLake                     

   COMMON SHARE
   ; Get the size of the image to be processed
   nSize           = size(WaterMask)
   Width           = nSize[1]
   Height          = nSize[2]

   ;***************************************************************************
   ; 1) Perform local segmentation by region
   ;***************************************************************************
   
   WaterRegion     = LABEL_REGION( WaterMask, /ULONG )
   ; New variables to save the buffer of each region
   RegionBuf       = LONG(WaterRegion)
   index           = WHERE(ImageMask EQ 0, nCount)
   IF(nCount GT 0) THEN BEGIN
      RegionBuf[index]= -1
   END
   ; Variable to save the region segmentation thresholds
   WaterRegion_T   = FLTARR(Width,Height)
   WaterRegion_T(WHERE(WaterRegion GT 0)) = Global_T
   ; For each region, find new segmentation value, and refresh the water region
   nTimes = 1
   print, 'Begin Local Water Segmentaion Iteration:'
   print, 'Iteration ' +  STRING(nTimes)
   MAPPING_LocalSegmentationByRegion, WaterRegion, RegionBuf, NDWI, WaterRegion_T
   WaterRegion = WaterRegion * ImageMask
   
   ;***************************************************************************
   ; 2) Detect the regions which are conjoint with each other
   ;***************************************************************************
   
   ConjointRegionCount = 0L
   MAPPING_DetectConjointRegion, WaterRegion, WaterRegion_T, RegionBuf,$
     REGCOUNT =RegionCount, ConjointRegion=ConjointRegion, ConjointRegionCount
   nWaterPixCount      = TOTAL(WaterRegion NE 0)
   Print, 'Total WaterPixels: '+STRING(nWaterPixCount)
   Print, 'Total Lake Numbers: '+STRING(RegionCount)
   Print, 'Lakes need to be redo again:' + STRING(ConjointRegionCount)

   ;***************************************************************************
   ; 3) Find and combine the conjoint regions and perform segementation on them,
   ;    until there are no conjoint regions  
   ;***************************************************************************
   nTimes = nTimes + 1
   WHILE (ConjointRegionCount GT 1 AND nTimes LT 10) DO BEGIN
      Print, 'Iteration ' + STRING(nTimes)
      MAPPING_SegmentConjointRegion, WaterRegion, WaterRegion_T, RegionBuf,  $
                                     NDWI, ConjointRegion
      MAPPING_DetectConjointRegion, WaterRegion, WaterRegion_T, RegionBuf, $
        REGCOUNT=RegionCount,ConjointRegion=ConjointRegion,ConjointRegionCount
      nWaterPixCount   = TOTAL(WaterRegion NE 0)
      Print, 'Total WaterPixels: '+STRING(nWaterPixCount)
      Print, 'Total Lake Numbers: '+STRING(RegionCount)
      Print, 'Lakes need to be redo again:' + STRING(ConjointRegionCount)
      nTimes    = nTimes + 1
   ENDWHILE
   ; then peform post segmentation, remove the small regions and regions with 
   ; high slopes
   WaterRegion = WaterRegion * ImageMask
   LocalLakeMask= WaterRegion NE 0
   
   MAPPING_PreSegmentation,LocalLakeMask,ImageMask,Band4,ShadeBand,SlopeBand
   WaterRegion  = LABEL_REGION(TEMPORARY(LocalLakeMask), /ULONG)
   
   ;***************************************************************************
   ;
   ; 4) Get the Attributes of the regions
   ;
   ;***************************************************************************
   nRegionCount = MAX(WaterRegion)+1
   RegionT      = FLTARR(nRegionCount)
   bHalfLake    = BYTARR(nRegionCount)
   LakeElev     = LONARR(nRegionCount)
   MAPPING_RegionAttribute, WaterRegion,WaterRegion_T,ImageMask,DEM,RegionT, $
                            LakeElev, bHalfLake
;   RegionT      = RegionT[1L:nRegionCount-1]
;   bHalfLake    = bHalfLake[1L:nRegionCount-1]
;   LakeElev     = LakeElev[1L:nRegionCount-1]
   
END
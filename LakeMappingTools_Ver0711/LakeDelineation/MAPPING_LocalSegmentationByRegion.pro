
;*****************************************************************************
;; $Id: envi45_config/Program/LakeMappingTools/MAPPING_LocalSegmentationByRegion $
;;
;; Author: Junli LI, Geography Department of UCLA, Los Angeles, CA 90095
;+
;; NAME:
;;   LocalSegmentationByRegion
;;
;; PURPOSE:
;;   This procedure finds the segementation value for each region, 
;;   and get the exact water extent.
;;
;; PARAMETERS:
;;   WaterRegion(in-out)- The labeled region from global segmentation
;;   RegionBuf(in)      - The same as the WaterRegion, temporary use
;;   NDWI(in)           - The NDWI of the Landsat image
;;   WaterRegion_T(Out) - New region's threshold 
;;
;; OUTPUTS:
;;
;;   the final result of the segmentation and water properity of each lake
;;
;; CALLING CUSTOM-DEFINED FUNCTIONS:  WaterExtraction
;;
;; PROCEDURES OR FUNCTIONS CALLED:   
;;
;; MODIFICATION HISTORY:
;;  Written by:  Junli LI, 2008/04/07 12:30 PM
;;  Modified by:  Junli LI, 2008/10/08 12:00 AM
;-
;*****************************************************************************

PRO MAPPING_LocalSegmentationByRegion, WaterRegion, RegionBuf, NDWI, WaterRegion_T

   ; Get the size of the image to be processed
   nSize           = size(WaterRegion)
   Width           = nSize[1]
   Height          = nSize[2]

   ; AS only water pixels are used during the processing, get the index 
   ; of water in order to be more efficient.
   NonZeroIndex    = WHERE(WaterRegion GT 0, PixCount)
   NonZeroRegion   = WaterRegion(NonZeroIndex)
   ; Sort the index
   SortIndex       = SORT(NonZeroRegion, /L64)
   NonZeroIndex    = NonZeroIndex(SortIndex)
   NonZeroRegion   = NonZeroRegion(SortIndex)

   ; Init loop varialbes
   nFrom           = 0L;
   nTo             = nFrom;
   nRegionID       = NonZeroRegion[0]

   ; Loop procedures, local processing by labeled regions
   FOR i = 0L, PixCount-1 DO BEGIN

      
      ;    [1] Find all of the pixels of each region
      IF(NonZeroRegion[i] EQ nRegionID) THEN BEGIN
         nTo       = i
      ENDIF ELSE BEGIN
         ; [2] Get one region, and perform the segmentation in its buffer area
         RegionCount = nTo-nFrom+1       ; region's pixel count
         RegionIndex = NonZeroIndex[nFrom:nTo]
         Region_T    = WaterRegion_T[NonZeroIndex[nTo]]
         bRedo       = 1
         nIteration = 0
         WHILE(bRedo EQ 1 AND nIteration LT 20) DO BEGIN

              MAPPING_RegionSegmentation, WaterRegion, WaterRegion_T, RegionBuf, $
                      NDWI, Width, Height, RegionIndex, RegionCount,Region_T,$
                      NewRegionIndex, NewRegionCount,NewRegion_T
              IF(NewRegionCount EQ 0 OR NewRegion_T EQ 1.0) THEN BREAK
              ; Whether the region changes much, if it does, process again
              ChangedPixels   = ABS(NewRegionCount-RegionCount)
              fChangePercent  = FLOAT(ChangedPixels*1.0/RegionCount)
              dT              = ABS(NewRegion_T - Region_T)

              bRedo = 0
              IF(RegionCount LT 100) THEN BEGIN
                 IF(fChangePercent GT 0.20 AND ChangedPixels GT 10L OR dT GT 0.10) $
                 THEN  bRedo = 1
              ENDIF ELSE BEGIN
                 IF(fChangePercent GT 0.05 OR dT GT 0.05) THEN  bRedo = 1
              ENDELSE

              RegionIndex = NewRegionIndex
              RegionCount = NewRegionCount
              Region_T    = NewRegion_T
              nIteration  = nIteration+1

         ENDWHILE

         ; [3] switch to the next region
         nRegionID = NonZeroRegion[i]
         nFrom     = i
         nTo       = i
      ENDELSE

   ENDFOR

END
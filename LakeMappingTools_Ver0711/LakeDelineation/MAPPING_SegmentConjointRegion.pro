;******************************************************************************
;;
;; $Id: envi45_config/Program/LakeMappingTools/MAPPING_SegmentConjointRegion.pro
;;
;; Author: Junli LI, Geography Department of UCLA, Los Angeles, CA 90095
;+
;; NAME:
;;    MAPPING_SegmentConjointRegion
;;
;; PURPOSE:
;;    This Function get the conjoint region in the local segmentation results
;;
;; PARAMETERS:
;;   LakeMask(in)    - the global lake segmentation result, 0 - land, 1 - water
;;
;;   RegionIndex     - the index of the region pixel
;;
;;
;; CALLING CUSTOM-DEFINED FUNCTIONS:  
;;      MAPPING_LocalSegmentation
;; PROCEDURES OR FUNCTIONS CALLED:  
;;      MAPPING_RegionSegmentation 
;;
;; MODIFICATION HISTORY:
;;   Written by:  Junli LI, 2008/05/04 12:30 PM
;-
;******************************************************************************

PRO MAPPING_SegmentConjointRegion, WaterRegion, WaterRegion_T, RegionBuf, NDWI,$
             ConjointRegion


   ; Get the size of the image to be processed
   nSize           = size(WaterRegion)
   Width           = nSize[1]
   Height          = nSize[2]

   nSize           = size(ConjointRegion)
   ConJointCount   = nSize[1]

   ; Get the nonzero index of the Laskimage
   NonZeroIndex    = WHERE(WaterRegion NE 0, WaterCount)
   NonZeroRegion   = WaterRegion(NonZeroIndex)
   ; Sort the index
   SortIndex       = SORT(NonZeroRegion, /L64)
   ; As only nonezero pixels make sense during the processing, we extract them from
   ; WaterMask and NDWI and store them as one dimension array
   NonZeroIndex    = NonZeroIndex(SortIndex)
   NonZeroRegion   = NonZeroRegion(SortIndex)

   ; Init loop varialbes
   nFrom             = 0L
   nTo               = nFrom
   RegionI           = 0L
   nRegionID         = ConjointRegion[RegionI]

   ; Loop procedures
   FOR i = 0L, WaterCount-1 DO BEGIN

      ; if the region ID of the current pixel is the same as nRegionID, then go ahead
      IF(NonZeroRegion[i] EQ nRegionID) THEN BEGIN
         nFrom       = i
         nTo         = i
         FOR j=i+1,WaterCount-1 DO BEGIN
             IF(NonZeroRegion[j] NE nRegionID) THEN BREAK
             nTo     = j
         ENDFOR
        
         RegionIndex = NonZeroIndex[nFrom:nTo]
         RegionCount = nTo-nFrom+1                 ; region's pixel count
         Region_T    = WaterRegion_T[NonZeroIndex[nTo]]
         bRedo       = 1
         nIteration = 0
         
         WHILE(bRedo EQ 1 AND nIteration LT 10) DO BEGIN

              MAPPING_RegionSegmentation,WaterRegion,WaterRegion_T,RegionBuf,$
                  NDWI, Width, Height,RegionIndex,RegionCount,Region_T,$
                  NewRegionIndex, NewRegionCount, NewRegion_T
              IF(NewRegionCount EQ 0 OR NewRegion_T EQ 1.0) THEN BREAK
              ; if the region changes much, process it to process again
              ChangedPixels   = ABS(NewRegionCount-RegionCount)
              fChangePercent  = FLOAT(ChangedPixels*1.0/RegionCount)
              dT              = ABS(NewRegion_T - Region_T)

              bRedo = 0
              IF(RegionCount LT 100) THEN BEGIN
                 IF(fChangePercent GT 0.20 AND (ChangedPixels GT 10L OR dT GT 0.10)) $
                 THEN bRedo = 1
              ENDIF ELSE BEGIN
                 IF(fChangePercent GT 0.05 OR dT GT 0.05) THEN  bRedo = 1
              ENDELSE

              RegionIndex = NewRegionIndex
              RegionCount = NewRegionCount
              Region_T    = NewRegion_T
              nIteration  = nIteration+1
         ENDWHILE

         RegionI     = RegionI+1
         IF(RegionI EQ ConJointCount) THEN BREAK
         nRegionID   = ConjointRegion[RegionI]
         i = j
      ENDIF

   ENDFOR

END

;******************************************************************************
;; $Id: envi45_config/Program/LakeMappingTools/MAPPING_DetectConjointRegion.pro$
;;
;; Author: Junli LI, Geography Department of UCLA, Los Angeles, CA 90095
;+
;; NAME:
;;   MAPPING_DetectConjointRegion
;;
;; PURPOSE:
;;   This Function get the conjoint regions of the local segmentation results
;;
;; PARAMETERS:
;;   WaterRegion(in)    - Water regions
;;   WaterRegion_T(in)  - Segmentation threshold for each water region
;;   RegionBuf          - Copy of the WaterRegion, just used as buffer analysis
;;                        of each region
;;   RegionCount        - Numbers of all the regions
;;   ConjointRegion     - The loation index of the conjiont regions
;;   ConjointRegionCount- Numbers of the conjiont regions
;;
;; OUTPUTS:
;;   Conjoint region indexes and Conjoint region counts
;;
;; CALLING CUSTOM-DEFINED FUNCTIONS:  LocalSegmentation
;;
;; PROCEDURES OR FUNCTIONS CALLED:  
;;     MAPPING_RemoveSmallRegions
;;
;; MODIFICATION HISTORY:
;;  Written by:  Junli LI, 2008/05/04 12:30 PM
;;  Written by:  Junli LI, 2008/10/08 12:00 AM
;-
;******************************************************************************

PRO MAPPING_DetectConjointRegion, WaterRegion, WaterRegion_T, RegionBuf, $
                          REGCOUNT=RegionCount, ConjointRegion=ConjointRegion,$
                          ConjointRegionCount

   COMMON SHARE

   ; remove small regions
   WaterMask       = WaterRegion GT 0
   WaterRegion     = LABEL_REGION(WaterMask, /ULONG)
   MAPPING_RemoveSmallRegions, WaterRegion, WaterRegion_T, SMALLREGION
   ;
   index           = WHERE(RegionBuf NE -1)
   RegionBuf[index]= WaterRegion[index]

   ; Get the nonzero index of the Laskimage
   NonZeroIndex    = WHERE(WaterRegion NE 0, WaterCount)
   NonZeroRegion   = WaterRegion(NonZeroIndex)
   ; Sort the index
   SortIndex       = SORT(NonZeroRegion, /L64)
   ; As only nonezero pixels make sense during the processing, we extract
   ; them from WaterMask and NDWI and store them as one dimension array
   NonZeroIndex    = NonZeroIndex(SortIndex)
   NonZeroRegion   = NonZeroRegion(SortIndex)

   RegionArray     = LONARR(WaterCount)
   ArrayCount      = 0

   ; Init loop varialbes
   nFrom           = 0L;
   nTo             = nFrom;
   nRegionID       = NonZeroRegion[0]
   RegionCount     = 0

   ; Loop procedures
   FOR i = 0L, WaterCount-1 DO BEGIN

      IF(NonZeroRegion[i] EQ nRegionID) THEN BEGIN
         nTo       = i
      ENDIF ELSE BEGIN
         RegionCount = RegionCount+1
         nPixels   = nTo-nFrom+1
         index     = NonZeroIndex[nFrom:nTo]
         ; judge by threshold difference
         T         = WaterRegion_T[index]
         newIndex  = WHERE(T GT 0, nNewCount)
         IF(nNewCount LE 0) THEN bT = 0 ELSE BEGIN
            T      = T[newIndex]
            bT     = (MIN(T) EQ MAX(T)) ? 0:1
         ENDELSE
         IF(bT) THEN BEGIN
            RegionArray[ArrayCount] = nRegionID
            ArrayCount              = ArrayCount + 1
            WaterRegion_T[index]    = MIN(T)
         END
         ; reset the nFrom, nTo and the new region label ID
         nRegionID = NonZeroRegion[i]
         nFrom     = i
         nTo       = i
      ENDELSE

   ENDFOR

   ; Return
   IF(ArrayCount GT 0) THEN BEGIN
      RegionArray    = RegionArray[0:ArrayCount-1]
      ConjointRegion = TEMPORARY(RegionArray)
   ENDIF
   ConjointRegionCount = ArrayCount

END
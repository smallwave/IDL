
;*****************************************************************************
;; $Id: envi45_config/Program/LakeMappingTools/MAPPING_RemoveSmallRegions.pro$
;;
;; Author: Junli LI, Geography Department of UCLA, Los Angeles, CA 90095
;+
;; NAME:
;;   MAPPING_RemoveSmallRegions
;;
;; PURPOSE:
;;  This procedure remove the regions whose pixels are less than SMALL_REGION
;;
;; PARAMETERS:
;;    ImageRegions(in) - the labeled lake regions
;;    Region_T(in)     - the threshold layer of the water region
;;    SMALL_REGION(in) - Region pixels below SMALL_REGION are removed off
;;
;; OUTPUTS:
;;
;; CALLING CUSTOM-DEFINED FUNCTIONS:  DetectConjointRegion
;;
;; PROCEDURES OR FUNCTIONS CALLED:   
;;
;; MODIFICATION HISTORY:
;;   Written by:  Junli LI, 2008/05/24 07:30 PM
;;  Modified by:  Junli LI, 2008/10/08 12:00 AM
;-
;******************************************************************************

PRO MAPPING_RemoveSmallRegions, ImageRegions, Region_T, SMALL_REGION

   ; get nozero index of the region
   NoZeroIndex  = WHERE(ImageRegions NE 0, RegionCount)
   NoZeroRegion = ImageRegions(NoZeroIndex)
   ; sort the index
   SortIndex    = SORT(NoZeroRegion, /L64)
   NoZeroIndex  = NoZeroIndex(SortIndex)
   NoZeroRegion = NoZeroRegion(SortIndex)

   nFrom        = 0L
   nTo          = nFrom
   nRegionID    = NoZeroRegion[0]
   FOR i = 0L, RegionCount-1 DO BEGIN

       IF(NoZeroRegion[i] EQ nRegionID) THEN  BEGIN
          nTo     = i
       ENDIF ELSE BEGIN
         nPixels  = nTo - nFrom + 1

         ; remove small regions
         IF(nPixels LE SMALL_REGION) THEN BEGIN
            ImageRegions[NoZeroIndex[nFrom:nTo]] = 0
            Region_T[NoZeroIndex[nFrom:nTo]]     = 0
         ENDIF

         ; reset the nFrom, nTo and the new region label ID
         nRegionID= NoZeroRegion[i]
         nFrom    = i
         nTo      = i
      ENDELSE

   ENDFOR

END
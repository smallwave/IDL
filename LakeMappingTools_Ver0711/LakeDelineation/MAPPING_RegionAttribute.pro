;*****************************************************************************
;; $Id: envi45_config/Program/LakeExtraction/MAPPING_RegionAttribute.pro $
;;
;; Author: Junli LI, Geography Department of UCLA, Los Angeles, CA 90095
;+
;; NAME:
;;   MAPPING_RegionAttribute
;;
;; PURPOSE:
;;   This procedure get the attribute of extraction region, such threshold, 
;;   elevation and wheter it's halflake
;;
;; PARAMETERS:
;;   WaterRegion(in)- the global lake segmentation result, 0 - land, 1 - water
;;   Local_T(in)    - image layer which stores the region's threshold 
;;   ImageMask(in)  - the valid image extent with values
;;   DEM(in)       - the DEM data corresponding to the landsat file
;;   RegionT(out)  - Region threshold
;;   RegionElev(out)- Region elevation
;;   bHalfLake(out) - Indicates the region is a halflake
;;
;; OUTPUTS:
;;
;;   the final result of the segmentation and water properity of each lake
;;
;; CALLING CUSTOM-DEFINED FUNCTIONS: 
;;    MAPPING_LocalSegmentation
;; PROCEDURES OR FUNCTIONS CALLED:   
;;    MAPPING_IsHalfLake
;; MODIFICATION HISTORY:
;;   Written by:  Junli LI, 2008/05/24 07:30 PM
;;  Modified by:  Junli LI, 2008/10/08 12:00 AM
;-
;******************************************************************************

PRO MAPPING_RegionAttribute, WaterRegion, Local_T, ImageMask, DEM, RegionT, $
                             RegionElev, bHalfLake

   ; Whether DEM is used or not
   bHaveDEM        = ( N_Elements(DEM) EQ 0 ) ? 0 : 1

   nSize           = size(ImageMask)
   Width           = nSize[1]
   Height          = nSize[2]

   RegionCount     = MAX(WaterRegion)
   ; Get the nonzero index of the Laskimage
   NonZeroIndex    = WHERE(WaterRegion NE 0, WaterCount)
   NonZeroRegion   = WaterRegion(NonZeroIndex)
   ; Sort the index
   SortIndex       = SORT(NonZeroRegion, /L64)
   ; As only nonezero pixels make sense during the processing, we extract them
   ;  from WaterMask and NDWI and store them as one dimension array
   NonZeroIndex    = NonZeroIndex(SortIndex)
   NonZeroRegion   = NonZeroRegion(SortIndex)

   ; Init loop varialbes
   nFrom           = 0L;
   nTo             = nFrom;
   nRegionID       = NonZeroRegion[0]
   ; Loop procedures
   FOR i = 0L, WaterCount-1 DO BEGIN
      
      IF(NonZeroRegion[i] EQ nRegionID) THEN BEGIN
         nTo       = i
      ENDIF ELSE BEGIN

         nPixels               = nTo-nFrom+1L
         RegionIndex           = NonZeroIndex[nFrom:nTo]
         RegionT[nRegionID]    = MAX(Local_T[RegionIndex])
         RegionElev[nRegionID] = (bHaveDEM EQ 1) ? MEAN(DEM[RegionIndex]) : 0L
         bHalfLake[nRegionID]  = MAPPING_IsHalfLake(ImageMask,RegionIndex, $
                                                     nPixels,Width, Height)
         ; reset the nFrom, nTo and the new region label ID
         nRegionID    = NonZeroRegion[i]
         nFrom        = i
         nTo          = i
      ENDELSE
   ENDFOR
   ; the last one
   nPixels               = nTo-nFrom+1L
   RegionIndex           = NonZeroIndex[nFrom:nTo]
   RegionT[nRegionID]    = MAX(Local_T[RegionIndex])
   RegionElev[nRegionID] = (bHaveDEM EQ 1) ? MEAN(DEM[RegionIndex]) : 0L
   bHalfLake[nRegionID]  = MAPPING_IsHalfLake(ImageMask,RegionIndex, nPixels,$
                                      Width, Height)

END
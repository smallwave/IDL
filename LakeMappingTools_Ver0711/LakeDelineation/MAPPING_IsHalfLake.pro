
;******************************************************************************
;; $Id: envi45_config/Program/LakeMappingTools/MAPPING_IsHalfLake.pro $
;;
;; Author: Junli LI, Geography Department of UCLA, Los Angeles, CA 90095
;+
;; NAME:
;;   MAPPING_IsHalfLake
;;
;; PURPOSE:
;;    This function get the information whether the lake is on the boundary of 
;;    the image. if it's a lake then return 1, else return 0.
;;
;; PARAMETERS:
;;   ImageMask(in)    - the water segmentation result, 0 - land, 1 - water
;;   RegionIndex(in)  - the index of the region to be processed
;;   RegionCount(in)  - the total pixels of the region
;;   Width(in)        - Image Width
;;   Height(in)       - Image Height
;;
;; OUTPUTS:
;;   1 - Half Lake (on the boundary of the water)  0 - Whole Lake  
;;
;; CALLING CUSTOM-DEFINED FUNCTIONS:  RegionAttribute
;;
;; PROCEDURES OR FUNCTIONS CALLED:  
;;
;; MODIFICATION HISTORY:
;;  Written  by:  Junli LI, 2008/05/04 12:30 PM
;;  Modified by:  Junli LI, 2008/05/24 06:30 PM
;;  Modified by:  Junli LI, 2008/10/08 12:00 AM
;-
;******************************************************************************

Function MAPPING_IsHalfLake, ImageMask, RegionIndex, RegionCount, Width, Height

   FOR i=0L, RegionCount-1 DO BEGIN

       index = RegionIndex[i]
       Y     = UINT( index / Width)
       X     = UINT( index - Y * Width)
       ; (1) if one pixel of the region is on the edge of the image
       IF( (Y EQ Height-1) OR (Y EQ 0) OR (X EQ 0) OR (X EQ Width-1) ) $
       THEN RETURN, 1

       ; (2) analyze it's 4-neighborhood
       Neighbor4  = [index - Width, index - 1, index + 1, index + Width]
       ;if one pixel in it's 4-neighborhood in the image, then it's a half lake
       FOR j=0, 3 DO BEGIN
           IF(ImageMask[Neighbor4[j]] EQ 0) THEN RETURN, 1
       ENDFOR

   ENDFOR

   ; (3) or they are completely in the image
   RETURN, 0

END
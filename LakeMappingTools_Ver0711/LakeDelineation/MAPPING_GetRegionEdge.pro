
;*****************************************************************************
;; $Id: envi45_config/Program/LakeMappingTool/MAPPING_GetRegionEdge.pro $
;;
;; Author: Junli LI, Geography Department of UCLA, Los Angeles, CA 90095
;+
;; NAME:
;;   MAPPING_GetRegionEdge
;;
;; PURPOSE:
;;   This procedure finds the outline of the given region
;;
;; PARAMETERS:
;;   WaterRegion(in)    - The labeled region from the water segmentation result
;;   RegionIndex(in)    - indexes of the region to be processed
;;   Width, Height(in)  - Widh and Height of the image
;;   EdgePoints(out)    - the edge point of the region
;;   EdgePixelCount(out)- the point pixel number of the region edge
;;
;; OUTPUTS:
;;   the edge point index of the given region
;;
;; CALLING CUSTOM-DEFINED FUNCTIONS:  WaterExtraction
;;
;; MODIFICATION HISTORY:
;;
;;  Written by:  Junli LI, 2008/05/24 07:00 PM
;;  Modified by: Junli LI, 2008/11/05 12:00 AM
;;  
;-
;*****************************************************************************

PRO MAPPING_GetRegionEdge, WaterRegion, RegionIndex, Width, Height, $
            EDGEPOINTS = EdgePoints, EDGEPOINTCOUNT = EdgePixelCount

   ; Get the size of the region
   RegSiz          = SIZE(RegionIndex)
   RegionCount     = RegSiz[1]
   ; Get the label ID of the region
   RegionID        = WaterRegion[RegionIndex[0]]

   ; new the variables to store the results
   ;     RegionEdge     : the edge points of the region's edge
   RegionEdge     = LONARR(RegionCount*4)
   ;     EdgePointCount : the point number of the region's edge
   EdgePointCount = 0L

   FOR i=0L,RegionCount-1 DO BEGIN

       index      = RegionIndex[i]
       Y          = UINT( index / Width)
       X          = UINT( index - Y * Width)
       ; the out boundary of the image
       IF((Y EQ Height -1) OR (Y EQ 0) OR (X EQ 0) OR (X EQ Width-1)) THEN BEGIN
           
           RegionEdge[EdgePointCount]    = index
           EdgePointCount                = EdgePointCount + 1
       ENDIF ELSE BEGIN
           ; expand it's 4-neighbor to find whether it's outside the Imagemask
          IF(WaterRegion[index-1] EQ 0 OR WaterRegion[index+1] EQ 0 OR $
             WaterRegion[index-Width] EQ 0 OR WaterRegion[index+Width] EQ 0) $
          THEN BEGIN
              RegionEdge[EdgePointCount] = index
              EdgePointCount             = EdgePointCount + 1
          ENDIF
       ENDELSE

   ENDFOR

   ; Output the edge points, if could not find the point, set EdgePixelCount=0
   IF(EdgePointCount LE 0) THEN BEGIN
      EdgePixelCount = 0
      RETURN
   ENDIF

   EdgePoints     = TEMPORARY(RegionEdge[0L:EdgePointCount-1])
   EdgePixelCount = EdgePointCount

END
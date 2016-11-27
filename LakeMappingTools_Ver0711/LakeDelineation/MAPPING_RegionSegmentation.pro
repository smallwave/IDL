
;******************************************************************************
;; $Id: envi45_config/Program/LakeMappingTool/MAPPING_RegionSegmentation.pro $
;;
;; Author: Junli LI, Geography Department of UCLA, Los Angeles, CA 90095
;+
;; NAME:
;;   MAPPING_RegionSegmentation
;;
;; PURPOSE:
;;    This procedure find the water threshold of lake region, then perform 
;;    local segmentation
;;    (1) get the edge of the region
;;    (2) get the buffer pixels of the region
;;    (3) perform the histogram segmentation and get the threshold
;;    (4) extend the region if the new region's pixels extent the buffer region
;;        (there are region's pixels on the boundary of the region buffer, which
;;         means the new region exceeds the buffer region )
;;
;; PARAMETERS:
;;   WaterRegion(in-out)  - The labeled region from the global segmentation
;;   WaterRegion_T(in-out)- Region's local segmentation threshold
;;   RegionBuf(in)        - The same as the WaterRegion,temporary use
;;   NDWI(in)             - The NDWI of the Landsat image 
;;   Width, Height(in)    - Widh and Height of the image
;;   RegionIndex(in)      - Region indexes before local segmentation
;;   RegionCount(in)      - Region count before segmentation
;;   Region_T(in)         - Local segmentation threshold before segmentation
;;   NewRegionIndex(out)  - Region indexes after local segmentation
;;   NewRegionCount(out)  - Region count after local segmentation
;;   NewRegion_T(out)     - Local segmentation threshold after segmentation
;;   
;; OUTPUTS:
;;   the water segmentation value of NDWI
;;
;; CALLING CUSTOM-DEFINED FUNCTIONS:  LocalSegmentationByRegion
;;
;; PROCEDURES OR FUNCTIONS CALLED:  GetRegionEdge HistSegmentation
;;
;;  IsHalfLake
;;
;; MODIFICATION HISTORY:
;;    Modified by: Junli LI, 2008/05/07 12:30 AM
;;    Written by:  Junli LI, 2008/10/08 06:00 PM
;-
;******************************************************************************

PRO MAPPING_RegionSegmentation, WaterRegion, WaterRegion_T, RegionBuf, NDWI, $
            Width, Height, RegionIndex,  RegionCount, Region_T, NewRegionIndex, $
            NewRegionCount, NewRegion_T

;   COMMON SHARE
   COMMON SHARE
   ; get the region ID of the region
   RegionID          = WaterRegion[RegionIndex[0L]]
   IF(RegionID EQ 0) THEN RETURN

   ;***************************************************************************
   ;
   ; 1) Get the edge of the region, EdgePoints are point indexes of the edges
   ;
   ;***************************************************************************

   MAPPING_GetRegionEdge, WaterRegion,RegionIndex,Width,Height, $
           EDGEPOINTS=EdgePoints, EDGEPOINTCOUNT = EdgeCount
   IF( EdgeCount EQ 0L ) THEN BEGIN
      WaterRegion[RegionIndex] = 0L
      RegionBuf[RegionIndex]   = 0L
      NewRegion_T              = 1.0
      NewRegionCount           = 0L
      RETURN
   ENDIF

   ;***************************************************************************
   ;
   ; 2) Get the buffer of the region, Expand the region size until the pixels 
   ;    in the buffer is 2 times of the original region
   ;
   ;***************************************************************************

   ; [2.1] set temporary variables to save the buffer region
   ; estimate the pixel number of the region buffer need to expand
   IF(RegionCount LT BIGLAKE) THEN BEGIN
      BufferMaxCount   = LONG(BUFFER_ZOOM_MAX*RegionCount)
      DilateMaxCount   = LONG(BufferMaxCount*4)
   ENDIF ELSE BEGIN
      BufferMaxCount   = LONG(BUFFER_ZOOM_MIN*RegionCount)
      DilateMaxCount   = LONG(BufferMaxCount*2)
   ENDELSE

   ; new variables (1):  save the dilated buffer indexes, 4-neighbor expansion
   DilateIndex         = LONARR(DilateMaxCount)
   DilateIndex[0L]     = RegionIndex ;DilateIndex[0:RegionCount-1]= RegionIndex
   DilateCount         = RegionCount

   ; new variables (2): save the buffer indexes of the region
   BufferIndex         = LONARR(BufferMaxCount)
   BufferIndex[0L]     = RegionIndex  ;BufferIndex[0:RegionCount-1]=RegionIndex
   BufferCount         = RegionCount

   ; new variables (3): save the edge pixel indexes of the new buffer
   ExpandEdgePoints    = LONARR(BufferMaxCount)
   ExpandEdgePoints[0L]= EdgePoints ;ExpandEdgePoints[0:EdgeCount-1]=EdgePoints
   ExpandEdgeCount     = EdgeCount

   ; new variables (4): save the temporary edge indexes of the expanded buffer
   TempEdgePoints      = LONARR(BufferMaxCount)
   TempEdgeCount       = 0L

   ; [2.2] Loop procedure: Buffer Expansion until touches BufferMaxCount
   nTimes = 0
   ;MAXBUFFER    = LONG(2.5*RegionCount)
   WHILE (nTimes LT 2 OR BufferCount LT BufferMaxCount) DO BEGIN

      ; [2.2.1] Extend one pixel for each time
      FOR i=0L,ExpandEdgeCount-1 DO BEGIN
          index        = ExpandEdgePoints[i]
          Y            = UINT( index / Width)
          X            = UINT( index - Y * Width)
          ; If the pixel exceeds the image spatial extent
          IF((Y EQ Height -1) OR (Y EQ 0L) OR (X EQ 0L) OR (X EQ Width-1)) $
          THEN CONTINUE
          ; or find the expand pixels in its 4 neighborhood
          Neighbor4    = [index - Width, index - 1, index + 1, index + Width]
          ; Whether its neighborhood can be a expanded pixel
          FOR j=0, 3 DO BEGIN
              ; <1> 4-neigbor pixels is in the buffer or outside the image, $
              ;     can't become a expandable pixel
              IF( (RegionBuf[Neighbor4[j]] EQ RegionID) OR $
              (RegionBuf[Neighbor4[j]] EQ -1) ) THEN CONTINUE
              ; <2> make the expandable pixel in RegionBuf as buffer areas
              RegionBuf[Neighbor4[j]]       = RegionID
              ; <3> the expandable pixel is also the new edge of the buffer
              TempEdgePoints[TempEdgeCount] = Neighbor4[j]
              TempEdgeCount                 = TempEdgeCount+1
              ; <4> add the pixel to the DilateIndex
              DilateIndex[DilateCount]      = Neighbor4[j]
              DilateCount                   = DilateCount+1
              ;  DilateIndex array is full
              IF(DilateCount EQ DilateMaxCount OR $
              TempEdgeCount EQ BufferMaxCount) THEN BREAK
          ENDFOR ; j
          ; DilateIndex array is full, can't expand the buffer again
          IF(DilateCount EQ DilateMaxCount OR $
          TempEdgeCount EQ BufferMaxCount) THEN BREAK
      ENDFOR; i

      ; [2.2.2] Get the valid region edge and expanded buffer pixels
      ; If there are no pixels that can be expanded, then return
      IF(TempEdgeCount LE 0L) THEN BEGIN
         BREAK
      ENDIF

      ; The new buffer pixels
      FOR i=0L, TempEdgeCount-1 DO BEGIN
          IF(BufferCount GE BufferMaxCount) THEN BREAK
          index  = TempEdgePoints[i]
          IF(WaterRegion[index] EQ 0L AND NDWI[index] NE 0.0) THEN BEGIN
             BufferIndex[BufferCount]  = index
             BufferCount               = BufferCount+1 
          ENDIF
      ENDFOR

      ; The Expand EdgePoints
      ExpandEdgePoints[0L] = TempEdgePoints[0L:TempEdgeCount-1]
      ExpandEdgeCount      = TempEdgeCount
      TempEdgeCount        = 0L
      ;
      IF(DilateCount EQ DilateMaxCount ) THEN BREAK
      IF(BufferCount EQ BufferMaxCount) THEN BREAK
      ; next loop
      nTimes = nTimes + 1

   ENDWHILE

   ; After get the buffer, restore the RegionBuf
   index = DilateIndex[0L:DilateCount-1]
   RegionBuf[index] = WaterRegion[index]

   ; Could not find the buffer pixel
   IF(BufferCount EQ RegionCount) THEN BEGIN
      WaterRegion[RegionIndex]  = 0L
      WaterRegion_T[RegionIndex]= 0.0
      RegionBuf[RegionIndex]    = 0L
      NewRegionCount            = 0L
      NewRegion_T               = 1.0
      RETURN
   ENDIF

   ;***************************************************************************
   ;
   ; 3) Get the buffer of the region and perform histogram segmentation, and 
   ;    get the local segmentation value and the new segmentation result
   ;
   ;***************************************************************************

   ; Local histogram segmentation on NDWI
   BufferIndex       = BufferIndex[0L:BufferCount-1]
   NDWI_Data         = NDWI[BufferIndex]
   NewRegion_T       = MAPPING_HistSegmentation(NDWI_Data,Region_T)

   ; Clear the original region, Set the new region 
   RegionBuf[RegionIndex]    = 0L
   WaterRegion[RegionIndex]  = 0L
   WaterRegion_T[RegionIndex]= 0.0

;   IF(NewRegion_T EQ 1.0 OR NewRegion_T LT WATER_MIN) THEN BEGIN
  IF(NewRegion_T EQ 1.0) THEN BEGIN
      NewRegionCount = 0L
      RETURN
   ENDIF

   ; get the new index of water pixels, NewRegionCount saves the new point
   NewRegionIndex = WHERE(NDWI[BufferIndex] GE NewRegion_T, NewRegionCount)
   IF(NewRegionCount EQ 0) THEN RETURN
   index               = TEMPORARY(BufferIndex(NewRegionIndex))
   NewRegionIndex      = index
   NewIndex            = LONARR(NewRegionCount*2)
   NewIndex[0]         = NewRegionIndex
   NewCount            = NewRegionCount

   ; set the new local segmentation values
   WaterRegion[index]  = RegionID
   RegionBuf[index]    = RegionID
   WaterRegion_T[index]= NewRegion_T

   ;***************************************************************************
   ; 4) Find whether there are water pixels on the boundary of the buffer.
   ;    regions. If they are, expand its 4-neighbor pixels to find them,
   ;    until there are  no pixels that can be expanded
   ;
   ;***************************************************************************
   ; sets the TempEdgePoints are null, and saves the new edge points
   TempEdgeCount     = 0L
   ExpandEdgePoints  = ExpandEdgePoints[0:ExpandEdgeCount-1]
   BufferEdgeIndex   = TEMPORARY(ExpandEdgePoints)
   BufEdgeWaterIndex = WHERE(WaterRegion[BufferEdgeIndex] EQ RegionID, nCount)
;   IF(nCount LE 0L OR NewRegion_T LT Water_T0) THEN RETURN
   IF(nCount LE 0L) THEN RETURN
   BufEdgeWaterPoints= BufferEdgeIndex[BufEdgeWaterIndex]

   WHILE nCount GT 0L DO BEGIN

       FOR i = 0L,nCount-1 DO BEGIN
           index = BufEdgeWaterPoints[i]
           Y     = UINT( index / Width)
           X     = UINT( index - Y * Width)
           ; exceeds the image spatial extent
           IF( (Y EQ Height -1) OR (Y EQ 0L) OR (X EQ 0L) OR (X EQ Width-1) ) $
           THEN CONTINUE
           ; get the 4-neighbor of the pixel
           Neighbor4  = [index - Width, index - 1, index + 1, index + Width]
           FOR j=0, 3 DO BEGIN
               IF(WaterRegion[Neighbor4[j]] EQ 0L AND NDWI[Neighbor4[j]] $
                  GE NewRegion_T AND RegionBuf[Neighbor4[j]] NE 0L) THEN BEGIN
                  TempEdgePoints[TempEdgeCount] = Neighbor4[j]
                  TempEdgeCount                 = TempEdgeCount+1
                  WaterRegion[Neighbor4[j]]     = RegionID
                  RegionBuf[Neighbor4[j]]       = RegionID
                  WaterRegion_T[Neighbor4[j]]   = NewRegion_T
                  NewIndex[NewCount]            = Neighbor4[j]
                  NewCount                      = NewCount+1
                  IF(NewCount EQ 2*NewRegionCount OR TempEdgeCount EQ $
                  BufferMaxCount ) THEN BREAK
               ENDIF
           ENDFOR
           IF(NewCount EQ 2*NewRegionCount OR TempEdgeCount EQ $
           BufferMaxCount ) THEN BREAK
       ENDFOR

       ; Reset the BufferEdgeindex
       IF(NewCount EQ 2*NewRegionCount OR TempEdgeCount EQ BufferMaxCount ) $
       THEN BREAK
       IF(TempEdgeCount LE 0L) THEN BREAK
       BufEdgeWaterPoints = TempEdgePoints[0L:TempEdgeCount-1]
       nCount             = TempEdgeCount
       TempEdgeCount      = 0L

   ENDWHILE

   ; renew the region
   NewRegionIndex = TEMPORARY(NewIndex)
   NewRegionIndex = NewRegionIndex[0:NewCount-1]
   NewRegionCount = NewCount

END
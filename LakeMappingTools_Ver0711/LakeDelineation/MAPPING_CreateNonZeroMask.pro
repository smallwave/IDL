
;*****************************************************************************
;; $Id:  envi45_config/Program/LakeMappingTools/MAPPING_CreateNonZeroMask
;;
;; Author: Junli LI, Geography Department of UCLA, Los Angeles, CA 90095
;+
;; NAME:
;;   MAPPING_CreateNonZeroMask1
;;
;; PURPOSE:
;;   The function get the nonzero mask of the image data, in order to avoid the
;;   influence of some stripe noises or
;;
;; PARAMETERS:
;;
;;   IMG_FID (In) - File handle.
;;
;;   SeaIdx (in)  - Sea region(index)
 ;;
;; CALLING CUSTOM-DEFINED FUNCTIONS:  LakeDelineation
;;
;; MODIFICATION HISTORY:
;;
;;  Written by:  Junli LI, 2009/04/27 06:00 PM
;;  
;-
;*****************************************************************************

FUNCTION MAPPING_CreateNonZeroMask, IMG_FID, NDWIMask, SeaIdx

   ENVI_FILE_QUERY, IMG_FID, DIMS=DIMS
   Band1     = ENVI_GET_DATA(FID=IMG_FID,DIMS=DIMS,POS=[3])
   ImageMask = Band1 GT 0
   
   ; Whether there are sea pixels
   IF(N_Elements(SeaIdx) LT 5) THEN RETURN, ImageMask
   SeaCount  = SIZE(SeaIdx,/DIMENSION)
   
   ; Perform LABEL_REGION to get the regions
   Regions   = LABEL_REGION(NDWIMask, /ULONG)
   SeaRegions= Regions[SeaIdx]
  
   ; Get nozero index of the image
   idx       = WHERE(SeaRegions GT 0, RCount)
   IF(RCount LT 5) THEN RETURN, ImageMask

   SeaRegions= SeaRegions[idx]
   RegionHist= HISTOGRAM(SeaRegions,MIN=1,MAX=MAX(SeaRegions))
   HistNum   = MAX(RegionHist)
   
   WHILE HistNum GT 5000 DO BEGIN
      MaxRegID= WHERE(RegionHist EQ HistNum,iCount) + 1
      ImageMask[WHERE(Regions EQ MaxRegID[0])] = 0
      IF(iCount LE 0) THEN BREAK
      RegionHist[MaxRegID-1] = 0
      HistNum = MAX(RegionHist)
   ENDWHILE
  
   Regions   = LABEL_REGION(ImageMask, /ULONG)
   RegCount  = MAX(Regions)
   IF(RegCount LE 20) THEN RETURN, ImageMask

   RegionHist= HISTOGRAM(Regions,MIN=1,MAX=RegCount)
   HistNum   = MAX(RegionHist)
   i = 0
   ImageMask[*,*] = 0
   WHILE HistNum GT 500 AND i LT 20 DO BEGIN
      MaxRegID  = WHERE(RegionHist EQ HistNum,iCount) + 1
      ImageMask[WHERE(Regions EQ MaxRegID[0])] = 1
      RegionHist[MaxRegID-1] = 0
      HistNum   = MAX(RegionHist)
      i = i+1
   ENDWHILE

   RETURN, ImageMask

END
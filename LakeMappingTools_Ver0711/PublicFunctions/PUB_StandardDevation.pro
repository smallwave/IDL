
;******************************************************************************
;; $Id: envi45_config/Program/LakeExtraction/PUB_StandardDevation.pro $
;;
;; Author: Junli LI, Geography Department of UCLA, Los Angeles, CA 90095
;+
;; NAME:
;;   PUB_StandardDevation
;;
;; PURPOSE:
;;   The function get the standard deviation at given Data and mean value
;;
;; PARAMETERS:
;;
;;   WaterMask (in)   - the binary image (0-Land, 1-Water)
;;
;;   SMALL_REGION(in) - lake total pixels LT SMALL_REGION are removed off
;;
;;   SLOPE(in)        - the slope layer of the landsat image
;;
;;   SLOPE_T(in)      - lake's average slope GT SLOPE_T are removed off
;;
;; OUTPUTS:
;;   Standard Deviation
;;
;; CALLING CUSTOM-DEFINED FUNCTIONS:  HistSegmentation
;;
;; MODIFICATION HISTORY:
;;    Written by:  Junli LI, 2008/05/25 06:00 PM
;;    Written by:  Junli LI, 2008/10/08 06:00 PM
;-
;******************************************************************************

FUNCTION PUB_StandardDevation, Data, Ave

   ; get the size of data
   nsize  = SIZE(Data)
   nCount = nsize[1]
   ; calculate the standard deviation
   std = 0.0
   FOR i=0L, nCount-1 DO BEGIN
      std = std + (Data[i]-Ave)*(Data[i]-Ave)
   ENDFOR
   std = SQRT(std/nCount)
   ; return
   RETURN, std

END

;******************************************************************************
;; $Id: envi45_config/Program/LakeMappingTools/MAPPING_DOG.pro $
;;
;; Author: Junli LI, Geography Department of UCLA, Los Angeles, CA 90095
;+
;; NAME:
;;   MAPPING_DOG
;;
;; PURPOSE:
;;   The function generate LOG coefficient by the given sigma
;;
;; PARAMETERS:
;;   Sigma(in)      - the given sigma, it's the standard deviation
;;   mask(out)      - the main peaks of histogram
;;
;; OUTPUTS:
;;   Get the Gaussian coefficients
;;
;; CALLING CUSTOM-DEFINED FUNCTIONS:  FindPeakValley
;;
;; PROCEDURES OR FUNCTIONS CALLED:  
;;
;; MODIFICATION HISTORY:
;;  Written by:  Junli LI, 2008/05/04 06:00 PM
;;  Written by:  Junli LI, 2008/10/08 12:00 AM
;-
;******************************************************************************


PRO MAPPING_DOG, Sigma, MASK = mask
    ;
   GaussianDieOff = 0.0001
   pi=3.14159

   ssq = sigma*sigma
   for i=0, 29 do begin
       weight=exp(-i*i/(2*ssq));
       if weight LT GaussianDieOff then goto, outofhere
   endfor

outofhere:
   width=i-1;
   t = (indgen(2*width+1)) - width
   mask = (-t* exp(-(t*t)/(2*ssq))/ ssq)  ; derivative of a gaussian

END

;******************************************************************************
;; NAME:
;;   DOG2
;;
;; PURPOSE:
;;   2nd derivative, LoG, i.e. zero-crossing
;;
;; PARAMETERS:
;;   Sigma(in)      - the given sigma, it's the standard deviation
;;   mask(out)      - the main peaks of histogram
;;
;; OUTPUTS:
;;   Get the Gaussian coefficients
;;
;; CALLING CUSTOM-DEFINED FUNCTIONS:  FindPeakValley
;;
;; PROCEDURES OR FUNCTIONS CALLED:  
;;
;; MODIFICATION HISTORY:
;;  Written by:  Junli LI, 2008/05/04 06:00 PM
;;  Written by:  Junli LI, 2008/10/08 12:00 AM
;-
;******************************************************************************
PRO MAPPING_DOG2, Sigma, MASK = mask

   GaussianDieOff = 0.0001  ; Value from Maneesha
   pi=3.14159

   ssq = sigma*sigma
   for i=0, 29 do begin
       weight=exp(-i*i/(2*ssq));
       if weight LT GaussianDieOff then goto, outofhere
   endfor

outofhere:
   width=i-1;
   t = (indgen(2*width+1)) - width
   ; 2nd derivative of a gaussian
   mask = (t*t-ssq) * exp(-(t*t)/(2*ssq))/ (ssq*ssq)

END
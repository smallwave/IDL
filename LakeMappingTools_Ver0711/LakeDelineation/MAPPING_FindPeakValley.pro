
;******************************************************************************
;; $Id: envi45_config/Program/LakeMappingTools/MAPPING_FindPeakValley.pro $
;;
;; Author: Junli LI, Geography Department of UCLA, Los Angeles, CA 90095
;+
;; NAME:
;;   MAPPING_FindPeakValley
;;
;; PURPOSE:
;;    Find the main peaks and valleys to the given histogram by using DOG; Here
;;    the main peaks mean that the pixels in the peak is 5% of the whole pixels 
;;    at least. and the valleys here are two lowest points around the left and 
;;    right of the peak. So each peak has two valleys.
;;
;; PARAMETERS:
;;   Hist(in)        - the given histogram
;;   HistCount(in)   - the size of histogram.
;;   Peaks(out)      - the main peaks of histogram
;;   Valleys(out)    - the main valleys of histogram
;;
;; OUTPUTS:
;;   the water segmentation value of NDWI
;;
;; CALLING CUSTOM-DEFINED FUNCTIONS:  FindPeakValley
;;
;; PROCEDURES OR FUNCTIONS CALLED:  
;;
;; MODIFICATION HISTORY:
;;   Written by:  Junli LI, 2008/05/02 12:30 PM
;;   Written by:  Junli LI, 2008/10/08 12:00 AM
;-
;******************************************************************************

FUNCTION MAPPING_FindPeakValley, Hist, HistCount, Peaks = Peaks, Valleys = Valleys

   COMMON SHARE
    
    STR_ERROR = ''
    CATCH, Error_status 
    ; This statement begins the error handler: 
    IF Error_status NE 0 THEN BEGIN 
       STR_ERROR = STRING(Error_status) + ' :' + !ERROR_STATE.MSG
       CATCH, /CANCEL 
       RETURN, 0
    ENDIF 
     
   ;***************************************************************************
   ;
   ; 1) Find the min and max NDWI in the hist
   ;
   ;***************************************************************************

   ; the first nozero values
   nBegin      = 0
   FOR i=0,HistCount-2 DO BEGIN
       IF(Hist[i] GT 0) THEN BREAK
   ENDFOR
   nBegin      = i
   ; the last nozero values
   nEnd        = HistCount-1
   FOR i=HistCount-1, 1, -1 DO BEGIN
       IF(Hist[i] GT 0) THEN BREAK
   ENDFOR
   nEnd        = i

   ;***************************************************************************
   ;
   ; 2) Use the DOG filter to perform convolving operations on the hist data, 
   ;    points where the curve is intersected with the X-axis are where peaks 
   ;    and valleys located
   ;
   ;***************************************************************************

   ; Perform DOG( Difference of Gaussian ) filtering
   ; SIGMA_GAUSS is in the <COMMON SHARE>
   MAPPING_DOG, SIGMA_GAUSS, MASK = Mask_DOG  
   DOG1_Hist   = -1.0*CONVOL(float(Hist),Mask_DOG,CENTER =1)

   ;***************************************************************************
   ;
   ; 3) Find the zero points of the histogram,descending points are peaks, 
   ;    while ascending ones are valleys
   ;
   ;***************************************************************************

   ; new variables to store values
   iPeaks      = INTARR(100)
   iPeakCount  = 0
   iValleys    = INTARR(100)
   iValleyCount= 0
   nPeaks      = INTARR(40)
   nValleys    = INTARR(40)
   nPeakCount  = 0
   nValleyCount= 0
   ; Set the first valley as nBegin
   iValleys[0] = nBegin
   iValleyCount= iValleyCount+1

   ;  [1] Generally, Peaks and valleys appear at the same time, that's to say, 
   ;      each peak is corresponding with one valley, but there are also 
   ;      occasions that peaks without valleys or valleys without peaks
   ;  (i)   if the DOG curve is degressive in zero regions, then the zero 
   ;        location is a peak of the histogram
   ;  (ii)  if it's increased in near zero regions, then the zero location is a
   ;        valley of the histogram
   ;  (iii) if there are continuous peaks(valleys), that means the interval 
   ;        between these two peaks(valleys) has no pixels    
   FOR i=nBegin,nEnd-1 DO BEGIN
       ; Peaks
       IF((DOG1_Hist[i] GT 0 AND DOG1_Hist[i+1] LE 0) OR $
          (DOG1_Hist[i] GE 0 AND DOG1_Hist[i+1] LT 0)) THEN BEGIN
           iPeaks[iPeakCount]     = i+1
           iPeakCount             = iPeakCount + 1
       ENDIF
       ; Valleys
       IF((DOG1_Hist[i] LT 0 AND DOG1_Hist[i+1] GE 0) OR $
          (DOG1_Hist[i] LE 0 AND DOG1_Hist[i+1] GT 0)) THEN BEGIN
           iValleys[iValleyCount] = i+1
           iValleyCount           = iValleyCount + 1
       ENDIF
   ENDFOR
   ; Set the last valley
   iValleys[iValleyCount]         = nEnd
   iValleyCount                   = iValleyCount+1

   ; IF there are no peaks, return
   IF(iPeakCount EQ 0) THEN BEGIN
     RETURN, 0
   ENDIF

   ; [2] After all the peaks and valleys are found, then need find the relations
   ;     between these peaks and valleys we make each peak has two valleys
   FOR i=0,iPeakCount-1 DO BEGIN
       Peak_i = iPeaks[i]
       IF(nPeakCount EQ 19) THEN BEGIN
          BREAK
       ENDIF
       FOR j=0,iValleyCount-2 DO BEGIN
           IF(iValleys[j] LT Peak_i AND iValleys[j+1] GT Peak_i) THEN BEGIN
              IF(nPeakCount EQ 19) THEN BEGIN
                 BREAK
              ENDIF
              IF(nPeakCount GE 1) THEN BEGIN
                 IF(nValleys[nValleyCount-1] EQ iValleys[j+1]) THEN BEGIN
                    nPeaks[nPeakCount-1]   = Peak_i
                 ENDIF ELSE BEGIN
                    nPeaks[nPeakCount]     = Peak_i
                    nPeakCount             = nPeakCount+1
                    nValleys[nValleyCount] = iValleys[j]
                    nValleyCount           = nValleyCount+1
                    nValleys[nValleyCount] = iValleys[j+1]
                    nValleyCount           = nValleyCount+1
                 ENDELSE
              ENDIF ELSE BEGIN
                nPeaks[nPeakCount]     = Peak_i
                nPeakCount             = nPeakCount+1
                nValleys[nValleyCount] = iValleys[j]
                nValleyCount           = nValleyCount+1
                nValleys[nValleyCount] = iValleys[j+1]
                nValleyCount           = nValleyCount+1
              ENDELSE
              BREAK
           ENDIF
       ENDFOR
   ENDFOR
   ;
   iPeaks[*]            = 0
   iPeaks[0]            = nPeaks[0:nPeakCount-1]
   iPeakCount           = nPeakCount
   nPeaks[*]            = 0
   nPeakCount           = 0
   iValleys[*]          = 0
   iValleys[0]          = nValleys[0:nValleyCount-1]
   iValleyCount         = nValleyCount
   nValleys[*]          = 0
   nValleyCount         = 0

   ;***************************************************************************
   ;
   ; 3) Find the big peaks and valleys in all of the peaks and valleys, the 
   ;    total pixel of the peak is greater than PEAK_PERCENT(In <COMMON SHARE>)
   ;    is the peak, then find it's left and right valley
   ;
   ;***************************************************************************

   ; [3.1] Add up hist from begin to end
   AddHist        = Hist
   FOR i=1,HistCount-1 DO BEGIN
       AddHist[i] = AddHist[i] + AddHist[i-1]
   ENDFOR
   ; The total of the pixels
   PixCount       = AddHist[HistCount-1]

   ; [3.2] Loop procedure to find big peaks
   FOR i=0,iPeakCount-1 DO BEGIN

     ; calculate the percentage of the hist
     fPercent = FLOAT((AddHist[iValleys[2*i+1]]-AddHist[iValleys[2*i]])*1.0/PixCount)
     IF( fPercent GT PEAK_PERCENT) THEN BEGIN

           IF( nPeakCount LT 1) THEN BEGIN
              nPeaks[nPeakCount]       = iPeaks[i]
              nPeakCount               = nPeakCount + 1
              nValleys[nValleyCount]   = iValleys[2*i]
              nValleyCount             = nValleyCount+1
              nValleys[nValleyCount]   = iValleys[2*i+1]
              nValleyCount             = nValleyCount+1
           ENDIF ELSE BEGIN
              ; IF the intervals between two peaks are less than 10, then 
              ;  combine them to become a one peak
              IF( ABS(iPeaks[i] - nPeaks[nPeakCount-1]) LE PEAK_INTERVAL) $
              THEN BEGIN
                  Peak1 = Hist[iPeaks[i]]
                  Peak2 = Hist[nPeaks[nPeakCount-1]]
                  nPeaks[nPeakCount-1]     = (Peak1 GT Peak2) ? iPeaks[i] : $
                                              nPeaks[nPeakCount-1]
                  nValleys[nValleyCount-1] = iValleys[2*i+1]
              ENDIF ELSE BEGIN
                  ; ELSE record the peaks and valleys
                  nPeaks[nPeakCount]       = iPeaks[i]
                  nPeakCount               = nPeakCount + 1
                  nValleys[nValleyCount]   = iValleys[2*i]
                  nValleyCount             = nValleyCount+1
                  nValleys[nValleyCount]   = iValleys[2*i+1]
                  nValleyCount             = nValleyCount+1
              ENDELSE
           ENDELSE

      ENDIF

   ENDFOR
   ; if no peaks are founded, return
   IF(nPeakCount EQ 0) THEN RETURN, 0

   ; return the peaks and valleys
   Peaks   = nPeaks(0:nPeakCount-1)
   Valleys = nValleys(0:nValleyCount-1)
   RETURN, 1
END


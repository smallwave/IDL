
;*****************************************************************************
;; $Id: envi45_config/Program/LakeMappingTools/MAPPING_HistSegmentation.pro $
;;
;; Author: Junli LI, Geography Department of UCLA, Los Angeles, CA 90095
;+
;; NAME:
;;   MAPPING_HistSegmentation
;;
;; PURPOSE:
;;   This Function calculate the threshold to segment Lakes from Water Index 
;;    data by using the histogram
;;
;; PARAMETERS:
;;   NDWI_Data(in)   - the NDWI data in the region buffer
;;   T0              - the initial NDWI threshold
;;
;; OUTPUTS:
;;   the water segmentation value of NDWI
;;
;; CALLING CUSTOM-DEFINED FUNCTIONS:  RegionSegmentation
;;
;; MODIFICATION HISTORY:
;;
;;  Written by:  Junli LI, 2008/05/04 06:00 PM
;;  Modified by: Junli LI, 2008/11/05 12:00 AM
;;  
;-
;*****************************************************************************

Function MAPPING_HistSegmentation, NDWI_Data, T0

  COMMON SHARE
           
;  COMMON SHARE
  siz_NDWI     = SIZE(NDWI_Data)
  nCount       = siz_NDWI[1]
  ;****************************************************************************
  ;
  ; 1) Get the histogram of NDWI
  ;
  ;****************************************************************************
  ;[1.1] In order to get the histogram of NDWI, we need to define the BINSIZE, 
  ;      MIN, MAX and HISTCOUNT HIST_BINSIZE has declared in 'COMMON SHARE'
  HIST_COUNT   = UINT((NDWI_MAX-NDWI_MIN)/HIST_BINSIZE)
  HIST_MIN     = NDWI_MIN
  HIST_MAX     = NDWI_MAX - HIST_BINSIZE
  ;[1.2] Create the histogram
  X            = HIST_MIN + LINDGEN(HIST_COUNT)*HIST_BINSIZE
  Y            = HISTOGRAM(FLOAT(NDWI_Data), MIN = HIST_MIN, MAX = HIST_MAX, $
                           BINSIZE = HIST_BINSIZE)
  ;[1.3] Smooth the histogram first
  ; if the size of NDWI_Data is small than the smooth kernal size, then return
  MEANSIZE     = 3          
  IF(nCount LT MEANSIZE) THEN RETURN, 1.0
  Y            = MEDIAN( Y, MEANSIZE)
  Y            = SMOOTH( Y, MEANSIZE)

  ;****************************************************************************
  ;
  ; 2) Find the peaks and valleys of the histogram, each peak has two valleys
  ;
  ;****************************************************************************

  bFind      = MAPPING_FindPeakValley(Y,HIST_COUNT,Peaks=Peaks,Valleys=Valleys)
  ;  NO peaks are found
  IF(bFind EQ 0) THEN  BEGIN
     RETURN, 1.0
  ENDIF
  ; Get the peaks and valleys
  tempSize     = SIZE(Peaks)
  PeakCount    = tempSize[1]
  Peak_NDWI    = X(Peaks)
  Valley_NDWI  = X(Valleys)

  ;****************************************************************************
  ;
  ; 3) Get the segmentation threshold by analysing the peaks of the histogram. 
  ;    Here are three cases, one peak, two peaks and multiple peaks
  ;
  ;****************************************************************************

  ;  Case 1: One Peak, it means no water 
  IF(PeakCount EQ 1) THEN BEGIN
     RETURN, 1.0
  ENDIF

  ; Case 2: Two Peaks, left peak(Peak_NDWI[0]) and right peak(Peak_NDWI[1])
  IF(PeakCount EQ 2) THEN BEGIN
     ;Case 2.1: if NDWI of the right peak is LT T0, indicates no-water pixels
     IF(Peak_NDWI[1] LT T0) THEN BEGIN
        ;RETURN, 1.0
       RETURN, T0-0.02
     ENDIF
     ;Case 2.2: calculate the mean and std of right part of left_peak and left 
     ;          part of right_peak
     Land   = WHERE(NDWI_Data GE Peak_NDWI[0] AND NDWI_Data LE Valley_NDWI[1],$
                    nLandCount)
     Water  = WHERE(NDWI_Data GE Valley_NDWI[2] AND NDWI_Data LE Peak_NDWI[1],$
                    nWaterCount)
     IF(nLandCount LE 0 OR nWaterCount EQ 0) THEN BEGIN
       RETURN, (Peak_NDWI[0]+Peak_NDWI[1])/2.0
     ENDIF
     ; get the mean and standard deviation
     ave_Land  = Peak_NDWI[0]
     ave_Water = Peak_NDWI[1]
     std_Land  = PUB_StandardDevation(NDWI_Data(Land) , ave_Land )
     std_Water = PUB_StandardDevation(NDWI_Data(Water), ave_Water)
     Water_T   = (ave_Water*std_Land+ave_Land*std_Water)/(std_Land+std_Water)
     IF(Water_T LE WATER_MIN) THEN Water_T = WATER_MIN  
     RETURN, Water_T
  ENDIF

  ; Case 3: multiple Peaks, left, middle and right peaks
  IF(PeakCount GE 3) THEN BEGIN
     ; Case 3.1: if the NDWI of the right peak is less than T0, it 
     ;           indicates that there is no water in the region
     IF(Peak_NDWI[PeakCount-1] LT 0) THEN BEGIN
        LandPeakIdx = PeakCount-2
        WaterPeakIdx= PeakCount-1
     ENDIF ELSE BEGIN
        ; Case 3.2: select the two peaks around T0, then calculate the ave and std
        index_Land     = WHERE(Peak_NDWI LT 0,nLandPeak)
        IF(nLandPeak EQ 0) THEN BEGIN
           LandPeakIdx = 0
           WaterPeakIdx= 1
        ENDIF ELSE BEGIN
           LandPeakIdx = WHERE( Peak_NDWI EQ MAX(Peak_NDWI[index_Land]) )
           LandPeakIdx = LandPeakIdx[0]
           WaterPeakIdx= LandPeakIdx + 1
        ENDELSE
     ENDELSE
     ; get the mean and standard deviation
     ave_Land    = Peak_NDWI[LandPeakIdx]
     ave_Water   = Peak_NDWI[WaterPeakIdx]
     Land        = WHERE(NDWI_Data GE ave_Land AND NDWI_Data LE $
                         Valley_NDWI[2*LandPeakIdx+1], nLandCount)
     Water       = WHERE(NDWI_Data GE Valley_NDWI[2*WaterPeakIdx] $
                           AND NDWI_Data LE ave_Water, nWaterCount)
     ; the half peak has no pixels
     IF(nLandCount LE 0 OR nWaterCount LE 0) THEN BEGIN
         RETURN, T0-0.02
     ENDIF
     ;
     std_Land    = PUB_StandardDevation(NDWI_Data(Land) , ave_Land )
     std_Water   = PUB_StandardDevation(NDWI_Data(Water), ave_Water)
     Water_T     = (ave_Water*std_Land+ave_Land*std_Water)/(std_Land+std_Water)
     IF(Water_T LE WATER_MIN) THEN Water_T = WATER_MIN 
     RETURN, Water_T
  ENDIF

END
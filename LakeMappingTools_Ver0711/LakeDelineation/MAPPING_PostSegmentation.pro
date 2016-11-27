
PRO MAPPING_PostSegmentation,WaterMask,ImageMask, ShadeMask, Band4

  COMMON SHARE
  bHaveShade   = ( N_Elements (ShadeMask) EQ 0 ) ? 0 : 1
  ; Get the size of watermask
  siz          = SIZE(WaterMask)
  Width        = siz[1]
  Height       = siz[2]

  ;****************************************************************************
  ;
  ; 1) Remove small regions of the foreground pixels, that means water regions 
  ;    less than 4 pixeles are taken as 0 ( 0 = background )
  ;
  ;****************************************************************************

  ; Perform LABEL_REGION to get the regions
  nCount       = TOTAL(WaterMask)
  Regions      = LABEL_REGION(WaterMask, /ULONG )
  ; Thirdly, get nozero index of the image
  NonZeroIndex = WHERE(Regions NE 0, NoZeroCount)
  NonZeroRegion= Regions(NonZeroIndex)
  ; The fourth, sort the index
  SortIndex    = SORT(NonZeroRegion, /L64)
  NonZeroIndex = NonZeroIndex(SortIndex)
  NonZeroRegion= NonZeroRegion(SortIndex)
  ; Loop the procedure to remove the lakes those total pixels LT SMALLREGION
  nFrom        = 0L
  nTo          = nFrom
  nRegionID    = NonZeroRegion[0]
  FOR i = 0L, NoZeroCount-1 DO BEGIN
    ; if the region ID of the current pixel is the same as nRegionID,  
    ; then go ahead or statistic the number of nRegionID
    IF(NonZeroRegion[i] EQ nRegionID) THEN  BEGIN
      nTo     = i
    ENDIF ELSE BEGIN
      nPixels  = nTo - nFrom + 1
      Index    = NonZeroIndex[nFrom:nTo]
      ; remove small regions
      IF(nPixels LE SMALLREGION) THEN BEGIN
        WaterMask(Index) = 0
        GOTO, NextRegion
      ENDIF
      ; remove the shade region
      IF(bHaveShade) THEN BEGIN
         nShadePixels = TOTAL(ShadeMask[Index])
         ShadePercent = LONG(0.25*nPixels+1)
         IF(nPixels LT 80 AND nShadePixels GE 10) THEN BEGIN
            WaterMask[Index] = 0
            ImageMask[Index] = 0
         ENDIF
         IF(nPixels GT 80 AND nShadePixels GT ShadePercent) THEN BEGIN
           WaterMask[Index] = 0
           ImageMask[Index] = 0
         ENDIF
         GOTO, NextRegion
      ENDIF
      ; remove the snow region
      IF(MEAN(Band4[Index]) GT SNOW_REF) THEN BEGIN
         WaterMask[Index] = 0
         GOTO, NextRegion
      ENDIF
      
      NextRegion:
      ; reset the nFrom, nTo and the new region label ID
      nRegionID= NonZeroRegion[i]
      nFrom    = i
      nTo      = i
    ENDELSE
  ENDFOR

  ;****************************************************************************
  ;
  ; 2) remove small regions of the background pixels, has the same steps as (1)
  ;
  ;****************************************************************************

  ; Convert the image and make background pixels be 1, foreground pixels be 0
  WaterMask    = 1 - WaterMask
  ; Perform LABEL_REGION to get the regions
  Regions = LABEL_REGION(WaterMask, /ULONG )
  RegionCount  = MAX(Regions)
  IF(RegionCount LE 0) THEN BEGIN
     WaterMask = 1 - WaterMask
     RETURN
  ENDIF
  RegionHist   = HISTOGRAM(Regions, MIN = 1, MAX = RegionCount)
  ; Then get the region ID which have the most pixels
  MaxRegID     = WHERE(RegionHist EQ MAX(RegionHist)) + 1
  ; Thirdly, get nozero index of the image
  NonZeroIndex = WHERE((Regions NE 0) AND (Regions NE MaxRegID[0]),NoZeroCount)
  IF(NoZeroCount LE 0) THEN NonZeroRegion = Regions $
  ELSE NonZeroRegion= Regions(NonZeroIndex)
  ; The fourth, sort the index
  SortIndex    = SORT(NonZeroRegion, /L64)
  NonZeroIndex = NonZeroIndex(SortIndex)
  NonZeroRegion= NonZeroRegion(SortIndex)

  ; Loop the procedure to remove lakes whose pixels are less than SMALLREGION
  nFrom        = 0L
  nTo          = nFrom
  nRegionID    = NonZeroRegion[0]
  ;
  FOR i = 0L, NoZeroCount-1 DO BEGIN
    ; if the region ID of the current pixel is the same as nRegionID, then go 
    ; ahead, else statistic the number of nRegionID
    IF(NonZeroRegion[i] EQ nRegionID) THEN  BEGIN
       nTo     = i
    ENDIF ELSE BEGIN
      nPixels  = nTo - nFrom + 1
      Index    = NonZeroIndex[nFrom:nTo]
      ; remove small regions
      IF(nPixels LE 2*SMALLREGION) THEN WaterMask[Index] = 0
      ; reset the nFrom, nTo and the new region label ID
      nRegionID= NonZeroRegion[i]
      nFrom    = i
      nTo      = i
    ENDELSE

  ENDFOR
  ;Restore background pixels and water pixels
  WaterMask    = 1- WaterMask

END
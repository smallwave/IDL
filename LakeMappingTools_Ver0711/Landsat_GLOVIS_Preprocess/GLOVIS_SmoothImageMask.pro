;*****************************************************************************
;; $Id: envi45_config/Program/LakeMappingTools/GLOVIS_SmoothImageMask
;;
;; Author: Junli LI, Geography Department of UCLA, Los Angeles, CA 90095
;+
;; NAME:
;;   GLOVIS_FileNaming
;;
;; PURPOSE:
;;  This function gives the file naming rule to convert a GLOVIS zip filename
;;  to an ENVI filename
;;
;*****************************************************************************
;; PARAMETERS:
;;
;;   MASK  - the MASK band of the imagery
;;
;; CALLING PROCEDURES:
;;   GLOVIS_StackBandFiles: Stack the multi bands of the Landsat file
;;     
;; CALLING CUSTOM-DEFINED FUNCTIONS:  

;;
;; MODIFICATION HISTORY:
;;
;;  Written by:  Junli LI, 2009/05/08 11:00 AM
;;  Modified  :  
;;  Modified  : 
;-
;*****************************************************************************

FUNCTION GLOVIS_SmoothImageMask, MASK
    
    ; Get the dimension of the 
    siz = SIZE(MASK, /DIMENSION)
    NS  = siz[0]
    NL  = siz[1]
    
    ;**************************************************y************************
    ;
    ;  Get the four footprint points of the imagery
    ;
    ;***************************************************************************
    ;
    ; First get the X, Y pixel coordinates of the Image region
    idx = WHERE(MASK EQ 1)
    Y   = UINT(idx/NS)
    X   = UINT(idx-Y*NS)
    
    ; minX
    minX = MIN(X)
    P4_X = minX
    idx = WHERE(X EQ minX)
    P4_Y = MAX(Y[idx])
       
    ; maxX
    maxX = MAX(X)
    P2_X = maxX
    idx = WHERE(X EQ maxX)
    P2_Y = MAX(Y[idx])
 
    ; minY
    minY = MIN(Y)
    P1_Y = minY
    idx = WHERE(Y EQ minY)
    P1_X = MIN(X[idx])
    
    ; maxY
    maxY = MAX(Y)
    P3_Y = maxY
    idx = WHERE(Y EQ maxY)
    P3_X = MAX(X[idx])
    
    ; Get the ROI (region of the interest)
    PX = LONARR(5)
    PY = LONARR(5)
    PX = [P1_X+50,P2_X-50,P3_X-50,P4_X+50,P1_X+50]
    PY = [P1_Y+5,P2_Y+5,P3_Y-5,P4_Y-5,P1_Y+5]
    
    ; fil the ROI
    WaterIdx  = POLYFILLV(PX, PY, NS, NL)    
    MASK1     = MASK
    MASK1[*,*]=0
    MASK1[WaterIdx] = 1
    MASK = MASK AND MASK1
    
    RETURN, MASK
END
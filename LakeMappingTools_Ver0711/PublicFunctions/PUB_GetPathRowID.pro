
;******************************************************************************
;; $Id: envi45_config/Program/LakeExtraction/PUB_GetPathRowID.pro $
;;
;; Author: Junli LI, Geography Department of UCLA, Los Angeles, CA 90095
;+
;; NAME:
;;   PUB_GetPathRowID
;;
;; PURPOSE:
;;   The function get the PathROW ID which connect the Landsat WRS shape file
;;   with each PathRow imagery
;;
;; PARAMETERS:
;;
;;   nPath (in)   - Path ID
;;
;;   nRow(in)     - Row ID
;;

;;
;; OUTPUTS:
;;   PathRow ID
;;
;; CALLING CUSTOM-DEFINED FUNCTIONS: 
;;
;; MODIFICATION HISTORY:
;;    Written by:  Junli LI, 2008/05/25 06:00 PM
;;    Written by:  Junli LI, 2008/10/08 06:00 PM
;-
;******************************************************************************

FUNCTION PUB_GetPathRowID, nPath, nRow

    sPath = STRTRIM(STRING(nPath),2)
    IF(nPath LT 10) THEN sPath = '00' + sPath
    IF(nPath GE 10 AND nPath LT 100) THEN sPath = '0' + sPath
  
    sRow  = STRTRIM(STRING(nRow),2)
    IF(nRow LT 10) THEN sRow = '00' + sRow
    IF(nRow GE 10 AND nRow LT 100) THEN sRow = '0' + sRow
  
    sPathRow = sPath+sRow
    RETURN, sPathRow
  
END
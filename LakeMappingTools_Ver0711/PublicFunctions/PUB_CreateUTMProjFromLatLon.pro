
;******************************************************************************
;; $Id: envi45_config/Program/LakeExtraction/PUB_CreateUTMProjFromLatLon.pro $
;;
;; Author: Junli LI, Geography Department of UCLA, Los Angeles, CA 90095
;+
;; NAME:
;;   PUB_CreateUTMProjFromLatLon
;;
;; PURPOSE:
;;   The function finds what's UTM zones are the given Lat/Lon point in, then 
;;   create the UTM projection 
;;   
;;   The Universal Transverse Mercator projection divides the earth into 60 UTM
;;   zones. Each zone is 6 degrees wide in longitude. The central meridian for 
;;   the projection is in the middle of the UTM zone. (The reference latitude 
;;   for all UTM zones is the equator.) 
;;
;;   UTM       Zone        Central         UTM       Zone        Central
;;   Zone      Range       Meridian        Zone      Range       Meridian
;;    1    180W - 174W      177W           31      0E -   6E        3E
;;    2    174W - 168W      171W           32      6E -  12E        9E
;;    3    168W - 162W      165W           33     12E -  18E       15E
;;    4    162W - 156W      159W           34     18E -  24E       21E
;;    5    156W - 150W      153W           35     24E -  30E       27E
;;    6    150W - 144W      147W           36     30E -  36E       33E
;;    7    144W - 138W      141W           37     36E -  42E       39E
;;    8    138W - 132W      135W           38     42E -  48E       45E
;;    9    132W - 126W      129W           39     48E -  54E       51E
;;   10    126W - 120W      123W           40     54E -  60E       57E
;;   11    120W - 114W      117W           41     60E -  66E       63E
;;   12    114W - 108W      111W           42     66E -  72E       69E
;;   13    108W - 102W      105W           43     72E -  78E       75E
;;   14    102W -  96W       99W           44     78E -  84E       81E
;;   15     96W -  90W       93W           45     84E -  90E       87E
;;   16     90W -  84W       87W           46     90E -  96E       93E
;;   17     84W -  78W       81W           47     96E - 102E       99E
;;   18     78W -  72W       75W           48    102E - 108E      105E
;;   19     72W -  66W       69W           49    108E - 114E      111E
;;   20     66W -  60W       63W           50    114E - 120E      117E
;;   21     60W -  54W       57W           51    120E - 126E      123E
;;   22     54W -  48W       51W           52    126E - 132E      129E
;;   23     48W -  42W       45W           53    132E - 138E      135E
;;   24     42W -  36W       39W           54    138E - 144E      141E
;;   25     36W -  30W       33W           55    144E - 150E      147E
;;   26     30W -  24W       27E           56    150E - 156E      153E
;;   27     24W -  18W       21W           57    156E - 162E      159E
;;   28     18W -  12W       15W           58    162E - 168E      165E
;;   29     12W -   6W        9W           59    168E - 174E      171E
;;   30      6W -   0E        3W           60    174E - 180W      177E
;;
;; PARAMETERS:
;;
;;   Lat (in)   - Latitude
;;
;;   Lon(in)    - Longitude
;;
;; OUTPUTS:
;;   UTM projections
;;
;; CALLING CUSTOM-DEFINED FUNCTIONS:  HistSegmentation
;;
;; MODIFICATION HISTORY:
;;    Written by:  Junli LI, 2009/05/09 06:00 PM
;-
;******************************************************************************

FUNCTION PUB_CreateUTMProjFromLatLon, Lat, Lon
    
    zone  = FIX(31.0 + Lon/6.0)  
    south = Lat LT 0
    Datum = 'WGS-84'
    Units = ENVI_TRANSLATE_PROJECTION_UNITS ('Meters') 
    proj = ENVI_PROJ_CREATE(/UTM, ZONE=ZONE, SOUTH=south,DATUM=Datum,UNITS=units)
    RETURN, proj
    
END
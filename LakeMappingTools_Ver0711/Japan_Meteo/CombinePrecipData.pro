
FUNCTION CombinePrecipData, nData1, nData2 
   
   idx1   = WHERE((nData1 GE 0) AND (nData2 GE 0), nCount1)
   IF(nCount1 GT 0) THEN nData1[idx1] = nData1[idx1]+nData2[idx1]
   idx2   = WHERE((nData1 LE -99.0) OR (nData2 LE -99.0), nCount2)
   IF(nCount2 GT 0) THEN nData1[idx2] = -99.9
   RETURN, nData1
END
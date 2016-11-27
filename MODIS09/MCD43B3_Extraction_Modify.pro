PRO MCD43B3_Extraction_Modify

    FilePath   =  'I:\MCD43B3_CentralAsia\'
    Point_PIX  =  [4047,1941]
;    Point_PIX  =  [2543,1793]
    X_Pix  =  Point_PIX[0]
    Y_Pix  =  Point_PIX[1]

    TXTPath    =  'D:\MCD43B3_2.txt'
    Head_String = ['Source', 'Date', 'Lat', 'Lon', 'B1', 'B2', 'B3', 'B4', 'B5', 'B6', 'B7', 'vis', 'nir', 'swir']
    OPENW, hFile, TXTPath, /GET_LUN
    Type   =  '(a16, 2X, a10, 2X, a5, 2X, a5, 2X, a5, 2X, a5, 2X, a5, 2X, a5, 2X, a5, 2X, a5, 2X, a5, 2X, a5, 2X, a5, 2X, a5)'  
    PRINTF, hFile, Head_String, FORMAT = TYPE
    
    FileSearch = FILE_SEARCH(FilePath, COUNT = ProductCount, '*.dat', /TEST_READ, /FULLY_QUALIFY_PATH)
    IF(ProductCount LE 0) THEN BEGIN
       Print, 'There are no valid MODIS data to be processed.'
       RETURN
    ENDIF    
    
    FOR i=0, ProductCount-1 DO BEGIN
      File      =  FileSearch[i] 
      Filename  =  FILE_BASENAME(File)
      MOD_Name  =  STRMID(Filename,0,16)
      MOD_Year  =  STRMID(Filename,9,4)
      MOD_Date  =  STRMID(Filename,13,3)
      ENVI_OPEN_FILE, File, R_FID = FID
      ENVI_FILE_QUERY, FID, NB = NB, DIMS = DIMS, BNAMES = BNAMES      
      ENVI_CONVERT_FILE_COORDINATES, FID,  X_Pix, Y_Pix, X_Map, Y_Map, /to_map ;坐标转换   
      Lat  = STRCOMPRESS(STRING(Y_Map), /REMOVE_ALL)
      Lon  = STRCOMPRESS(STRING(X_Map), /REMOVE_ALL)     
;            X_Pix = FIX(X_Pix[0])     
;            Y_Pix = FIX(Y_Pix[0])        
            DIMS = [-1,X_Pix,X_Pix,Y_Pix,Y_Pix]           
            
      V_B1  = STRCOMPRESS(STRING(ENVI_GET_DATA(FID=FID,DIMS = DIMS, POS=0)), /REMOVE_ALL)
      V_B2  = STRCOMPRESS(STRING(ENVI_GET_DATA(FID=FID,DIMS = DIMS, POS=1)), /REMOVE_ALL)
      V_B3  = STRCOMPRESS(STRING(ENVI_GET_DATA(FID=FID,DIMS = DIMS, POS=2)), /REMOVE_ALL)
      V_B4  = STRCOMPRESS(STRING(ENVI_GET_DATA(FID=FID,DIMS = DIMS, POS=3)), /REMOVE_ALL)
      V_B5  = STRCOMPRESS(STRING(ENVI_GET_DATA(FID=FID,DIMS = DIMS, POS=4)), /REMOVE_ALL)
      V_B6  = STRCOMPRESS(STRING(ENVI_GET_DATA(FID=FID,DIMS = DIMS, POS=5)), /REMOVE_ALL)
      V_B7  = STRCOMPRESS(STRING(ENVI_GET_DATA(FID=FID,DIMS = DIMS, POS=6)), /REMOVE_ALL)
      V_B8  = STRCOMPRESS(STRING(ENVI_GET_DATA(FID=FID,DIMS = DIMS, POS=7)), /REMOVE_ALL)
      V_B9  = STRCOMPRESS(STRING(ENVI_GET_DATA(FID=FID,DIMS = DIMS, POS=8)), /REMOVE_ALL)
      V_B10  = STRCOMPRESS(STRING(ENVI_GET_DATA(FID=FID,DIMS = DIMS, POS=9)), /REMOVE_ALL)
            
      IF MOD_Year EQ '2000' or '2004' or '2008' THEN BEGIN
        MONTH = MOD_Date/30 + 1        
        nDAY  = MOD_Date mod 30
        CASE MONTH OF
          '1': Day = nDAY
          '2': Day = nDAY-1
          '3': Day = nDay
          '4': Day = nDAY-1
          '5': Day = nDAY-1
          '6': Day = nDAY-2
          '7': Day = nDAY-2
          '8': Day = nDAY-3
          '9': Day = nDAY-4
          '10': Day = nDAY-4
          '11': Day = nDAY-5
          '12': Day = nDAY-5
          '13': Day = 26 
        ENDCASE
        IF MOD_Date EQ 241 THEN BEGIN 
        MONTH = 8 
        Day = 28
        ENDIF
        IF MOD_Date EQ 273 THEN BEGIN
        MONTH = 9 
        Day = 29
        ENDIF
      ENDIF ELSE BEGIN
        MONTH = MOD_Date/30 + 1
        nDAY  = MOD_Date mod 30
        CASE MONTH OF
          '1': Day = nDAY
          '2': Day = nDAY-1
          '3': Day = nDay+1
          '4': Day = nDAY
          '5': Day = nDAY
          '6': Day = nDAY-1
          '7': Day = nDAY-1
          '8': Day = nDAY-2
          '9': Day = nDAY-3
          '10': Day = nDAY-3
          '11': Day = nDAY-4
          '12': Day = nDAY-4
          '13': Day = 27
        ENDCASE
        IF MOD_Date EQ 241 THEN BEGIN 
        MONTH = 8 
        Day = 29
        ENDIF
        IF MOD_Date EQ 273 THEN BEGIN
        MONTH = 9 
        Day = 30
        ENDIF
      ENDELSE
      IF MONTH EQ 13 THEN MONTH = 12       

      Date  = STRCOMPRESS(string(MOD_Year, Month, Day, Format = '(i4,"/",i2.2,"/",i2.2)'), /REMOVE_ALL)
                                   
      DATA = [MOD_Name,DATE,Lat,Lon,V_B1,V_B2,V_B3,V_B4,V_B5,V_B6,V_B7,V_B8,V_B9,V_B10]
      PRINTF, hFile, DATA, FORMAT = TYPE

      ENVI_FILE_MNG, ID=FID, /REMOVE    
    
    ENDFOR
    FREE_LUN, hFile     

END
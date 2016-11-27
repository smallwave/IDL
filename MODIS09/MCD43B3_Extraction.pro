PRO MCD43B3_Extraction

    FilePath   =  'D:\MCD43B3\'
    SHAPEFILE  =  'D:\MCD43B3\MCD43B3.shp'
;    GlacierPnt =  [87.2,45.2]
    TXTPath    =  'D:\MCD43B3\MCD43B3.txt'
    Head_String = ['Source', 'Date', 'Lat', 'Lon', 'B1', 'B2', 'B3', 'B4', 'B5', 'B6', 'B7', 'vis', 'nir', 'swir']
    OPENW, hFile, TXTPath, /GET_LUN
    Type   =  '(a16, 2X, a8, 2X, a5, 2X, a5, 2X, a5, 2X, a5, 2X, a5, 2X, a5, 2X, a5, 2X, a5, 2X, a5, 2X, a5, 2X, a5, 2X, a5)'  
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
;      PRINTF, hFile,MOD_Name
      ENVI_OPEN_FILE, File, R_FID = FID
      ENVI_FILE_QUERY, FID, NB = NB, DIMS = DIMS, BNAMES = BNAMES
      OSHP  =  Obj_New('IDLffShape', SHAPEFILE)
      OSHP->getproperty, n_entities=n_ent, Attribute_info=attr_info, $
                         n_attributes=n_attr, Entity_type=ent_type
                                                  
          FOR j=0,n_ent-1 do begin ;循环
            ent=oshp->getentity(j) ;读取第i个实体
            bounds    = ent.bounds ;读取实体的边界
            ENVI_CONVERT_FILE_COORDINATES, FID,  X_Pix, Y_Pix, bounds[0], bounds[1] ;坐标转换                              
          ; ENVI_CONVERT_FILE_COORDINATES, FID,  X_Pix, Y_Pix, X_Map, Y_Map;坐标转换               
            X_Pix = FIX(X_Pix[0])     
            Y_Pix = FIX(Y_Pix[0])        
            DIMS = [-1,X_Pix,X_Pix,Y_Pix,Y_Pix]
            Lat  = STRCOMPRESS(STRING(bounds[1]), /REMOVE_ALL)
            Lon  = STRCOMPRESS(STRING(bounds[0]), /REMOVE_ALL)
            
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
            
;            Value     = ENVI_GET_DATA(FID=FID,DIMS = DIMS, POS=0)            
;            V_B1 = STRCOMPRESS(STRING(value[X_Map,Y_Map]), /REMOVE_ALL)
;            Value     = ENVI_GET_DATA(FID=FID,DIMS = DIMS, POS=1)
;            V_B2 = STRCOMPRESS(STRING(value[X_Map,Y_Map]), /REMOVE_ALL)
;            Value     = ENVI_GET_DATA(FID=FID,DIMS = DIMS, POS=2)
;            V_B3 = STRCOMPRESS(STRING(value[X_Map,Y_Map]), /REMOVE_ALL)
;            Value     = ENVI_GET_DATA(FID=FID,DIMS = DIMS, POS=3)
;            V_B4 = STRCOMPRESS(STRING(value[X_Map,Y_Map]), /REMOVE_ALL)
;            Value     = ENVI_GET_DATA(FID=FID,DIMS = DIMS, POS=4)
;            V_B5 = STRCOMPRESS(STRING(value[X_Map,Y_Map]), /REMOVE_ALL)
;            Value     = ENVI_GET_DATA(FID=FID,DIMS = DIMS, POS=5)
;            V_B6 = STRCOMPRESS(STRING(value[X_Map,Y_Map]), /REMOVE_ALL)
;            Value     = ENVI_GET_DATA(FID=FID,DIMS = DIMS, POS=6)
;            V_B7 = STRCOMPRESS(STRING(value[X_Map,Y_Map]), /REMOVE_ALL)
;            Value     = ENVI_GET_DATA(FID=FID,DIMS = DIMS, POS=7)
;            V_B8 = STRCOMPRESS(STRING(value[X_Map,Y_Map]), /REMOVE_ALL)
;            Value     = ENVI_GET_DATA(FID=FID,DIMS = DIMS, POS=8)
;            V_B9 = STRCOMPRESS(STRING(value[X_Map,Y_Map]), /REMOVE_ALL)
;            Value     = ENVI_GET_DATA(FID=FID,DIMS = DIMS, POS=9)
;            V_B10 = STRCOMPRESS(STRING(value[X_Map,Y_Map]), /REMOVE_ALL)
            DATE = '20000219'            
                     
            DATA = [MOD_Name,DATE,Lat,Lon,V_B1,V_B2,V_B3,V_B4,V_B5,V_B6,V_B7,V_B8,V_B9,V_B10]
            PRINTF, hFile, DATA, FORMAT = TYPE
          ENDFOR
      PRINTF, hFile, FORMAT='(%" %s\n")'
      Obj_destroy,OSHP ;销毁一个shape对象
      ENVI_FILE_MNG, ID=FID, /REMOVE    
    
    ENDFOR
    FREE_LUN, hFile
    
    
  

END
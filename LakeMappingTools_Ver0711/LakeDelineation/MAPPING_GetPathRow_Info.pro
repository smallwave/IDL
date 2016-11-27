PRO MAPPING_GetPathRow_Info, WRSFile, DB_PathRows=PathRows

    ; Open a shapefile
    SHP_FID = OBJ_NEW('IDLffShape', WRSFile)
    ; Get the number of entities so we can parse through them.
    SHP_FID->GetProperty, N_ENTITIES=ShapeEntCount
    IF(ShapeEntCount LE 0) THEN BEGIN
       OBJ_DESTROY, SHP_FID
       PathRows = ['']
       RETURN
    ENDIF
    PathRows =  STRARR(ShapeEntCount)
    ; Read all the entities
    FOR i=0L, ShapeEntCount-1 DO BEGIN
     
        ; update the attributes of the entity
        attr     = SHP_FID->getAttributes(i)
        PathRows[i] = attr.ATTRIBUTE_0

    ENDFOR
    ; Close the Shapefile.
    OBJ_DESTROY, SHP_FID

END
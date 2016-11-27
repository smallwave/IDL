

PRO MAPPING_GetPathRow_Shoreline, ShorelineVectorFile, DB_PathRows=PathRows

    ; Open a shapefile
    Shoreline_SHP = OBJ_NEW('IDLffShape', ShorelineVectorFile)
    ; Get the number of entities so we can parse through them.
    Shoreline_SHP->GetProperty, N_ENTITIES=ShapeEntCount
    IF(ShapeEntCount LE 0) THEN BEGIN
       OBJ_DESTROY, Shoreline_SHP
       PathRows = ['']
       RETURN
    ENDIF
    PathRows =  STRARR(ShapeEntCount)
    ; Read all the entities
    FOR i=0L, ShapeEntCount-1 DO BEGIN
     
        ; update the attributes of the entity
        attr     = Shoreline_SHP->getAttributes(i)
        PathRows[i] = attr.ATTRIBUTE_1

    ENDFOR
    ; Close the Shapefile.
    OBJ_DESTROY, Shoreline_SHP

END
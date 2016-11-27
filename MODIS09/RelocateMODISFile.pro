

PRO RelocateMODISFile, MODIS_DIR, OUT_DIR, MOD_TYPE, sDATE
    
    siz = SIZE(sDATE)
    nDIRCount = siz[1]
    ; First, build the new directory in OUT_DIR
    ; sub DIR name
    
    FOR i=0, nDIRCount-1 DO BEGIN
        SubDIRName = MOD_TYPE + '_' + sDATE[i]
        SearchStr  = MOD_TYPE + '.' + sDATE[i]+'*'
        SUB_DIR    = OUT_DIR + SubDIRName 
        IF(FILE_TEST(SUB_DIR, /DIRECTORY) EQ 0) THEN FILE_MKDIR,SUB_DIR
        MODISFiles = FILE_SEARCH(MODIS_DIR,SearchStr, COUNT = nMODISCount, /TEST_READ, /FULLY_QUALIFY_PATH)
        IF(nMODISCount LE 0) THEN CONTINUE
        FOR j=0, nMODISCount-1 DO BEGIN
            FILE_MOVE, MODISFiles[j], SUB_DIR
        ENDFOR   
        FILE_DELETE,MODIS_DIR     
    ENDFOR   
     
END
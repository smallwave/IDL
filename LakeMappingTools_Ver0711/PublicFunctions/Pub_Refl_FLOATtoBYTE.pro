Pro Pub_Refl_FLOATtoBYTE
  
    ; ############################################################
    ; Temporary variables, just for testing
    DataFile_DIR = 'E:\Tibetan_TM1990\LandsatTM_LakeDyamics\Ref\'
    ByteFile_DIR = 'H:\Tibet_LandsatTM\TM_Refl\'
    ; ############################################################

    ; Find landsat files in the give directory
    DataFilePaths  = file_search(DataFile_DIR,'*.dat', COUNT = FileCount, $
                                    /TEST_READ, /FULLY_QUALIFY_PATH)
    ; Initialize ENVI
    print, 'Start time is: ', systime()
    logProcedureFileName = 'Landsat_Ref.txt'
    ENVI, /RESTORE_BASE_SAVE_FILES
    ENVI_BATCH_INIT, LOG_FILE = logProcedureFileName,/NO_STATUS_WINDOW 
    envi_batch_status_window, /off  
    for i=0, FileCount-1 do begin
         
        ; Get general information from the landsat file names
        FloatFileName = DataFilePaths[i]
        FileName      = file_basename(FloatFileName)
        BYTEFileName  = ByteFile_DIR + FileName
        PRINT, 'FtoB  ', STRTRIM(STRING(i+1),2), ':', FloatFileName,' ...'
        ; Load the Landsat Files
       ENVI_OPEN_FILE, FloatFileName, R_FID = IMG_FID
       IF(IMG_FID EQ -1) THEN CONTINUE
       
       ; [2.1] Width, Height, Band dimensions,starting sample and row of the image
       ENVI_FILE_QUERY, IMG_FID, NB=NB, NS=NS, NL=NL, DIMS=DIMS,BNAMES=BNAMES
       ; Map information
       MapInfo  = ENVI_GET_MAP_INFO(FID=IMG_FID)
       ; Projection information
       Proj     = ENVI_GET_PROJECTION(FID=IMG_FID, PIXEL_SIZE=PS)
       
       Band1    = ENVI_GET_DATA(FID=IMG_FID, DIMS=DIMS, POS=[0])
       Band2    = ENVI_GET_DATA(FID=IMG_FID, DIMS=DIMS, POS=[1])
       Band3    = ENVI_GET_DATA(FID=IMG_FID, DIMS=DIMS, POS=[2])
       Band4    = ENVI_GET_DATA(FID=IMG_FID, DIMS=DIMS, POS=[3])
       Band5    = ENVI_GET_DATA(FID=IMG_FID, DIMS=DIMS, POS=[4])
       Band6    = ENVI_GET_DATA(FID=IMG_FID, DIMS=DIMS, POS=[5])
       
       Band1    = (Band1*255)
       Band2    = (Band2*255)
       Band3    = (Band3*255)
       Band4    = (Band4*255)
       Band5    = (Band5*255)
       Band6    = (Band6*255)
       
       MASK = (Band1 GT 0) AND (Band2 GT 0) AND (Band3 GT 0) $
              AND (Band4 GT 0) AND (Band5 GT 0) AND (Band6 GT 0)
       idx = WHERE(Band1 GE 255,nCount)
       if(nCount GT 0) THEN Band1[idx] = 255
       idx = WHERE(Band2 GE 255,nCount)
       if(nCount GT 0) THEN Band2[idx] = 255
       idx = WHERE(Band3 GE 255,nCount)
       if(nCount GT 0) THEN Band3[idx] = 255
       idx = WHERE(Band4 GE 255,nCount)
       if(nCount GT 0) THEN Band4[idx] = 255
       idx = WHERE(Band5 GE 255,nCount)
       if(nCount GT 0) THEN Band5[idx] = 255
       idx = WHERE(Band6 GE 255,nCount)
       if(nCount GT 0) THEN Band6[idx] = 255
       
       Band1 = BYTE(MASK * Band1)
       Band2 = BYTE(MASK * Band2)
       Band3 = BYTE(MASK * Band3)
       Band4 = BYTE(MASK * Band4)
       Band5 = BYTE(MASK * Band5)
       Band6 = BYTE(MASK * Band6)
       
       ENVI_ENTER_DATA, TEMPORARY(Band1), BNAMES=['Band 1'], FILE_TYPE=FILE_TYPE,$
                        MAP_INFO=MapInfo,R_FID=B1_FID
       ENVI_ENTER_DATA, TEMPORARY(Band2), BNAMES=['Band 2'], FILE_TYPE=FILE_TYPE,$
                        MAP_INFO=MapInfo,R_FID=B2_FID
       ENVI_ENTER_DATA, TEMPORARY(Band3), BNAMES=['Band 3'], FILE_TYPE=FILE_TYPE,$
                        MAP_INFO=MapInfo,R_FID=B3_FID
       ENVI_ENTER_DATA, TEMPORARY(Band4), BNAMES=['Band 4'], FILE_TYPE=FILE_TYPE,$
                        MAP_INFO=MapInfo,R_FID=B4_FID
       ENVI_ENTER_DATA, TEMPORARY(Band5), BNAMES=['Band 5'], FILE_TYPE=FILE_TYPE,$
                        MAP_INFO=MapInfo,R_FID=B5_FID
       ENVI_ENTER_DATA, TEMPORARY(Band6), BNAMES=['Band 7'], FILE_TYPE=FILE_TYPE,$
                        MAP_INFO=MapInfo,R_FID=B7_FID
       nFIDs  = [B1_FID,B2_FID,B3_FID,B4_FID,B5_FID,B7_FID]
       nPOS   = [0,0,0,0,0,0]
       nDIMS   = lonarr(5,6)
       for j=0,5 do nDIMS[0,j] = [-1, 0, NS-1, 0, NL-1]
       BandNames = ['Band 1','Band 2','Band 3','Band 4','Band 5','Band 7']
        ; Call the layer stacking routine.
       ENVI_DOIT, 'ENVI_LAYER_STACKING_DOIT', FID=nFIDs,POS=nPOS,DIMS=nDIMS, $
                OUT_DT=1, OUT_BNAME=BandNames, INTERP=0, OUT_PS=PS, $
                OUT_PROJ=Proj, OUT_NAME=BYTEFileName, R_FID=STACK_FID      
       ENVI_FILE_MNG, ID=IMG_FID, /REMOVE
       ENVI_FILE_MNG, ID=STACK_FID, /REMOVE
       ENVI_FILE_MNG, ID=B1_FID, /REMOVE
       ENVI_FILE_MNG, ID=B2_FID, /REMOVE
       ENVI_FILE_MNG, ID=B3_FID, /REMOVE
       ENVI_FILE_MNG, ID=B4_FID, /REMOVE
       ENVI_FILE_MNG, ID=B5_FID, /REMOVE
       ENVI_FILE_MNG, ID=B7_FID, /REMOVE

   ENDFOR
   PRINT, 'FINISHED!'
END
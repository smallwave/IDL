Pro Pub_Band4_Dividedby2
  
    ; ############################################################
    ; Temporary variables, just for testing
    DataFile_DIR = 'H:\Tibet_LandsatMSS\MSS_Proj\13\'
    ByteFile_DIR = 'H:\Tibet_LandsatMSS\MSS_Proj\'
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
    FOR i=0, FileCount-1 DO BEGIN
         
        ; Get general information from the landsat file names
        RefFile    = DataFilePaths[i]
        FileName   = file_basename(RefFile)
        Ref_DivFile  = ByteFile_DIR + FileName
        PRINT, 'Band4/2  ', STRTRIM(STRING(i+1),2), ':', RefFile,' ...'
        ; Load the Landsat Files
        ENVI_OPEN_FILE, RefFile, R_FID = IMG_FID
        IF(IMG_FID EQ -1) THEN CONTINUE
       
       ; [2.1] Width, Height, Band dimensions,starting sample and row of the image
       ENVI_FILE_QUERY, IMG_FID, NB=NB, NS=NS, NL=NL, DIMS=DIMS,BNAMES=BNAMES
       ; Map information
       MapInfo  = ENVI_GET_MAP_INFO(FID=IMG_FID)
       ; Projection information
       Proj     = ENVI_GET_PROJECTION(FID=IMG_FID, PIXEL_SIZE=PS)
       
       ; Load the data
       nBand = BYTARR(NS,NL,NB)
       FOR j=0,NB-1 DO nBand[*,*,j] = ENVI_GET_DATA(FID=IMG_FID,DIMS=DIMS, POS=[j])
       
       nBand[*,*,3] = BYTE(nBand[*,*,3]*2)
       
       ENVI_ENTER_DATA, nBand, MAP_INFO=MapInfo, R_FID=DIV_FID
       ENVI_FILE_QUERY, DIV_FID, DIMS=nDIMS
       nPOS     = LINDGEN(NB) 
       ENVI_OUTPUT_TO_EXTERNAL_FORMAT, FID=DIV_FID,POS=nPOS,DIMS=nDIMS,$
                                       OUT_BNAME=BNAMES, OUT_NAME=Ref_DivFile, /ENVI
    
       ENVI_FILE_MNG,ID=DIV_FID, /REMOVE                  
       ENVI_FILE_MNG,ID=IMG_FID,  /REMOVE
       ; remove all the FIDs in the file lists
       FIDS = ENVI_GET_FILE_IDS()
       FOR j = 0, N_ELEMENTS(FIDS) - 1 DO BEGIN
           IF(FIDS[j] NE -1) THEN  ENVI_FILE_MNG, ID = FIDS[j], /REMOVE
       ENDFOR

   ENDFOR
   PRINT, 'FINISHED!'
END
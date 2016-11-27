PRO Pub_Band4Generation

    ; ########################################################################
    ; Temporary variables, just for testing
    Landsat_DIR     = 'E:\Tibetan_MSS1970s\MSS_ENVI1\'       
    Band4_DIR       = 'E:\Tibetan_MSS1970s\'
    
    ; ########################################################################
    
    ;*************************************************************************
    ; Initilize the procedure parameters
    ;*************************************************************************
    
    IF(Landsat_DIR EQ '' OR Band4_DIR EQ '') THEN BEGIN
       MESSAGE, 'The given directory is invalid.'
       RETURN
    ENDIF
    LandsatFilePaths = FILE_SEARCH(Landsat_DIR,'*.dat', COUNT=FileCount,$
                                   /TEST_READ, /FULLY_QUALIFY_PATH) 
    IF(FileCount LE 0) THEN BEGIN
        PRINT, 'There are no valid Landsat files in the given directory.'
        RETURN
    ENDIF
    
    ;*************************************************************************
    ;
    ; Create log file to save the processing logs
    ;
    ;*************************************************************************
    BatchFile        = Landsat_DIR + 'BatchLogFile.txt'
    GET_LUN, LogHFile
    OPENW, LogHFile, BatchFile
    ; Begin to write processing log in the file
    PRINTF,LogHFile,'___________________Begin Procedure_________________'
    PRINTF,LogHFile, SYSTIME()
    PRINTF,LogHFile, 'There are ' + String(FileCount) + $
                     ' Landsat Files altogether to be processed'
    ; Initialize ENVI and store all errors and warnings
    ENVI, /RESTORE_BASE_SAVE_FILES
    ENVI_BATCH_INIT, LOG_FILE = logProcedureFileName
    
    ;***************************************************************************
    ;
    ; Loop procedures to extract lake from the landsat scenes
    ;
    ;***************************************************************************
    nTotalMinutes = 0.0
    FOR i=0, FileCount-1 DO BEGIN

        LandsatFileName = LandsatFilePaths[i]
        ; Remove '.hdr' of the LandsatFileName
        FileName = STRMID(LandsatFileName, 0, STRLEN(LandsatFileName)-4)
        ; Get the base file name (without directory)
        FileName  = FILE_BASENAME(FileName)
        ; WRS 1/2 Path and Row info
        sPathRow  = STRMID(FileName,0,8)
        ; Get the Sensor info
        SensorID  = STRMID(FileName,9,3)
       ; Acq Date
        sAcqDate  = STRMID(FileName,13,8)
                               
        ; Generate the raster and vector Lake file paths
        Band4File  = Band4_DIR + FileName  + '_Band3'
        ;        
        PRINT, STRTRIM(STRING(i+1),2)+ ': '+LandsatFileName + '  is being Processed'
        PRINTF,LogHFile, LandsatFileName + '  is being Processed'
        time_begin      = SYSTIME(1,/SECONDS)
        
        ; [2] Load the raster file to memory and get the basic image information
        ENVI_OPEN_FILE, LandsatFileName, R_FID = IMG_FID
        ; Width, Height, Band dimensions,starting sample and row of the image
        ENVI_FILE_QUERY, IMG_FID, NS=Width, NL=Height, DIMS=DIMS
        ; map information
        MapInfo  = ENVI_GET_MAP_INFO(FID=IMG_FID)
        ; projection information
        Proj     = ENVI_GET_PROJECTION(FID=IMG_FID, PIXEL_SIZE=PS, UNITS=Units)
        ;
        bRef = GLOVIS_Landsat_Reflectance(IMG_FID, sAcqDate, SensorID, 3, BANDREF=Band4)
        ; Close the image file
        ENVI_FILE_MNG, ID=IMG_FID, /REMOVE
        
        IF(bRef EQ 0) THEN BEGIN
           STR_ERROR = LandsatFileName + ': could not get the reflectance of Band 4!'
           RETURN
        ENDIF

;        Band4 = BYTE(Band4*255)
        ; save to external ENVI file
        FTYPE   = ENVI_FILE_TYPE('ENVI Standard')
        ENVI_ENTER_DATA, Band4, BNAMES=['Band4'],FILE_TYPE=FTYPE,MAP_INFO=MapInfo,$
                         PIXEL_SIZE=PS, UNITS=Units, R_FID=Band4_FID
        ENVI_OUTPUT_TO_EXTERNAL_FORMAT, FID=Band4_FID,POS=[0],DIMS=DIMS,$
                         OUT_BNAME=['Band4'], OUT_NAME=Band4File, /ENVI
        ENVI_FILE_MNG, ID=Band4_FID,/REMOVE
    
        FIDS = ENVI_GET_FILE_IDS()
        ncount=n_elements(FIDS)
        if(ncount ge 1) then begin
           for j = 0, ncount-1 DO begin
               if(FIDS[j] NE -1) then  ENVI_FILE_MNG, ID=FIDS[j], /REMOVE
           endfor
        endif
                    
        time_end   = SYSTIME(1,/SECONDS)
        PRINT, 'Processing time: '+STRING(time_end-time_begin) + ' seconds'
        nTotalMinutes = nTotalMinutes + (time_end-time_begin)/60.0
    ENDFOR
    
    PRINT, 'The total processing time for water extraction is : ' + $
                     STRING(nTotalMinutes) + ' minutes'
    FREE_LUN, LogHFile
     
END
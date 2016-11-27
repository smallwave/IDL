;******************************************************************************
;; $Id: envi45_config/Program/LakeMappingTools/SRTM_PreProcess_RemoveBadPixels.pro$
;;
;; Author: Junli LI, Geography Department of UCLA, Los Angeles, CA 90095
;+
;; NAME:
;;   SRTM_01PreProcess_RemoveBadPixels
;;
;; PURPOSE:
;;   The procedure convert the hgt SRTM grid files(1 degree* 1 degree ) to 
;l   ENVI files, then remove the bad pixels from the original files
;;
;; PARAMETERS:
;;   SRTM_DIR(in) - input SRTM_DIR grid file directory (.hgt files)
;;
;;   DEM_DIR(in)  - input DEM file directory
;;
;; OUTPUTS:
;;
;; CALLING CUSTOM-DEFINED FUNCTIONS: 
;;
;; PROCEDURES OR FUNCTIONS CALLED: 
;;
;; MODIFICATION HISTORY:
;;   Written by:  Junli LI, 2009/04/23 12:00 AM
;-
;******************************************************************************

PRO SRTM_01PreProcess_RemoveBadPixels, SRTM_DIR, DEM_DIR
   
    ; ############################################################
    ;
    SRTM_DIR  = 'H:\TibetanPlateau_DEM\'
    DEM_DIR   = 'H:\TibetanPlateau_DEM1\'
    ;
    ; ############################################################
    
    IF( FILE_TEST(SRTM_DIR, /DIRECTORY) EQ 0 OR $
        FILE_TEST(DEM_DIR, /DIRECTORY) EQ 0) THEN BEGIN
        MESSAGE, 'The given directory is invalid.'
        RETURN
    ENDIF
    ; Find SRTM files in the give directory
    SRTMFilePaths  = FILE_SEARCH(SRTM_DIR,'*.hgt', COUNT = FileCount,$
                                 /TEST_READ, /FULLY_QUALIFY_PATH)

    ; Create log file to save the processing logs
    BatchFile       = SRTM_DIR + 'SRTMBatchLog.txt'
    GET_LUN, LogH
    OPENW, LogH, BatchFile
    ; Begin to write processing log in the file
    PRINTF,LogH, '_________________Begin Procedure__________________'
    PRINTF,LogH, '                                                  '
    PRINTF,LogH, 'There are ' + STRING(FileCount) + '  SRTM Files'
    PRINTF,LogH, 'Loop procedures is starting at  ', + SYSTIME()

    ;**************************************************************************
    ; Loop procedures to extract convert SRTM files to DEM ENVI standard files
    ;**************************************************************************
    
    ; some bad file that can't read, write these file in batch files
    nBadCount          = 0
    time_begin     = SYSTIME(1,/SECONDS)
    ; Set the variable for water extraction
    FOR i=0, FileCount-1 DO BEGIN

        SRTMFilePath   = SRTMFilePaths[i]
        SRTMFileName   = FILE_BASENAME(SRTMFilePath)
        SRTMFileName   = STRMID(SRTMFileName, 0, STRLEN(SRTMFileName)-4)
        DEMFilePath    = DEM_DIR + SRTMFileName
        
         ; [2] Load the SRTM file and get the basic image information
         ENVI_OPEN_FILE, SRTMFilePath, R_FID = SRTM_FID
         IF(SRTM_FID EQ -1) THEN BEGIN
            nBadCount  = nBadCount+1
            ERR_String = 'Error '+STRTRIM(STRING(nBadCount),2) + ' : '
            ERR_String = ERR_String + SRTMFileName + ' could not be opened.'
            PRINTF,LogH, ERR_String
            ERR_String = 'Source File location is: ' + SRTMFilePath
            PRINTF,LogH, ERR_String
            PRINTF,LogH, '                                                  '
            CONTINUE
         ENDIF
         ; [2.1] Width, Height, Band Count, dimensions, Data type of the image
         ENVI_FILE_QUERY, SRTM_FID, NS = Width, NL = Height, NB = BandCount, $
                          DIMS = DIMS, OUT_BNAME=BNAME
         ENVI_DOIT, 'DEM_BAD_DATA_DOIT',FID=SRTM_FID,DIMS=DIMS,OUT_BNAME=BNAME,$
                    POS=[0],BAD_VALUE=-32768,OUT_NAME=DEMFilePath,R_FID=DEM_FID 
         ENVI_FILE_MNG, ID = SRTM_FID, /REMOVE
         ENVI_FILE_MNG, ID = DEM_FID, /REMOVE
   
    ENDFOR
    time_end        = SYSTIME(1,/SECONDS)
    PRINTF,LogH, 'time used: ' + STRTRIM(STRING(time_end-time_begin),2) + ' seconds.'
    PRINTF,LogH, '__________________________ End Procedure __________________________'
    FREE_LUN, LogH

END
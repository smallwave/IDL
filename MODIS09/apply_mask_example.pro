PRO apply_mask_example 
 
; Initialize ENVI 
ENVI, /RESTORE_BASE_SAVE_FILES 
ENVI_BATCH_INIT, LOG_FILE = 'batch_log.txt' 
 
; Set the input and output file names 
out_name = 'E:\Modis_reference\MODIS_Sample\test\MODIS_MidAsia_sub.dat' 
    FILE = 'E:\Modis_reference\MODIS_Sample\MODIS_MidAsia_sub.dat'
    MASK = 'E:\Modis_reference\MODIS_Sample\MidAsia_Mask_test'
;FILE = 'E:\Modis_reference\MODIS_Sample\MOD13A2_A2002241_MidAsia.dat'
;MASK = 'E:\Modis_reference\MODIS_Sample\MidAsia_Mask'

ENVI_OPEN_FILE, FILE, R_FID = fid 
ENVI_OPEN_FILE, MASK, R_FID = m_fid 
IF (fid EQ -1 OR m_fid EQ -1) THEN BEGIN 
   ENVI_BATCH_EXIT 
   RETURN 
ENDIF 
 
; Get some useful information about the input data. 
ENVI_FILE_QUERY, fid, dims=dims, NB = nb 
 
; Set the keyword parameters 
pos  = LINDGEN(nb) 
m_pos = [0] 
 
; Call the 'doit' 
ENVI_MASK_APPLY_DOIT, FID = fid, POS = pos, DIMS = dims, $ 
   M_FID = m_fid, M_POS = m_pos, VALUE = 0, OUT_NAME = out_name, $ 
   IN_MEMORY = 0, R_FID = r_fid 
 
; Exit ENVI 
ENVI_BATCH_EXIT 
 
END 

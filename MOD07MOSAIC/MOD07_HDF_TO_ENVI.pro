;+--------------------------------------------------------------------------
;| MOD07_HDF_TO_ENVI
;+--------------------------------------------------------------------------
FUNCTION MOD07_HDF_TO_ENVI, MODISFilePaths,TIFFDirectory,ExtractionVar

  FileCount  = SIZE(MODISFilePaths,/N_ELEMENTS)

  IF(FileCount LE 0) THEN RETURN, 0

  FOR j=0, FileCount-1 DO BEGIN

    modis_swath_file    = MODISFilePaths[j]

    FileName            = FILE_BASENAME(modis_swath_file)

    swath_name = 'mod07'

    output_rootname      = STRMID(FileName, 0, STRLEN(FileName)-4) + "_" + ExtractionVar


    ;Output method schema is:
    ;0 = Standard, 1 = Projected, 2 = Standard and Projected
    out_method = 1

    output_projection = envi_proj_create(/geographic)

    ;Choosing nearest neighbor interpolation
    interpolation_method = 0

    ;do not put the bridge creation/destruction code inside a loop
    bridges = mctk_create_bridges()

    convert_modis_data, in_file=modis_swath_file, $
      out_path=TIFFDirectory, out_root=output_rootname, $
      swt_name=swath_name, sd_names= ExtractionVar, $
      out_method=out_method, out_proj=output_projection, $
      interp_method=interpolation_method, /no_msg, $
      r_fid_array=r_fid_array, r_fname_array=r_fname_array, $
      bridges=bridges, msg=msg
    mctk_destroy_bridges, bridges


  ENDFOR  ; file

  RETURN , 1

END
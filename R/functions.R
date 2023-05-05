

# extract values from a raster file, which has units
extract_with_units <- function(rasterfile, vector, output_unit = NULL, fun = "mean"){
  input_unit <- units(rasterfile)
  stopifnot(input_unit != "")
  if(is.null(output_unit)){
    output_unit <- input_unit
  }
  vector_vect <- vect(vector)
  extracted <- terra::extract(rasterfile,vector_vect,fun = fun)[,2]
  extracted |>
    units::set_units(input_unit,mode = "standard") |>
    set_units(output_unit,mode = "standard")
}


global_with_units <- function(raster, fun = "mean", na.rm = TRUE, output_unit = NULL){
  input_unit <- units(raster)
  stopifnot(input_unit != "")
  if(is.null(output_unit)){
    output_unit <- input_unit
  }
  
  res <- global(raster, fun, na.rm = na.rm)
  
  res <- res[,1]
  units(res) <- input_unit
  set_units(res, output_unit,mode = "standard")
}

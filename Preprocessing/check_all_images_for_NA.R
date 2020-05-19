library("raster")
library(rgdal)

rgb_out_path = "D:/Masterarbeit/Data/raw_terrain_data/"

srtm_path <- paste0(rgb_out_path, "tf_data/test/SRTM/subfolder/")
srtm_files <- list.files(path = srtm_path, pattern = "*.tif$")


for (filenamee in srtm_files) {
  rgb <- stack(paste0(srtm_path, filenamee))
  if (any(is.na(getValues(rgb))) == TRUE) {
    paste("DELETE:" , filenamee)}
}

  srtm_path <- paste0(rgb_out_path,"tf_data/test/WOKAM/subfolder/")
  srtm_files <- list.files(path = srtm_path, pattern = "*.tif$")
  
  
  for (filenamee in srtm_files) {
    rgb <- stack(paste0(srtm_path, filenamee))
    if (any(is.na(getValues(rgb))) == TRUE) {
      paste("DELETE:" , filenamee)}
    }
    
    srtm_path <- paste0(rgb_out_path,"tf_data/train/SRTM/subfolder/")
    srtm_files <- list.files(path = srtm_path, pattern = "*.tif$")
    
    
    for (filenamee in srtm_files) {
      rgb <- stack(paste0(srtm_path, filenamee))
      if (any(is.na(getValues(rgb))) == TRUE) {
        paste("DELETE:" , filenamee)}
      }
      
      srtm_path <- paste0(rgb_out_path,"tf_data/train/SRTM/subfolder/")
      srtm_files <- list.files(path = srtm_path, pattern = "*.tif$")
      
      
      for (filenamee in srtm_files) {
        rgb <- stack(paste0(srtm_path, filenamee))
        if (any(is.na(getValues(rgb))) == TRUE) {
          paste("DELETE:" , filenamee)}
        }
library("raster")
library(rgdal)
library("spatial.tools")

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
      
lidar_path <- paste0("D:/Masterarbeit/Data/high_res/slovenia_1m/tiff/lidar/")
lidar_files <- list.files(path = lidar_path, pattern = "*.tif$")

mask_path <- paste0("D:/Masterarbeit/Data/high_res/slovenia_1m/tiff/mask/")
mask_files <- list.files(path = mask_path, pattern = "*.tif$")

mask_files <- lidar_files[which(!(lidar_files %in% mask_files))]
mask_files <- mask_files[mask_files %in% lidar_files]

lidar_files <- lidar_files[lidar_files %in% mask_files]
lidar_files <- lidar_files[mask_files %in% lidar_files]

all(lidar_files %in% mask_files)
all(lidar_files == mask_files)


for (lassfile in lidar_files[1:ceiling(0.8*length(lidar_files))]) {
  
  dtm <- raster(paste0(lidar_path, lassfile))
  maske <- raster(paste0(mask_path, lassfile))
  
  if (all(dim(dtm) >= c(1000,1000,1) & dim(maske) >= c(1000,1000,1))) {
    
    dtm <- crop(dtm, extent(dtm, 1, 1000, 1, 1000))
    maske <- crop(maske, extent(maske, 1, 1000, 1, 1000))
    
    writeRaster(maske, 
                paste0("D:/Masterarbeit/Data/high_res/slovenia_1m/tf_data/train/WOKAM/subfolder/", lassfile),
                format = "GTiff",
                datatype = "FLT4S",
                overwrite = TRUE)
    writeRaster(dtm, 
                paste0("D:/Masterarbeit/Data/high_res/slovenia_1m/tf_data/train/LIDAR/subfolder/", lassfile),
                format = "GTiff",
                datatype = "FLT4S",
                overwrite = TRUE)
  }
}

for (lassfile in lidar_files[175:217]) {
  
  dtm <- raster(paste0(lidar_path, lassfile))
  maske <- raster(paste0(mask_path, lassfile))
  
  if (all(dim(dtm) >= c(1000,1000,1) & dim(maske) >= c(1000,1000,1))) {
    
    dtm <- crop(dtm, extent(dtm, 1, 1000, 1, 1000))
    maske <- crop(maske, extent(maske, 1, 1000, 1, 1000))
    
    writeRaster(maske, 
                paste0("D:/Masterarbeit/Data/high_res/slovenia_1m/tf_data/test/WOKAM/subfolder/", lassfile),
                format = "GTiff",
                datatype = "FLT4S",
                overwrite = TRUE)
    writeRaster(dtm, 
                paste0("D:/Masterarbeit/Data/high_res/slovenia_1m/tf_data/test/LIDAR/subfolder/", lassfile),
                format = "GTiff",
                datatype = "FLT4S",
                overwrite = TRUE)
  }
}

# Four large normalized raster datasets "srtm.tif" a digital elevation model, slope data "slope.tif", and flow direction "flowdir.tif", and 
# "wokam.tif", binary data to indicate karst areas, are clipped to the extent of the Balkans and preprocessed into tiles to 
# be fed to a convolutional neural network for image segmentation.
#
# 1- clip ot balkan extent
# 2- split into tiles

# LIBRARIES AND PATHS -----------------------------------------------------

library("scales")
library("raster")
library(rgdal)

# Set temporary directory on D:/ 
rasterOptions(tmpdir = "D:/rtmp/")
write("R_USER = D:/rtmp/", file = file.path(Sys.getenv('R_USER'), '.Renviron'))

slope_norm <- raster( "D:/Masterarbeit/Data/normalized/slope/slope.tif")
srtm_norm <- raster( "D:/Masterarbeit/Data/normalized/srtm/srtm.tif")
flowdir_norm <- raster( "D:/Masterarbeit/Data/normalized/flowdir/flowdir.tif")
mask <- raster("D:/Masterarbeit/Data/wokam/wokam_bin.tif")

crop_extent <- readOGR("D:/Masterarbeit/Data/Balkans/Balkans_extent_poly.shp")

# crop the DEM rasters using the vector extent
slope_norm_crop <- crop(slope_norm, crop_extent)
srtm_norm_crop <- crop(srtm_norm, crop_extent)
flowdir_norm_crop <- crop(flowdir_norm, crop_extent)
wokam_crop <- crop(mask, crop_extent)

# take a look at it
plot(slope_norm_crop, main = "Cropped slope")
plot(crop_extent, add = TRUE)

ceiling(nrow(slope_norm_crop) / 93.5)
ceiling(ncol(slope_norm_crop) / 118)

# CREATE TILES -----------------------------------------------------

SplitRas <- function(raster, path) {
  h        <- ceiling(ncol(raster) / 118)
  v        <- ceiling(nrow(raster) / 93.5)
  agg      <- aggregate(raster, fact = c(h, v))
  agg[]    <- 1:ncell(agg)
  agg_poly <- rasterToPolygons(agg)
  names(agg_poly) <- "polis"
  for (i in 1:ncell(agg)) {
    e1          <- extent(agg_poly[agg_poly$polis == i, ])
    crop <- crop(raster, e1)
    print(paste0("processing tile:", i))
    writeRaster(
      crop,
      filename = paste0(path,"tile", i),
      format = "GTiff",
      datatype = "FLT4S",
      overwrite = TRUE
    )
    
  }
}


SplitRas(srtm_norm_crop,path = "D:/Masterarbeit/Data/Balkans/tiles_srtm/")
SplitRas(slope_norm_crop,path = "D:/Masterarbeit/Data/Balkans/tiles_slope/")
SplitRas(flowdir_norm_crop,path = "D:/Masterarbeit/Data/Balkans/tiles_flowdir/")
SplitRas(wokam_crop,path = "D:/Masterarbeit/Data/Balkans/tiles_wokam/")

# ONLY BORDERING AREAS -----------------------------------------------------

srtm_path <- "D:/Masterarbeit/Data/Balkans/tiles_srtm/"
srtm_files <- list.files(path = srtm_path, pattern = "*.tif$")

slope_path <- "D:/Masterarbeit/Data/Balkans/tiles_slope/"
slope_files <- list.files(path = slope_path, pattern = "*.tif$")

flowdir_path <- "D:/Masterarbeit/Data/Balkans/tiles_flowdir/"
flowdir_files <- list.files(path = flowdir_path, pattern = "*.tif$")

mask_path <- "D:/Masterarbeit/Data/Balkans/tiles_wokam/"
mask_files <- list.files(path = mask_path, pattern = "*.tif$")


for (i in 1:length(mask_files)) {
  print(paste0(i, ":", "processing tile:", mask_files[i]))
  
  ras <- raster(paste0(srtm_path, mask_files[i]))
  slope <-  raster(paste0(slope_path, mask_files[i]))
  flow <-  raster(paste0(flowdir_path, mask_files[i]))
  
  mask <- raster(paste0(mask_path, mask_files[i]))
  
  
  if (sum(is.na(getValues(ras))) == 0 ) {
    
    rgb <- stack(ras, slope, flow)
    
    writeRaster(
      rgb,
      filename = paste0("D:/Masterarbeit/Data/Balkans/rgb/", mask_files[i]),
      format = "GTiff",
      datatype = "FLT4S",
      overwrite = TRUE)
    
    writeRaster(
      mask,
      filename = paste0("D:/Masterarbeit/Data/Balkans/wokam/", mask_files[i]),
      format = "GTiff",
      datatype = "FLT4S",
      overwrite = TRUE)
  }
}

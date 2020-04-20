
# PREPROCESSING -----------------------------------------------------------
# Two large raster datasets "srtm.tif", a digital elevation model, and 
# "wokam.tif", binary data to indicate karst areas, are preprocessed to 
# be fed to a convolutional neural network for image segmentation.
#
# 1- normalize the rasters
# 2- split large raster data into smaller areas
# 3- combine RGB images and save as tif

# Set temporary directory on D:/ 
rasterOptions(tmpdir = "D:/rtmp/")
write("R_USER = D:/rtmp/", file = file.path(Sys.getenv('R_USER'), '.Renviron'))

library("spatialEco")
library("scales")
library("raster")
library(rgdal)

srtm <- raster("D:/Masterarbeit/Data/srtm/srtm.tif")

srtm_rescaled <- raster.transformation(srtm, trans = "stretch")#, smin=0, smax = 4080)

writeRaster(srtm_rescaled ,"D:/Masterarbeit/Data/rescaled/srtm.tif",overwrite = T,format = "GTiff")

slope <- raster("D:/Masterarbeit/Data/slope/slope.tif")

srtm_slope <- raster.transformation(slope, trans = "stretch", smin=0, smax = 1.47926)
writeRaster(srtm_slope ,"D:/Masterarbeit/Data/rescaled/slope.tif",overwrite = T,format = "GTiff")

flowdir <- raster("D:/Masterarbeit/Data/flowdir/flowdir.tif")
srtm_flowdir <- raster.transformation(flowdir, trans = "stretch")#, smin=0, smax = 128)
writeRaster(srtm_flowdir ,"D:/Masterarbeit/Data/rescaled/flowdir.tif",overwrite = T,format = "GTiff")

stack_normalized <- stack(img_mask,srtm_rescaled, srtm_flowdir, srtm_slope)
terrain_stack_norm <- data.frame(sampleRandom(stack_normalized, 10000))

# fm_multi_norm <- glm(wokam_bin ~ (srtm + slope + flowdir),
#                 family = "binomial",
#                 data = terrain_stack_norm)
# summary(fm_multi_norm)


writeRaster(
  srtm_slope ,
  "D:/Masterarbeit/Data/normalized/slope/slope.tif",
  overwrite = T,
  format = "GTiff"
)


writeRaster(
  srtm_flowdir,
  "D:/Masterarbeit/Data/normalized/flowdir/flowdir.tif",
  overwrite = T,
  format = "GTiff"
)

writeRaster(
  srtm_rescaled,
  "D:/Masterarbeit/Data/normalized/srtm/srtm.tif",
  overwrite = T,
  format = "GTiff"
)

# CREATE TILES -----------------------------------------------------

SplitRas <- function(raster, path) {
  h        <- ceiling(ncol(raster) / 375)
  v        <- ceiling(nrow(raster) / 235)
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

slope_norm <- raster( "D:/Masterarbeit/Data/rescaled/slope.tif")
srtm_norm <- raster( "D:/Masterarbeit/Data/rescaled/srtm.tif")
flowdir_norm <- raster( "D:/Masterarbeit/Data/flowdir/flowdir.tif")
wokam_bin <- raster( "D:/Masterarbeit/Data/wokam/wokam_bin.tif")

SplitRas(srtm_norm,path = "D:/Masterarbeit/Data/rescaled/tiles_srtm/")
SplitRas(slope_norm,path = "D:/Masterarbeit/Data/rescaled/tiles_slope/")
SplitRas(flowdir_norm,path = "D:/Masterarbeit/Data/rescaled/tiles_flowdir/")
SplitRas(wokam_bin,path = "D:/Masterarbeit/Data/rescaled/tiles_wokam/")

# EXPORT 3-CHANNEL TIF -----------------------------------------------------
# Export all of Europe, except the sea:

# srtm_path <- "D:/Masterarbeit/Data/normalized/tiles_srtm/"
# srtm_files <- list.files(path = srtm_path, pattern = "*.tif$")
# 
# slope_path <- "D:/Masterarbeit/Data/normalized/tiles_slope/"
# slope_files <- list.files(path = slope_path, pattern = "*.tif$")
# 
# rough_path <- "D:/Masterarbeit/Data/normalized/tiles_flowdir/"
# rough_files <- list.files(path = rough_path, pattern = "*.tif$")
# 
# for (i in 1:length(srtm_files)) {
#   print(paste0(i, ":", "processing tile:", srtm_files[i]))
#   ras <- raster(paste0(srtm_path, srtm_files[i]))
#   
#   
#   if (!all(is.na(getValues(ras)))) {
#     slope <- raster(paste0(slope_path, slope_files[i]))
#     rough <- raster(paste0(rough_path, rough_files[i]))
#     
#     rgb <- stack(ras, slope, rough)
#     writeRaster(
#       rgb,
#       filename = paste0("D:/Masterarbeit/Data/normalized/RGB_tif/", srtm_files[i]),
#       format = "GTiff",
#       datatype = "FLT4S",
#       overwrite = TRUE)
#   }
# }

# ONLY BORDERING AREAS -----------------------------------------------------

srtm_path <- "D:/Masterarbeit/Data/normalized/tiles_srtm/"
srtm_files <- list.files(path = srtm_path, pattern = "*.tif$")

slope_path <- "D:/Masterarbeit/Data/normalized/tiles_slope/"
slope_files <- list.files(path = slope_path, pattern = "*.tif$")

flowdir_path <- "D:/Masterarbeit/Data/normalized/tiles_flowdir/"
flowdir_files <- list.files(path = flowdir_path, pattern = "*.tif$")

mask_path <- "D:/Masterarbeit/Data/normalized/tiles_wokam/"
mask_files <- list.files(path = mask_path, pattern = "*.tif$")


for (i in 1:length(mask_files)) {
  print(paste0(i, ":", "processing tile:", mask_files[i]))
  
  ras <- raster(paste0(srtm_path, mask_files[i]))
  slope <-  raster(paste0(slope_path, mask_files[i]))
  flow <-  raster(paste0(flowdir_path, mask_files[i]))
  
  mask <- raster(paste0(mask_path, mask_files[i]))
  
  
  if ( max(getValues(mask)) == 1 & min(getValues(mask)) == 0 & !all(is.na(getValues(ras)))) {
    
    rgb <- stack(ras, slope, flow)
    
    writeRaster(
      rgb,
      filename = paste0("D:/Masterarbeit/Data/Randbereiche/SRTM/", mask_files[i]),
      format = "GTiff",
      datatype = "FLT4S",
      overwrite = TRUE)
    
    writeRaster(
      mask,
      filename = paste0("D:/Masterarbeit/Data/Randbereiche/WOKAM/", mask_files[i]),
      format = "GTiff",
      datatype = "FLT4S",
      overwrite = TRUE)
  }
}

# ONLY BORDERING AREAS OF RESCALED DATA -----------------------------------------------------

srtm_path <- "D:/Masterarbeit/Data/rescaled/tiles_srtm/"
srtm_files <- list.files(path = srtm_path, pattern = "*.tif$")

slope_path <- "D:/Masterarbeit/Data/rescaled/tiles_slope/"
slope_files <- list.files(path = slope_path, pattern = "*.tif$")

flowdir_path <- "D:/Masterarbeit/Data/rescaled/tiles_flowdir/"
flowdir_files <- list.files(path = flowdir_path, pattern = "*.tif$")

mask_path <- "D:/Masterarbeit/Data/rescaled/tiles_wokam/"
mask_files <- list.files(path = mask_path, pattern = "*.tif$")


for (i in 1:length(mask_files)) {
  #i <- 10
  print(paste0(i, ":", "processing tile:", mask_files[i]))
  
  ras <- raster(paste0(srtm_path, mask_files[i]))
  slope <-  raster(paste0(slope_path, mask_files[i]))
  #flow <-  raster(paste0(flowdir_path, mask_files[i]))
  
  mask <- raster(paste0(mask_path, mask_files[i]))
  
  x <- getValues(mask)
  y <- getValues(ras)
  
  if (max(x, na.rm = T) == 1 & min(x, na.rm = T) == 0 & all(!is.na(y))) {
    
    rgb <- stack(ras, slope)#, flow)
    
    writeRaster(
      rgb,
      filename = paste0("D:/Masterarbeit/Data/rescaled/SRTM/", mask_files[i]),
      format = "GTiff",
      datatype = "FLT4S",
      overwrite = TRUE)
    
    writeRaster(
      mask,
      filename = paste0("D:/Masterarbeit/Data/rescaled/WOKAM/", mask_files[i]),
      format = "GTiff",
      datatype = "FLT4S",
      overwrite = TRUE)
  }
}

srtm_path <- "D:/Masterarbeit/Data/rescaled/subfolder_srtm/SRTM/"
srtm_files <- list.files(path = srtm_path, pattern = "*.tif$")

## 80% of the sample size
smp_size <- floor(0.80 * length(srtm_files))

## set the seed to make your partition reproducible
set.seed(123)
train_ind <- sample(seq_len(length(srtm_files)), size = smp_size)

train <- srtm_files[train_ind]
test <- srtm_files[-train_ind]

for (filenamee in test) {
  #i <- 10
  #print(paste0(i, ":", "processing tile:", mask_files[i]))
  
  rgb <- stack(paste0("D:/Masterarbeit/Data/rescaled/subfolder_srtm/SRTM/", filenamee))
  mask <- raster(paste0("D:/Masterarbeit/Data/rescaled/subfolder_wokam/WOKAM/", filenamee))
  flowdir <- raster(paste0("D:/Masterarbeit/Data/rescaled/tiles_flowdir/", filenamee))
  
  three_band <- stack(rgb,flowdir)
    
  writeRaster(
      three_band,
      filename = paste0("D:/Masterarbeit/Data/rescaled/test/SRTM/subfolder_srtm/", filenamee),
      format = "GTiff",
      datatype = "FLT4S",
      overwrite = TRUE)
    
    writeRaster(
      mask,
      filename = paste0("D:/Masterarbeit/Data/rescaled/test/WOKAM/subfolder_wokam/", filenamee),
      format = "GTiff",
      datatype = "FLT4S",
      overwrite = TRUE)
}

for (filenamee in test) {

  unlink(paste0("D:/Masterarbeit/Data/rescaled/train/SRTM/subfolder_srtm/", filenamee))
  unlink(paste0("D:/Masterarbeit/Data/rescaled/train/WOKAM/subfolder_wokam/", filenamee))
  
}

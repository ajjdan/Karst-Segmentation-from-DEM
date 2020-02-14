
# PREPROCESSING -----------------------------------------------------------
# Two large raster datasets "srtm.tif", a digital elevation model, and 
# "wokam.tif", binary data to indicate karst areas, are preprocessed to 
# be fed to a convolutional neural network for image segmentation.
#
# 1- derive slope, aspect, TPI, TRI, roughness and Flow direction 
# 2- performe a multiple Regression to find most influential predictors
# 3- split large raster data into smaller areas
# 4- combine RGB images and save as compatible format

# LIBRARIES AND PATHS -----------------------------------------------------

library("scales")
library("raster")
library(rgdal)

# Set temporary directory on D:/ 
rasterOptions(tmpdir = "D:/rtmp/")
write("R_USER = D:/rtmp/", file = file.path(Sys.getenv('R_USER'), '.Renviron'))

#Path to raster files
raster_path <- "D:/Masterarbeit/Data/srtm/"
mask_path <- "D:/Masterarbeit/Data/wokam/"

#Filenames
raster_files <- list.files(path = raster_path, pattern = "*.tif$")
mask_files <- list.files(path = mask_path, pattern = "*.tif$")

#Read data using raster package
img_raster <- raster(paste0(raster_path, raster_files))
img_mask <- raster(paste0(mask_path, mask_files))

#Derive terrain indices from digital elevation model
slope <- terrain(img_raster, opt = " slope")
aspect <- terrain(img_raster, opt = "aspect")
TPI <- terrain(img_raster, opt = "TPI")
TRI <- terrain(img_raster, opt = "TRI")
roughness <- terrain(img_raster, opt = "roughness")
flowdir <- terrain(img_raster, opt = "flowdir")


#A sample of the data is used because of the size
#Regular (not a random) sample to minimize redundancy in your data.

stack <- stack(img_mask, img_raster)
stack <- data.frame(sampleRandom(stack, 10000))

terrain_stack <- stack(img_mask, img_raster, slope, aspect, TPI, TRI, roughness, flowdir)
terrain_stack <- data.frame(sampleRandom(terrain_stack, 10000))

fm <- glm(wokam_bin ~ srtm, data = stack, family = "binomial")

fm_multi <- glm(wokam_bin ~ (srtm + slope + aspect + tpi + tri + roughness + flowdir),
    family = "binomial",
    data = terrain_stack)

#Untersuchen auf einen Interaktionsefekt
#Mit einem Sternchen ans Stelle des Plus werden beide Prädiktoren (wie bei 2.) und ihre Interaktion ins
#Modell aufgenommen.
fm_multi_interact <- glm(wokam_bin ~ (srtm * slope * aspect * tpi * tri * roughness * flowdir),
                         family = "binomial",
                         data = terrain_stack)
summary(fm_multi)

# Cluster Analysis to check corellations between predictors
library(Hmisc)

vc <- varclus(as.matrix(terrain_stack))
plot(vc)
abline(h=0.5)

#Export selected predictors

writeRaster(
  slope,
  "D:/Masterarbeit/Data/slope/slope.tif",
  overwrite = T,
  format = "GTiff"
)

writeRaster(
  flowdir,
  "D:/Masterarbeit/Data/flowdir/flowdir.tif",
  overwrite = T,
  format = "GTiff"
)

library("spatialEco")

srtm_rescaled <- raster.transformation(img_raster, trans = "norm", smin=0, smax = 4080)
srtm_slope <- raster.transformation(slope, smin=0, smax = 1.47926)
srtm_flowdir <- raster.transformation(flowdir, smin=0, smax = 128)

stack_normalized <- stack(img_mask,srtm_rescaled, srtm_flowdir, srtm_slope)
terrain_stack_norm <- data.frame(sampleRandom(stack_normalized, 10000))

fm_multi_norm <- glm(wokam_bin ~ (srtm + slope + flowdir),
                family = "binomial",
                data = terrain_stack_norm)
summary(fm_multi_norm)


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
  h        <- ceiling(ncol(raster) / 480)
  v        <- ceiling(nrow(raster) / 301)
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

slope_norm <- raster( "D:/Masterarbeit/Data/normalized/slope/slope.tif")
srtm_norm <- raster( "D:/Masterarbeit/Data/normalized/srtm/srtm.tif")
flowdir_norm <- raster( "D:/Masterarbeit/Data/normalized/flowdir/flowdir.tif")


SplitRas(srtm_norm,path = "D:/Masterarbeit/Data/normalized/tiles_srtm/")
SplitRas(slope_norm,path = "D:/Masterarbeit/Data/normalized/tiles_slope/")
SplitRas(flowdir_norm,path = "D:/Masterarbeit/Data/normalized/tiles_flowdir/")

# EXPORT 3-CHANNEL TIF -----------------------------------------------------
# If we want all of Europe, except the sea:
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

flowdir_path <- "D:/Masterarbeit/Data/normalized/tiles_flowdir"
flowdir_files <- list.files(path = flowdir_path, pattern = "*.tif$")

mask_path <- "D:/Masterarbeit/Data/tiles_wokam/"
mask_files <- list.files(path = mask_path, pattern = "*.tif$")

for (i in 1:length(srtm_files)) {
  print(paste0(i, ":", "processing tile:", srtm_files[i]))
  
  ras <- raster(paste0(srtm_path, srtm_files[i]))
  slope <-  raster(paste0(slope_path, slope_files[i]))
  flow <-  raster(paste0(flowdir_path, flowdir_files[i]))
  
  mask <- raster(paste0(mask_path, mask_files[i]))
  
  
  if ( max(getValues(mask)) == 1 & min(getValues(mask)) == 0 & !all(is.na(getValues(ras)))) {
    
    rgb <- stack(ras, slope, flow)
    
    writeRaster(
      rgb,
      filename = paste0("D:/Masterarbeit/Data/Randbereiche/SRTM/", srtm_files[i]),
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

# Two large raster datasets "srtm.tif", a digital elevation model, and 
# "wokam.tif", binary data to indicate karst areas, are preprocessed to 
# be fed to a convolutional neural network for image segmentation.
#
# 1- derive slope, aspect, TPI, TRI, roughness and Flow direction 
# 2- performe a multiple Regression to find most influential predictors

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
# Four large normalized raster datasets "srtm.tif" a digital elevation model, slope data "slope.tif", and flow direction "flowdir.tif", and 
# "wokam.tif", binary data to indicate karst areas, are clipped to the extent of the Balkans and preprocessed into tiles to 
# be fed to a convolutional neural network for image segmentation.
#
# 1- clip ot balkan extent
# 2- split into tiles

# LIBRARIES AND PATHS -----------------------------------------------------
# 
library("scales")
library("raster")
library(rgdal)
library("quantregForest")
# 
# # Set temporary directory on D:/ 
 rasterOptions(tmpdir = "D:/rtmp/")
write("R_USER = D:/rtmp/", file = file.path(Sys.getenv('R_USER'), '.Renviron'))
# 
 slope_norm <- raster( "D:/Masterarbeit/Data/normalized/slope/slope.tif")
 srtm_norm <- raster( "D:/Masterarbeit/Data/normalized/srtm/srtm.tif")
 flowdir_norm <- raster( "D:/Masterarbeit/Data/normalized/flowdir/flowdir.tif")
 mask <- raster("D:/Masterarbeit/Data/wokam/wokam_bin.tif")
# 
# 
# #crop_extent <- readOGR("D:/Masterarbeit/Data/Balkans/Balkans_extent_poly.shp")
# 
# # crop the DEM rasters using the vector extent
# #slope_norm_crop <- crop(slope_norm, crop_extent)
# #srtm_norm_crop <- crop(srtm_norm, crop_extent)
# #flowdir_norm_crop <- crop(flowdir_norm, crop_extent)
# #wokam_crop <- crop(mask, crop_extent)
# 
 terrain_stack <- stack( srtm_norm ,slope_norm, flowdir_norm, mask)
# 
# rm(list = setdiff(ls(), "terrain_stack"))
# 
# terrain_stack <- na.omit(terrain_stack)
# 
terrain_stack <- as.data.frame(na.omit(sampleRegular(terrain_stack,20000 )))
#terrain_stack <- sampleRandom(terrain_stack, 20000, asRaster=TRUE)

# QUANTILE REGRESSION FOREST -----------------------------------------------------

################################################
## Load air-quality data (and preprocessing) ##
################################################

## number of remining samples
#n <- nrow(terrain_stack)

## divide into training and test data
#indextrain <- sample(1:n,round(0.6*n),replace=FALSE)
#Xtrain <- terrain_stack[ indextrain,1:3]
#Xtest <- terrain_stack[-indextrain,1:3]
#Ytrain <- terrain_stack[ indextrain,4]
#Ytest <- terrain_stack[-indextrain,4]

################################################
## With Modelmap ##
################################################

names(terrain_stack) <-c("srtm.tif", "slope.tif", "flowdir.tif", "wokam_bin.tif")
write.table(terrain_stack,file = paste0(folder, "/", "VModelMapData.csv"), quote = FALSE, sep = ",", row.names = FALSE)

library("ModelMap")
library("raster")

writeRaster(na.omit(sampleRegular(slope_norm,20000, asRaster = TRUE)),"D:/Masterarbeit/Data/forest/slope.tif", overwrite = TRUE)
writeRaster(na.omit(sampleRegular(srtm_norm,20000, asRaster = TRUE)),"D:/Masterarbeit/Data/forest/srtm.tif", overwrite = TRUE)
writeRaster(na.omit(sampleRegular(flowdir_norm,20000, asRaster = TRUE)),"D:/Masterarbeit/Data/forest/flowdir.tif", overwrite = TRUE)
writeRaster(na.omit(sampleRegular(mask,20000, asRaster = TRUE)),"D:/Masterarbeit/Data/forest/wokam_bin.tif", overwrite = TRUE)

imageList <- c("D:/Masterarbeit/Data/forest/srtm.tif",
               "D:/Masterarbeit/Data/forest/slope.tif",
               "D:/Masterarbeit/Data/forest/flowdir.tif",
               "D:/Masterarbeit/Data/forest/wokam_bin.tif")
predList <- c("srtm.tif", "slope.tif", "flowdir.tif")


#Define the output folder

folder <-  "D:/Masterarbeit/Data/forest"

qdatafn <-  "VModelMapData.csv"
qdata.trainfn <- "VModelMapData_TRAIN.csv"
qdata.testfn <-  "VModelMapData_TEST.csv"
rastLUTfn <- "VModelMapData_LUT.csv"

predLUT <-build.rastLUT(imageList=imageList,predList=predList,qdata.trainfn=qdatafn,folder=folder)

get.test( proportion.test=0.2,
          qdatafn=qdatafn,
          folder=folder,
          qdata.trainfn=qdata.trainfn,
          qdata.testfn=qdata.testfn)

MODELfn.a <- "VModelMapEx1a"

predFactor <- FALSE
response.type <- "binary"
#Define the response variable, and whether it is continuous, binary or categorical.
response.name.a <- "wokam_bin.tif"

unique.rowname <- "ID"

#Define raster look up table.
 rastLUTfn <- paste0(folder,"/","VModelMapData_rastLUT.csv")
 rastLUTfn <- read.table( rastLUTfn,
                           header=FALSE,
                          sep=",",
                       stringsAsFactors=FALSE)
 rastLUTfn[,1] <- paste(folder,rastLUTfn[,1],sep="/")

preds <-  paste0(folder,"/",predList)
model.explore( qdata.trainfn=qdata.trainfn,
                folder=folder,
                predList=predList,
                predFactor=predFactor,
                OUTPUTfn=MODELfn.a,
                response.name=response.name.a ,
                response.type="binary",
                unique.rowname=unique.rowname,
                device.type=c("png"),
                #cex=1.2,
                # Raster arguments
                rastLUTfn=rastLUTfn,
                na.value=-9999,
                # colors for continuous predictors
                col.ramp=heat.colors(101),
                #colors for categorical predictors
                col.cat=c("wheat1","springgreen2","darkolivegreen4",
                          "darkolivegreen2","yellow","thistle2",
                          "brown2","brown4")
 )
 
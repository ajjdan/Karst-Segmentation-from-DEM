
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

preprocess_raster <- function(srtm_file = "D:/Masterarbeit/Data/srtm/srtm.tif",
           stretch_transform = FALSE,
           rescaled_out_path = "D:/Masterarbeit/Data/rescaled/",
           rgb_out_path = "D:/Masterarbeit/Data/srtm/srtm.tif",
           mask_file = "D:/Masterarbeit/Data/wokam/wokam_bin.tif",
           slope_file = "D:/Masterarbeit/Data/slope/slope.tif",
           flowdir_file = "D:/Masterarbeit/Data/flowdir/flowdir.tif",
           tile_size = c(128, 128),
           tile_path = "D:/Masterarbeit/Data/raw_terrain_data/",
           tiles = TRUE,
           only_bordering_areas = TRUE) {
  
    srtm <- raster(srtm_file)
    slope <- raster(slope_file)
    flowdir <- raster(flowdir_file)
    mask <- raster(mask_file)
    
    
    if (stretch_transform == TRUE) {
      srtm <-
        raster.transformation(srtm, trans = "stretch")#, smin=0, smax = 4080)
      writeRaster(
        srtm ,
        paste0(rescaled_out_path, "srtm.tif"),
        overwrite = T,
        format = "GTiff"
      )
      
      slope <-
        raster.transformation(slope,
                              trans = "stretch",
                              smin = 0,
                              smax = 1.47926)
      writeRaster(
        slope ,
        paste0(rescaled_out_path, "slope.tif"),
        overwrite = T,
        format = "GTiff"
      )
      
      
      flowdir <-
        raster.transformation(flowdir, trans = "stretch")#, smin=0, smax = 128)
      writeRaster(
        flowdir ,
        paste0(rescaled_out_path, "flowdir.tif"),
        overwrite = T,
        format = "GTiff"
      )
    }
    
# Define where the raster must be split -----------------------------------------------------
    
    if (tiles == TRUE) {
      splits_h = ceiling(ncol(srtm) / tile_size[1])
      splits_v = ceiling(nrow(srtm) / tile_size[2])
      
# Function to create tiles -----------------------------------------------------
      
      h        <- ceiling(ncol(slope) / splits_h)
      v        <- ceiling(nrow(slope) / splits_v)
      agg      <- aggregate(slope, fact = c(h, v))
      agg[]    <- 1:ncell(agg)
      agg_poly <- rasterToPolygons(agg)
      names(agg_poly) <- "polis"
      
      for (i in 1:ncell(agg)) {
        e1          <- extent(agg_poly[agg_poly$polis == i,])
        crop <- crop(slope, e1)
        print(paste0("processing tile:", i))
        writeRaster(
          crop,
          filename = paste0(paste0(tile_path, "tiles_slope/"), "tile", i),
          format = "GTiff",
          datatype = "FLT4S",
          overwrite = TRUE
        )
        
      }
      
      h        <- ceiling(ncol(srtm) / splits_h)
      v        <- ceiling(nrow(srtm) / splits_v)
      agg      <- aggregate(srtm, fact = c(h, v))
      agg[]    <- 1:ncell(agg)
      agg_poly <- rasterToPolygons(agg)
      names(agg_poly) <- "polis"
      
      for (i in 1:ncell(agg)) {
        e1          <- extent(agg_poly[agg_poly$polis == i,])
        crop <- crop(srtm, e1)
        print(paste0("processing tile:", i))
        writeRaster(
          crop,
          filename = paste0(paste0(tile_path, "tiles_srtm/"), "tile", i),
          format = "GTiff",
          datatype = "FLT4S",
          overwrite = TRUE
        )
        
      }
      
      h        <- ceiling(ncol(flowdir) / splits_h)
      v        <- ceiling(nrow(flowdir) / splits_v)
      agg      <- aggregate(flowdir, fact = c(h, v))
      agg[]    <- 1:ncell(agg)
      agg_poly <- rasterToPolygons(agg)
      names(agg_poly) <- "polis"
      
      for (i in 1:ncell(agg)) {
        e1          <- extent(agg_poly[agg_poly$polis == i,])
        crop <- crop(flowdir, e1)
        print(paste0("processing tile:", i))
        writeRaster(
          crop,
          filename = paste0(paste0(tile_path, "tiles_flowdir/"), "tile", i),
          format = "GTiff",
          datatype = "FLT4S",
          overwrite = TRUE
        )
        
      }
      
      h        <- ceiling(ncol(mask) / splits_h)
      v        <- ceiling(nrow(mask) / splits_v)
      agg      <- aggregate(mask, fact = c(h, v))
      agg[]    <- 1:ncell(agg)
      agg_poly <- rasterToPolygons(agg)
      names(agg_poly) <- "polis"
      
      for (i in 1:ncell(agg)) {
        e1          <- extent(agg_poly[agg_poly$polis == i,])
        crop <- crop(mask, e1)
        print(paste0("processing tile:", i))
        writeRaster(
          crop,
          filename = paste0(paste0(tile_path, "tiles_wokam/"), "tile", i),
          format = "GTiff",
          datatype = "FLT4S",
          overwrite = TRUE
        )
        
      }
      
    }

    
    # Creating a RBG image  -----------------------------------------------------
    
    srtm_path <-  paste0(tile_path, "tiles_srtm/")
    srtm_files <- list.files(path = srtm_path, pattern = "*.tif$")
    
    slope_path <-  paste0(tile_path, "tiles_slope/")
    slope_files <- list.files(path = slope_path, pattern = "*.tif$")
    
    flowdir_path <- paste0(tile_path, "tiles_flowdir/")
    flowdir_files <-
      list.files(path = flowdir_path, pattern = "*.tif$")
    
    mask_path <- paste0(tile_path, "tiles_wokam/")
    mask_files <- list.files(path = mask_path, pattern = "*.tif$")
    
    
    if (only_bordering_areas == TRUE) {
      print("ONLY BORDERING TILES AS RGB")
      for (i in 1:length(mask_files)) {
        print(paste0(i, ":", "processing tile:", mask_files[i]))
        
        ras <- raster(paste0(srtm_path, mask_files[i]))
        slope <-  raster(paste0(slope_path, mask_files[i]))
        flow <-  raster(paste0(flowdir_path, mask_files[i]))
        
        mask <- raster(paste0(mask_path, mask_files[i]))
        
        
        if (max(getValues(mask)) == 1 &
            min(getValues(mask)) == 0 & !all(is.na(getValues(ras)))) {
          rgb <- stack(ras, slope, flow)
          
          writeRaster(
            rgb,
            filename = paste0(rgb_out_path, "SRTM/", mask_files[i]),
            format = "GTiff",
            datatype = "FLT4S",
            overwrite = TRUE
          )
          
          writeRaster(
            mask,
            filename = paste0(rgb_out_path, "WOKAM/", mask_files[i]),
            format = "GTiff",
            datatype = "FLT4S",
            overwrite = TRUE
          )
        }
      }
    }
    
    if (only_bordering_areas != TRUE) {
      print("WHOLE RASTER AS RGB")
      for (i in 1:length(mask_files)) {
        print(paste0(i, ":", "processing tile:", mask_files[i]))
        
        ras <- raster(paste0(srtm_path, mask_files[i]))
        slope <-  raster(paste0(slope_path, mask_files[i]))
        flow <-  raster(paste0(flowdir_path, mask_files[i]))
        
        mask <- raster(paste0(mask_path, mask_files[i]))
        
        
        if (!all(is.na(getValues(ras)))) {
          rgb <- stack(ras, slope, flow)
          
          writeRaster(
            rgb,
            filename = paste0(rgb_out_path, "SRTM/", mask_files[i]),
            format = "GTiff",
            datatype = "FLT4S",
            overwrite = TRUE
          )
          
          writeRaster(
            mask,
            filename = paste0(rgb_out_path, "WOKAM/", mask_files[i]),
            format = "GTiff",
            datatype = "FLT4S",
            overwrite = TRUE
          )
        }
      }
    }
    
    
    
    if (train_test_split == TRUE) {
      
      srtm_path <- paste0(rgb_out_path, "SRTM/")
      srtm_files <- list.files(path = srtm_path, pattern = "*.tif$")
      
      ## 80% of the sample size
      smp_size <- floor(0.80 * length(srtm_files))
      
      ## set the seed to make your partition reproducible
      set.seed(123)
      train_ind <-
        sample(seq_len(length(srtm_files)), size = smp_size)
      
      train <- srtm_files[train_ind]
      test <- srtm_files[-train_ind]
      
      for (filenamee in test) {
        rgb <- stack(paste0(rgb_out_path, "SRTM/", filenamee))
        mask <- raster(paste0(rgb_out_path, "WOKAM/", filenamee))
        
        writeRaster(
          three_band,
          filename = paste0(rgb_out_path, "test/tf_data/SRTM/", filenamee),
          format = "GTiff",
          datatype = "FLT4S",
          overwrite = TRUE
        )
        
        writeRaster(
          mask,
          filename = paste0(rgb_out_path, "test/tf_data/WOKAM/", filenamee),
          format = "GTiff",
          datatype = "FLT4S",
          overwrite = TRUE
        )
      }
      
      for (filenamee in train) {
        rgb <- stack(paste0(rgb_out_path, "SRTM/", filenamee))
        mask <- raster(paste0(rgb_out_path, "wokam/", filenamee))
        
        writeRaster(
          three_band,
          filename = paste0(rgb_out_path, "train/tf_data/SRTM/", filenamee),
          format = "GTiff",
          datatype = "FLT4S",
          overwrite = TRUE
        )
        
        writeRaster(
          mask,
          filename = paste0(rgb_out_path, "train/tf_data/WOKAM/", filenamee),
          format = "GTiff",
          datatype = "FLT4S",
          overwrite = TRUE
        )
      }
      
    }
}


preprocess_raster()


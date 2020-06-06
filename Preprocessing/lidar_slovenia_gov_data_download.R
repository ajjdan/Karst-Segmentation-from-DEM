library("st")
library("sf")
library("raster")
library("lidR")
library(rgdal)

#Sample link
#http://gis.arso.gov.si/lidar/gkot/laz/b_34/D48GK/GK_499_120.laz
#http://gis.arso.gov.si/lidar/gkot/laz/b_24/D48GK/GK_585_180.laz

# Set temporary directory on D:/ 
rasterOptions(tmpdir = "D:/rtmp/")
write("R_USER = D:/rtmp/", file = file.path(Sys.getenv('R_USER'), '.Renviron'))

# fishnet <- st_read("D:/Masterarbeit/Data/high_res/slovenia_1m/shp/LIDAR_FISHNET_D48GK.shp")
# fishnet <- fishnet[fishnet$BLOK %in%  c("b_23" , "b_22", "b_22" ,"b_26" , "b_24","b_14" ,"b_21") ,]
# 
wokam_bin <- raster("D:/Masterarbeit/Data/wokam/wokam_bin_slovenia.tif")
wokam_bin <- projectRaster(wokam_bin, crs = '+proj=tmerc +lat_0=0 +lon_0=15 +k=0.9999 +x_0=500000 +y_0=-5000000 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs ')
# 
# plot(wokam_bin)
# plot(fishnet, add = TRUE)
# 
# fishnet_extracted <- extract(wokam_bin, fishnet, fun=mean, df=TRUE) 
# 
# fishnet$ID <- 1:nrow(fishnet)
# 
# fishnet_wokam <- merge.data.frame(fishnet,fishnet_extracted, by = "ID")
# 
# fishnet_wokam <- fishnet[fishnet_wokam$wokam_bin_slovenia > 0 & fishnet_wokam$wokam_bin_slovenia < 1 & !is.na(fishnet_wokam$wokam_bin_slovenia),]
# 
# 
# filenames <- paste0("http://gis.arso.gov.si/lidar/gkot/laz/",fishnet_wokam$BLOK,"/D96TM/TM_",fishnet_wokam$NAME, ".laz")
#http://gis.arso.gov.si/lidar/gkot/b_25/D96TM/TM_558_164.zlas
# 
# files <- paste0("TM_",fishnet_wokam$NAME, ".laz")


#filenames <- paste0("http://gis.arso.gov.si/lidar/gkot/laz/",fishnet_wokam$BLOK,"/D96TM/TM_",fishnet_wokam$NAME, ".laz")
#files <- paste0("TM_",fishnet_wokam$NAME, ".laz")

# for (i in 1:length(filenames)){
#  tryCatch({
#    
# download.file(filenames[i], paste0("D:/Masterarbeit/Data/high_res/slovenia_1m/laz/" ,files[i]), mode = "wb")
# }, error=function(e){cat("ERROR :","THIS TILE IS MISSING", "\n")})
# }
# 


    lidar_path <-  paste0("D:/Masterarbeit/Data/high_res/slovenia_1m/laz/")
    lidar_files <- list.files(path = lidar_path, pattern = "*.laz$")
    
    tif_path <-  paste0("D:/Masterarbeit/Data/high_res/slovenia_1m/tiff/")
    tif_files <- gsub(".laz", ".tif", lidar_files)
    
    reclass_df <- c(-1, 0.494, 0,
                    0.495, 1.1, 1)
    reclass_m <- matrix(reclass_df,
                        ncol = 3,
                        byrow = TRUE)
    
for (i in 1:length(lidar_files)) {
  
    print(paste0(i, ":", "processing tile:", lidar_files[i]))    
    
    
    Lasfile <- readLAS(paste0(lidar_path ,lidar_files[i]))
     
    epsg(Lasfile) <- 3794

    dtm <-  grid_terrain(Lasfile, algorithm = tin())
    #plot_dtm3d(dtm)
#crs='+proj=tmerc +lat_0=0 +lon_0=15 +k=0.9999 +x_0=500000 +y_0=-5000000 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs ')
    
    ext <- extent(Lasfile)
    mask_file <- crop(wokam_bin, ext)
    mask_file<-resample(mask_file, dtm, method="ngb")
    mask_file<- reclassify(mask_file,reclass_m)
    
    writeRaster(mask_file, paste0(tif_path,"/mask/",tif_files[i]),
                format = "GTiff",
                datatype = "FLT4S",
                overwrite = TRUE)
    writeRaster(dtm, 
                paste0(tif_path,"/lidar/",tif_files[i]),
                format = "GTiff",
                datatype = "FLT4S",
                overwrite = TRUE)
}
    
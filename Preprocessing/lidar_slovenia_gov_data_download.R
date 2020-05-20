library("st")

fishnet <- st_read("D:/Masterarbeit/Data/high_res/slovenia_1m/LIDAR_FISHNET_D48GK.shp")

filenames <- paste0("http://gis.arso.gov.si/lidar/dmr1/",fishnet$BLOK,"/D48GK/GK1_",fishnet$NAME, ".asc")
files <- paste0("GK1_",fishnet$NAME, ".asc")

for (i in 1:length(filenames) ){
  download.file(filenames[i], paste0("D:/Masterarbeit/Data/high_res/slovenia_1m/" ,files[i]))}


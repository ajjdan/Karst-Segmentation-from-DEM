################################################
##  Load air-quality data (and preprocessing) ##
################################################

library(quantregForest)
library(raster)
library(scales)
library(rasterVis)

## Set location of R-script as working directory
path.act <- dirname(sys.frame(1)$ofile)
setwd(path.act)


lidar_path <- paste0("C:/Users/nadja/Documents/Masterarbeit/DATA/high_res/lidar/")
lidar_files <- list.files(path = lidar_path, pattern = "*.tif$")
lidar_files <- lidar_files[-which(lidar_files=="TM_402_45.tif")]

r <- data.frame()

for (filenamee in lidar_files) {
  raster <- raster(paste0(lidar_path, filenamee))
  slope <- terrain(raster,"slope")
  flowdir <- terrain(raster,"flowdir")
  
  raster <- sampleRegular(raster,1000)
  slope <- sampleRegular(slope,1000)
  flowdir <- sampleRegular(flowdir,1000)
  
  ras_df <- cbind(as.data.frame(raster), as.data.frame(slope),  as.data.frame(flowdir))
  names(ras_df) <- c("lidar", "slope", "flowdir")
  
  r <- rbind(r, ras_df)
}


wokam_path <- paste0("C:/Users/nadja/Documents/Masterarbeit/DATA/high_res/wokam/")
wokam_files <- list.files(path = wokam_path, pattern = "*.tif$")
wokam_files <- wokam_files[-which(wokam_files=="TM_402_45.tif")]

w <- data.frame()

for (filenamee in wokam_files) {
  raster <- sampleRegular(raster(paste0(wokam_path, filenamee)), 1000)
  ras_df <- as.data.frame(raster)
  names(ras_df) <- "wokam"
  w <- rbind(w, ras_df)
}

terrain_sample_df <- cbind(w,r)

## remove observations with mising values

terrain_sample_df$lidar <- rescale(terrain_sample_df$lidar, to = c(0.2,1), from = c(min(terrain_sample_df$lidar, na.rm = TRUE), max(terrain_sample_df$lidar, na.rm = TRUE)))
terrain_sample_df$slope <- rescale(terrain_sample_df$slope, to = c(0.2,1), from = c(min(terrain_sample_df$slope, na.rm = TRUE), max(terrain_sample_df$slope, na.rm = TRUE)))
terrain_sample_df$flowdir <- rescale(terrain_sample_df$flowdir, to = c(0.2,1), from = c(min(terrain_sample_df$flowdir, na.rm = TRUE), max(terrain_sample_df$flowdir, na.rm = TRUE)))

which_na <- which(is.na(terrain_sample_df))

terrain_stack_df <- na.omit(terrain_sample_df)

terrain_stack_df$wokam <- as.factor(terrain_stack_df$wokam)
## number of remining samples
n <- nrow(terrain_stack_df)


## divide into training and test data
indextrain <- sample(1:n,round(0.6*n),replace=FALSE)
Xtrain     <- terrain_stack_df[ indextrain,2:4]
Xtest      <- terrain_stack_df[-indextrain,2:4]
Ytrain     <- terrain_stack_df[ indextrain,1]
Ytest      <- terrain_stack_df[-indextrain,1]


################################################
##     compute Quantile Regression Forests    ##
################################################

#qrf <- quantregForest(x=Xtrain, y=Ytrain)
qrf <- quantregForest(x=Xtrain, y=Ytrain, nodesize=30,ntree=500)

#####################################
## Test on one tile
#####################################

test_wokam_path <- paste0("C:/Users/nadja/Documents/Masterarbeit/DATA/high_res/wokam/")
test_wokam_files <- list.files(path = wokam_path, pattern = "*.tif$")[-which(!(wokam_files=="TM_402_45.tif"))]


test_lidar_path <- paste0("C:/Users/nadja/Documents/Masterarbeit/DATA/high_res/lidar/")
test_lidar_files <- list.files(path = lidar_path, pattern = "*.tif$")[-which(!(lidar_files=="TM_402_45.tif"))]

test_raster <- raster(paste0(test_lidar_path, test_lidar_files))
test_slope <- terrain(test_raster,"slope")
test_flowdir <- terrain(test_raster,"flowdir")

test_raster <- sampleRegular(test_raster, 10000)
test_slope <- sampleRegular(test_slope, 10000)
test_flowdir <- sampleRegular(test_flowdir, 10000)

test_wokam <- raster(paste0(wokam_path, test_wokam_files))
test_wokam <- sampleRegular(test_wokam, 10000)

test_ras_df <- cbind(as.data.frame(test_raster), as.data.frame(test_slope),  as.data.frame(test_flowdir), as.data.frame(test_wokam))
names(test_ras_df) <- c("lidar", "slope", "flowdir", "wokam")

test_ras_df$lidar <- rescale(test_ras_df$lidar, to = c(0.2,1), from = c(min(test_ras_df$lidar, na.rm = TRUE), max(test_ras_df$lidar, na.rm = TRUE)))
test_ras_df$slope <- rescale(test_ras_df$slope, to = c(0.2,1), from = c(min(test_ras_df$slope, na.rm = TRUE), max(test_ras_df$slope, na.rm = TRUE)))
test_ras_df$flowdir <- rescale(test_ras_df$flowdir, to = c(0.2,1), from = c(min(test_ras_df$flowdir, na.rm = TRUE), max(test_ras_df$flowdir, na.rm = TRUE)))

which_na <- which(is.na(test_ras_df))

test_elim_df <- na.omit(test_ras_df)

conditionalMean <- predict(qrf, test_elim_df[1:3], what=mean)
conditionalMean <- as.numeric(conditionalMean)-1

test_wokam <- raster(paste0(wokam_path, test_wokam_files))
test_raster <- raster(paste0(test_lidar_path, test_lidar_files))
test_slope <- terrain(test_raster,"slope")
test_flowdir <- terrain(test_raster,"flowdir")

r_val <- getValues(test_raster)
s_val <- getValues(test_slope)
f_val <- getValues(test_flowdir)

values(test_raster) <- rescale(r_val, to = c(0.2,1), from = c(min(r_val, na.rm = TRUE), max(r_val, na.rm = TRUE)))
values(test_slope) <- rescale(s_val, to = c(0.2,1), from = c(min(s_val, na.rm = TRUE), max(s_val, na.rm = TRUE)))
values(test_flowdir) <- rescale(f_val, to = c(0.2,1), from = c(min(f_val, na.rm = TRUE), max(f_val, na.rm = TRUE)))

row.has.na <- apply(test_ras_df, 1, function(x){any(is.na(x))})

test_ras_df$wokam_pred <- NA
test_elim_df$wokam_pred <- NA
test_ras_df$random <- NA

terrain_stack_sample <- stack( test_raster, test_slope, test_flowdir, test_wokam)
terrain_stack_sample <- sampleRegular(terrain_stack_sample, 10000, asRaster = TRUE)


#####################################
## Generate random numbers
#####################################

prob1train <- length(which(terrain_stack_df$wokam==1))/length(terrain_stack_df$wokam)
prob0train <- length(which(terrain_stack_df$wokam==0))/length(terrain_stack_df$wokam)

prob1 <- length(which(test_elim_df$wokam==1))/length(test_elim_df$wokam)
prob0 <- length(which(test_elim_df$wokam==0))/length(test_elim_df$wokam)

set.seed(234)
random_vals <- sample(c(1, 0), size =9700, replace = TRUE, prob = c(prob1,prob0))
 
#####################################
## Reverse to raster
##################################### 


test_elim_df$wokam_pred <- conditionalMean
test_elim_df$random <-random_vals

test_ras_df$wokam_pred[!(row.has.na)] <- round(test_elim_df$wokam_pred,0)
test_ras_df$random[!(row.has.na)] <- test_elim_df$random

test_ras_df$wokam_pred[row.has.na] <- 1
test_ras_df$random[row.has.na] <- 1
test_ras_df$wokam[row.has.na] <- 1

terrain_stack_sample$wokam_pred <- test_ras_df$wokam_pred
terrain_stack_sample$random<- test_ras_df$random
terrain_stack_sample$TM_404_46.2<- test_ras_df$wokam

#####################################
## Accuracy
#####################################

conditionalMeantrain <- predict(qrf,Xtrain, what=mean)
conditionalMeantrain <- round(as.numeric(conditionalMeantrain)-1,0)

train_acc <-(100/length(Ytrain))*length(which(conditionalMeantrain == as.numeric(Ytrain)-1))
test_acc <- (100/nrow(test_ras_df))*length(which(test_ras_df$wokam == round(test_ras_df$wokam_pred,0)))
random_acc <- (100/nrow(test_ras_df))*length(which(test_ras_df$random == round(test_ras_df$wokam_pred,0)))


#####################################
## Plot
#####################################

headers <- c("Rescaled elevation", "Rescaled slope", "Rescaled flow direction", "WOKAM", "QRF", "Random")


# dev.new(height=0.91*nrow(terrain_stack_sample[[1]])/50, width=1.09*ncol(terrain_stack_sample[[1]])/50)
# par(mfrow=c(2,3))
# 
# for (i in 1:6){
#   
#   plot(terrain_stack_sample[[i]],
#        legend=FALSE,
#        box = FALSE,
#        col = rev(grey(1:100/100)),
#        main = headers[i], 
#        cex.lab=1.7, cex.axis=1.7, cex.main=1.7, cex.sub=1.7)
#   
#   plot(terrain_stack_sample[[i]], legend.only=TRUE, col=rev(grey(1:100/100)),
#        legend.width=1, legend.shrink=1,
#        axis.args=list(#at=seq(terrain_stack_sample.range[1], r.range[2], 25),
#                       #labels=seq(r.range[1], r.range[2], 25), 
#                       cex.axis=0.6),
#        legend.args=list(text = "", side=4, font=2, line=2.5, cex=5, cex.pt = 5))
#   
# }
# 
# dev.new(height=0.91*nrow(terrain_stack_sample[[1]])/50, width=1.09*ncol(terrain_stack_sample[[1]])/50)

X11(15,10)  
levelplot(terrain_stack_sample,layout=c(3, 2),margin=FALSE,col.regions =rev(grey(1:100/100)), names.attr=headers, main = "Quantile regression forest Lidar testing data")#colorkey=list(space="bottom")


dev.copy(pdf,"C:/Users/nadja/Documents/Masterarbeit/DATA/randomslovenia.pdf", width = 9, height = 6)
dev.off()

length(which(terrain_stack_df$wokam_bin == round(terrain_stack_df$wokam_pred,0)))/nrow(terrain_stack_df)

length(which(terrain_stack_df$wokam_bin == round(terrain_stack_df$random,0)))/nrow(terrain_stack_df)






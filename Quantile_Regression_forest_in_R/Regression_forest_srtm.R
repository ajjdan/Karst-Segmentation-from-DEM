################################################
##  Load air-quality data (and preprocessing) ##
################################################

library(quantregForest)
library(raster)
library(scales)
library(rasterVis)

srtm <- raster("C:/Users/nadja/Documents/Masterarbeit/DATA/srtm/srtm.tif")

slope <-  raster("C:/Users/nadja/Documents/Masterarbeit/DATA/slope/slope.tif")

flowdir <-  raster("C:/Users/nadja/Documents/Masterarbeit/DATA/flowdir/flowdir.tif")

wokam <- raster("C:/Users/nadja/Documents/Masterarbeit/DATA/wokam/wokam_bin.tif")

terrain_stack <- stack(srtm,slope, flowdir,wokam)


## remove observations with mising values
terrain_stack_sample  <- sampleRegular(terrain_stack, 10000, asRaster = TRUE)

min_vals <-  cellStats(terrain_stack_sample, stat = min)
max_vals <-  cellStats(terrain_stack_sample, stat = max)

for (i in 1:3){
vals_srtm <- rescale(getValues(terrain_stack_sample[[i]]), to = c(0.2,1), from = c(min_vals[i], max_vals[i]))

terrain_stack_sample[[i]] <- vals_srtm
plot(terrain_stack_sample[[i]])
}


terrain_stack_df  <- as.data.frame(terrain_stack_sample)
which_na <- which(is.na(terrain_stack_df))

terrain_stack_df <- na.omit(terrain_stack_df)
terrain_stack_test <- na.omit(terrain_stack_sample)

terrain_stack_df$wokam_bin <- as.factor(terrain_stack_df$wokam_bin)
## number of remining samples
n <- nrow(terrain_stack_df)


## divide into training and test data
indextrain <- sample(1:n,round(0.6*n),replace=FALSE)
Xtrain     <- terrain_stack_df[ indextrain,1:3]
Xtest      <- terrain_stack_df[-indextrain,1:3]
Ytrain     <- terrain_stack_df[ indextrain,4]
Ytest      <- terrain_stack_df[-indextrain,4]


################################################
##     compute Quantile Regression Forests    ##
################################################

#qrf <- quantregForest(x=Xtrain, y=Ytrain)
qrf <- quantregForest(x=Xtrain, y=Ytrain, nodesize=30,ntree=500)


## for parallel computation use the nthread option
## qrf <- quantregForest(x=Xtrain, y=Ytrain, nthread=8)

## predict 0.1, 0.5 and 0.9 quantiles for test data
conditionalQuantiles  <- predict(qrf,  Xtest)
print(conditionalQuantiles[1:4,])

## predict 0.1, 0.2,..., 0.9 quantiles for test data
conditionalQuantiles  <- predict(qrf, Xtest, what=0.1*(1:9))
print(conditionalQuantiles[1:4,])

## estimate conditional standard deviation
conditionalSd <- predict(qrf,  Xtest, what=sd)
print(conditionalSd[1:4])

## estimate conditional mean (as in original RF)
conditionalMean <- predict(qrf,  Xtest, what=mean)
conditionalMean <- as.numeric(conditionalMean)-1
#conditionalMean <- round(conditionalMean,0)
print(conditionalMean[1:4])

## estimate conditional mean (as in original RF)
conditionalMeantrain <- predict(qrf,  Xtrain, what=mean)
conditionalMeantrain <- as.numeric(conditionalMeantrain)-1
#conditionalMeantrain <- round(conditionalMeantrain,0)
print(conditionalMeantrain[1:4])

## sample 10 new observations from conditional distribution at each new sample
newSamples <- predict(qrf, Xtest,what = function(x) sample(x,10,replace=TRUE))
print(newSamples[1:4,])


## get ecdf-function for each new test data point
## (output will be a list with one element per sample)
condEcdf <- predict(qrf,  Xtest, what=ecdf)
condEcdf[[10]](30) ## get the conditional distribution at value 30 for i=10
## or, directly, for all samples at value 30 (returns a vector)
condEcdf30 <- predict(qrf, Xtest, what=function(x) ecdf(x)(30))
print(condEcdf30[1:4])

## to use other functions of the package randomForest, convert class back
class(qrf) <- "randomForest"
importance(qrf) ## importance measure from the standard RF


#####################################
## out-of-bag predictions and sampling
#####################################

## for with option keep.inbag=TRUE
qrf <- quantregForest(x=Xtrain, y=Ytrain, keep.inbag=TRUE)

## or use parallel version
## qrf <- quantregForest(x=Xtrain, y=Ytrain, nthread=8)

## get quantiles 
oobQuantiles <- predict( qrf, what= c(0.2,0.5,0.8))

## sample from oob-distribution
oobSample <- predict( qrf, what= function(x) sample(x,1))

getTree(qrf, 1, labelVar=TRUE)

#####################################
## Generate random numbers
#####################################

set.seed(234)
random_vals <- sample(c(0, 1), size = nrow(terrain_stack_df), replace = TRUE, prob = c(0.704,0.296))

#####################################
## reverse to raster object
#####################################

terrain_stack_sample_df <- as.data.frame(terrain_stack_sample)

row.has.na <- apply(terrain_stack_sample_df, 1, function(x){any(is.na(x))})

terrain_stack_sample$wokam_pred <- NA
terrain_stack_df$wokam_pred <- NA
terrain_stack_sample$random <- NA

terrain_stack_df$wokam_pred[indextrain] <- conditionalMeantrain
terrain_stack_df$wokam_pred[-indextrain] <- conditionalMean
terrain_stack_df$random <-random_vals

terrain_stack_sample$wokam_pred[!(row.has.na)] <- round(terrain_stack_df$wokam_pred,0)
terrain_stack_sample$wokam_bin[row.has.na] <- NA
terrain_stack_sample$random[!(row.has.na)] <- terrain_stack_df$random
terrain_stack_sample$random[row.has.na] <- NA

dev.off()

headers <- c("Rescaled elevation", "Rescaled slope", "Rescaled flow direction", "WOKAM", "simulated QRF", "Random")

# dev.new(height=0.91*nrow(terrain_stack_sample[[1]])/50, width=1.09*ncol(terrain_stack_sample[[1]])/50)
# par(mfrow=c(2,3))
# 
# for (i in 1:6){
# 
# plot(terrain_stack_sample[[i]],
#      box = FALSE,
#      col = grey(1:100/100),
#      main = headers[i], 
#      cex.main=1.5, cex.lab=1.5, cex.axis=1.2)
# }
# 
# dev.copy(pdf,"C:/Users/nadja/Documents/Masterarbeit/DATA/randomeurope.pdf")
# dev.off()
# 
# length(which(terrain_stack_df$wokam_bin == round(terrain_stack_df$wokam_pred,0)))/nrow(terrain_stack_df)
# 
# length(which(terrain_stack_df$wokam_bin == round(terrain_stack_df$random,0)))/nrow(terrain_stack_df)

X11(15,10)  
levelplot(terrain_stack_sample,layout=c(3, 2),margin=FALSE,col.regions =rev(grey(1:100/100)), names.attr=headers, main = "Quantile regression forest Lidar testing data")#colorkey=list(space="bottom")


dev.copy(pdf,"C:/Users/nadja/Documents/Masterarbeit/DATA/randomeurope.pdf", width = 9, height = 6)
dev.off()



#####################################
## Acessing performance
#####################################


prob1train <- length(which(as.numeric(Ytrain)-1 ==1))/length(Ytrain)
prob0train <- length(which(as.numeric(Ytrain)-1 ==0))/length(Ytrain)

prob1test <- length(which(as.numeric(Ytest)-1 ==1))/length(Ytest)
prob0test <- length(which(as.numeric(Ytest)-1 ==0))/length(Ytest)
length(Ytrain)
length(Ytest)
train_acc <-(100/nrow(terrain_stack_df[indextrain,]))*length(which(round(terrain_stack_df[indextrain,]$wokam_pred,0) == as.numeric(terrain_stack_df[indextrain,]$wokam_bin)-1))

test_acc <-(100/nrow(terrain_stack_df[-indextrain,]))*length(which(round(terrain_stack_df[-indextrain,]$wokam_pred,0) == as.numeric(terrain_stack_df[-indextrain,]$wokam_bin)-1))

rand_acc <-(100/nrow(terrain_stack_df))*length(which(round(terrain_stack_df$random,0) == as.numeric(terrain_stack_df$wokam_bin)-1))

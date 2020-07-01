from __future__ import absolute_import, division, print_function, unicode_literals
import tensorflow as tf
import tensorflow.keras
from sklearn.utils.class_weight import compute_class_weight
import pandas as pd
import numpy as np
import os

from skimage.io import imread
from glob import glob
from random import choices
from sklearn import preprocessing
from skimage import exposure

import rasterio
from rasterio.plot import show
#from sklearn.impute import SimpleImputer
#So, I like to split the batch generator into 4 steps:
#1. Get input            : input_path -> image
#2. Get output           : input_path -> label
#3. Pre-process input    : image -> pre-processing step -> image
#4. Get generator output : ( batch_input, batch_labels )
#Step 1 : Define a function to get input (can be subsetting a numpy array, pandas dataframe, reading in from disk etc.) :

def get_input(path):
 
    img = imread( path)
    
    return( img )
#Step 2 : Define a function to get output :

def get_output( path_2 ):
    
    labels = imread( path_2 )
    
    return(labels)

#Step 3 : Define a function to preprocess input :
def preprocess_input( image ):
    
    image = np.array(image)
    
    return( image )


def preprocess_output( image, categorical ):
    
    image = np.array(image)
    
    if categorical == True:
        image = tf.keras.utils.to_categorical(image, num_classes=2)
    else:
        image = image[:,:, np.newaxis]
    
    return( image )

#Step 4 : Bring everything together to define your generator :
def image_generator(files, files_2, batch_size = 2, intensify = False, random = True, batch_start = 0, categorical = True, lidar = False):
    
    samples_per_epoch = len(files)
    number_of_batches = samples_per_epoch/batch_size
    counter=0
    
    while True:
       
        if random == True:
            random_index = choices(range(len(files)), k = batch_size)
        else: 
            random_index = range(batch_size*counter,batch_size*(counter+1))
     
        batch_input  = []
        batch_output = [] 
        
                
          # Read in each input, perform preprocessing and get labels
        if intensify == 10:
            for indx in random_index:
                raster = get_input(files[int(indx)] )
                mask = get_output(files_2[int(indx)])

                mask_idx = mask               
                
                band_1 = raster[:,:,0]
                band_2 = raster[:,:,1]
                band_3 = raster[:,:,2]
                
                image_inx_1 = np.nan_to_num(np.where(mask_idx > 0, band_1, np.multiply(band_1,1.1)))
                image_inx_2 = np.nan_to_num(np.where(mask_idx > 0, band_2, np.multiply(band_2,1.1)))
                image_inx_3 = np.nan_to_num(np.where(mask_idx > 0, band_3, np.multiply(band_3,1.1)))
                
                 
                #imputer=SimpleImputer(missing_values=np.nan,strategy='mean')
                #imputer=imputer.fit(image_inx_1)
                #image_inx_1=imputer.transform(image_inx_1)
                
                #imputer=SimpleImputer(missing_values=np.nan,strategy='mean')
                #imputer=imputer.fit(image_inx_2)
                #image_inx_2=imputer.transform(image_inx_2)
                
                #imputer=SimpleImputer(missing_values=np.nan,strategy='mean')
                #imputer=imputer.fit(image_inx_3)
                #image_inx_3=imputer.transform(image_inx_3)


                out_band_1 = preprocessing.minmax_scale(image_inx_1,feature_range=(0.2, 1))
                out_band_2 = preprocessing.minmax_scale(image_inx_2, feature_range=(0.2, 1))
                out_band_3 = preprocessing.minmax_scale(image_inx_3, feature_range=(0.2, 1))

                image_inx_1 = exposure.equalize_hist(out_band_1)
                image_inx_2 = exposure.equalize_hist(out_band_2)
                image_inx_3 = exposure.equalize_hist(out_band_3)

                raster = np.dstack((image_inx_1, image_inx_2, image_inx_3))

                raster_preproc = preprocess_input(image=raster)
                mask = preprocess_output(image = mask, categorical = categorical)

                batch_input += [ raster_preproc ]
                batch_output += [ mask ]

              # Return a tuple of (input, output) to feed the network
                batch_x = np.array( batch_input )
                batch_y = np.array( batch_output )

                yield( batch_x, batch_y )
                
        elif intensify == 20:
            for indx in random_index:
                raster = get_input(files[int(indx)])
                mask = get_output(files_2[int(indx)])

                mask_idx = mask                
                
                band_1 = raster[:,:,0]
                band_2 = raster[:,:,1]
                band_3 = raster[:,:,2]
                
                image_inx_1 = np.nan_to_num(np.where(mask_idx > 0, band_1, np.multiply(band_1,1.2)))
                image_inx_2 = np.nan_to_num(np.where(mask_idx > 0, band_2, np.multiply(band_2,1.2)))
                image_inx_3 = np.nan_to_num(np.where(mask_idx > 0, band_3, np.multiply(band_3,1.2)))

                out_band_1 = preprocessing.minmax_scale(image_inx_1,feature_range=(0.2, 1))
                out_band_2 = preprocessing.minmax_scale(image_inx_2, feature_range=(0.2, 1))
                out_band_3 = preprocessing.minmax_scale(image_inx_3, feature_range=(0.2, 1))

                image_inx_1 = exposure.equalize_hist(out_band_1)
                image_inx_2 = exposure.equalize_hist(out_band_2)
                image_inx_3 = exposure.equalize_hist(out_band_3)

                raster = np.dstack((image_inx_1, image_inx_2, image_inx_3))

                raster_preproc = preprocess_input(image=raster)
                mask = preprocess_output(image = mask, categorical = categorical)

                batch_input += [ raster_preproc ]
                batch_output += [ mask ]

              # Return a tuple of (input, output) to feed the network
                batch_x = np.array( batch_input )
                batch_y = np.array( batch_output )

                yield( batch_x, batch_y )
                
        elif intensify == 50:
            for indx in random_index:
                raster = get_input(files[int(indx)])
                mask = get_output(files_2[int(indx)])

                mask_idx = mask              
                
                band_1 = raster[:,:,0]
                band_2 = raster[:,:,1]
                band_3 = raster[:,:,2]
                
                image_inx_1 = np.nan_to_num(np.where(mask_idx > 0, band_1, np.multiply(band_1,1.05)))
                image_inx_2 = np.nan_to_num(np.where(mask_idx > 0, band_2, np.multiply(band_2,1.05)))
                image_inx_3 = np.nan_to_num(np.where(mask_idx > 0, band_3, np.multiply(band_3,1.05)))

                out_band_1 = preprocessing.minmax_scale(image_inx_1,feature_range=(0.2, 1))
                out_band_2 = preprocessing.minmax_scale(image_inx_2, feature_range=(0.2, 1))
                out_band_3 = preprocessing.minmax_scale(image_inx_3, feature_range=(0.2, 1))
                
                image_inx_1 = exposure.equalize_hist(out_band_1)
                image_inx_2 = exposure.equalize_hist(out_band_2)
                image_inx_3 = exposure.equalize_hist(out_band_3)

                raster = np.dstack((image_inx_1, image_inx_2, image_inx_3))

                raster_preproc = preprocess_input(image=raster)
                mask = preprocess_output(image = mask, categorical = categorical)

                batch_input += [ raster_preproc ]
                batch_output += [ mask ]

              # Return a tuple of (input, output) to feed the network
                batch_x = np.array( batch_input )
                batch_y = np.array( batch_output )

                yield( batch_x, batch_y )
                
        elif lidar == True:
            for indx in random_index:
                raster = get_input(files[int(indx)])
                mask = get_output(files_2[int(indx)])

                raster = raster[0:1000,0:1000].reshape(1000,1000)
                
                                
                raster = preprocessing.minmax_scale(raster,feature_range=(0.2, 1))
                #raster = exposure.equalize_hist(raster)
                
                raster = raster.reshape(1000,1000,1)

                raster_preproc = np.nan_to_num(preprocess_input(image=raster))   
                
                mask = mask[0:1000,0:1000]
                                
                mask = np.where(mask < 0, 1, mask)
                
                mask = np.nan_to_num(preprocess_output(image = mask.reshape(1000,1000), categorical = categorical))

                batch_input += [ raster_preproc ]
                batch_output += [ mask ]

              # Return a tuple of (input, output) to feed the network
                batch_x = np.array( batch_input )
                batch_y = np.array( batch_output )

                yield( batch_x, batch_y )
            
        else:
            
            for indx in random_index:
                raster = get_input(files[int(indx)])
                mask = get_output(files_2[int(indx)])
                    
                raster = preprocess_input(image=raster)
                    
                band_1 = preprocessing.minmax_scale(raster[:,:,0],feature_range=(0.2, 1))
                band_2 = preprocessing.minmax_scale(raster[:,:,1], feature_range=(0.2, 1))
                band_3 = preprocessing.minmax_scale(raster[:,:,2], feature_range=(0.2, 1))

                image_inx_1 = exposure.equalize_hist(band_1)
                image_inx_2 = exposure.equalize_hist(band_2)
                image_inx_3 = exposure.equalize_hist(band_3)

                raster_preproc = np.dstack((image_inx_1, image_inx_2, image_inx_3))

                mask = preprocess_output(image = mask, categorical = categorical)

                batch_input += [ raster_preproc ]
                batch_output += [ mask ]

                  # Return a tuple of (input, output) to feed the network
                batch_x = np.array( batch_input )
                batch_y = np.array( batch_output )

                yield( batch_x, batch_y )
                
        if counter >= number_of_batches:
            counter = 0
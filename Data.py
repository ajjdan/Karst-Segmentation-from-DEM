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

#So, I like to split the batch generator into 4 steps:
#1. Get input            : input_path -> image
#2. Get output           : input_path -> label
#3. Pre-process input    : image -> pre-processing step -> image
#4. Get generator output : ( batch_input, batch_labels )
#Step 1 : Define a function to get input (can be subsetting a numpy array, pandas dataframe, reading in from disk etc.) :

def get_input(path):
    
    img = imread( path )
    
    return( img )
#Step 2 : Define a function to get output :

def get_output( path_2 ):
    
    labels = imread( path_2 )
    
    return(labels)

#Step 3 : Define a function to preprocess input :
def preprocess_input( image ):
    
    image = np.array(image)
    
    return( image )


def preprocess_output( image ):
    
    image = np.array(image)
    
    image = tf.keras.utils.to_categorical(image)
    
    return( image )

#Step 4 : Bring everything together to define your generator :
def image_generator(files, files_2, batch_size = 64, intensify = False):
    
    while True:
          # Select files (paths/indices) for the batch
        #batch_paths  = np.random.choice(a = files, 
        #                                  size = batch_size)
        random_index = choices(range(len(files)), k = batch_size)
      
        batch_input  = []
        batch_output = [] 
          
          # Read in each input, perform preprocessing and get labels
        if intensify == True:
            for indx in random_index:
                raster = get_input(files[int(indx)] )
                mask = get_output(files_2[int(indx)])

                mask_idx = mask.reshape(128*128)

                band_1 = preprocessing.minmax_scale(raster[:,:,0],feature_range=(0.2, 1)).reshape(128*128*1)
                band_2 = preprocessing.minmax_scale(raster[:,:,1], feature_range=(0.2, 1)).reshape(128*128*1)
                band_3 = preprocessing.minmax_scale(raster[:,:,2], feature_range=(0.2, 1)).reshape(128*128*1)

                image_inx_1 = np.where(mask_idx > 0, band_1, 10*band_1).reshape(128,128)
                image_inx_2 = np.where(mask_idx > 0, band_2, 10*band_2).reshape(128,128)
                image_inx_3 = np.where(mask_idx > 0, band_3, 10*band_3).reshape(128,128)

                raster = np.dstack((image_inx_1, image_inx_2, image_inx_3))

                raster_preproc = preprocess_input(image=raster)
                mask = preprocess_output(image = mask)

                batch_input += [ raster_preproc ]
                batch_output += [ mask ]

              # Return a tuple of (input, output) to feed the network
                batch_x = np.array( batch_input )
                batch_y = np.array( batch_output )

                yield( batch_x, batch_y )
            
        else:
            
            for indx in random_index:
                raster = get_input(files[int(indx)] )
                mask = get_output(files_2[int(indx)])
                    
                raste = preprocess_input(image=raster)
                    
                band_1 = preprocessing.minmax_scale(raster[:,:,0],feature_range=(0.2, 1)).reshape(128*128*1)
                band_2 = preprocessing.minmax_scale(raster[:,:,1], feature_range=(0.2, 1)).reshape(128*128*1)
                band_3 = preprocessing.minmax_scale(raster[:,:,2], feature_range=(0.2, 1)).reshape(128*128*1)

                image_inx_1 = exposure.equalize_hist(band_1).reshape(128,128)
                image_inx_2 = exposure.equalize_hist(band_2).reshape(128,128)
                image_inx_3 = exposure.equalize_hist(band_3).reshape(128,128)

                raster_preproc = np.dstack((image_inx_1, image_inx_2, image_inx_3))

                mask = preprocess_output(image = mask)

                batch_input += [ raster_preproc ]
                batch_output += [ mask ]

                  # Return a tuple of (input, output) to feed the network
                batch_x = np.array( batch_input )
                batch_y = np.array( batch_output )

                yield( batch_x, batch_y )
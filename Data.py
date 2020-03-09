from __future__ import absolute_import, division, print_function, unicode_literals
import tensorflow as tf
import tensorflow.keras
from sklearn.utils.class_weight import compute_class_weight
import pandas as pd
import numpy as np
import os
from sklearn.preprocessing import LabelEncoder, OneHotEncoder
import matplotlib.pyplot as plt

def get_data_from_npz(path, filename, categorical):
    
    data_dir = tf.keras.utils.get_file(origin="file:" + path, fname=filename)

    with np.load(data_dir) as data:
        train_examples = data['x_train']
        train_labels = data['y_train']
        test_labels =  data['y_test']
        test_examples = data['x_test']

    num_test_img = test_labels.shape[0]
    num_train_img = train_labels.shape[0]
    img_heigth = test_labels.shape[1]
    img_width = test_labels.shape[2]
    num_categories = 2
    
    if categorical is True :
        train_labels_small= train_labels[:,:,:,0].astype(int)
        test_labels_small = test_labels[:,:,:,0].astype(int)
        #train_labels_small += 1
        #test_labels_small += 1
        train_labels_category = tf.keras.utils.to_categorical(train_labels_small)#.reshape(num_train_img,img_heigth*img_width,num_categories)
        test_labels_category = tf.keras.utils.to_categorical(test_labels_small)#.reshape(num_test_img,img_heigth*img_width,num_categories)

        return train_examples, test_examples, train_labels_category, test_labels_category
    
    else:

        return train_examples, test_examples, train_labels, test_labels

@tf.function
def load_image_train(datapoint_1, datapoint_2):
    input_image = tf.image.resize(datapoint_1, (128, 128))
    input_mask = tf.image.resize(datapoint_2, (128, 128))

    return input_image, input_mask

def load_image_test(datapoint_1, datapoint_2):
    input_image = tf.image.resize(datapoint_1, (128, 128))
    input_mask = tf.image.resize(datapoint_2, (128, 128))
    
    return input_image, input_mask

def display(display_list):
    plt.figure(figsize=(15, 15))

    title = ['Input Image', 'True Mask', 'Predicted Mask']

    for i in range(len(display_list)):
        plt.subplot(1, len(display_list), i+1)
        plt.title(title[i])
        if display_list[i].shape[2] == 3:
            plt.imshow(display_list[i])
            plt.axis('off')
        else:
            plt.imshow(display_list[i][:,:,0], cmap = "Greys")
            plt.axis('off')
    plt.show()
    
def get_datagen(): 
    datagen = keras.preprocessing.image.ImageDataGenerator(
    samplewise_center=True,
    samplewise_std_normalization=True
    #rotation_range=20,
    #width_shift_range=0.2,
    #height_shift_range=0.2,
    #horizontal_flip=True)
    )
    
    return datagen

    

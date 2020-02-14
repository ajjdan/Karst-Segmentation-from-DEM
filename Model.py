# adapted from : https://github.com/ykamikawa/tf-keras-SegNet/blob/master/model.py
from __future__ import absolute_import, division, print_function, unicode_literals
import tensorflow as tf
from tensorflow.keras import datasets, layers, models
import keras

from MaxPool import MaxPoolingWithArgmax2D, MaxUnpooling2D



def KaI():

    terrain = keras.layers.Input(shape=(128 , 200, 3), name='terrain')

    #lay1 = keras.layers.BatchNormalization()(terrain)

    lay2 = keras.layers.Conv2D(3, (3, 3), activation='relu', padding="same" )(terrain)
    lay3= keras.layers.Conv2D(3, (3, 3), activation='relu', padding="same" )(lay2)
    lay4 = keras.layers.BatchNormalization()(lay3)
    lay5 , mask1 = MaxPoolingWithArgmax2D((2, 2))(lay4)

    lay6= keras.layers.Conv2D(3, (3, 3), activation='relu', padding="same" )(lay5)
    lay7 = keras.layers.Conv2D(3, (3, 3), activation='relu', padding="same" )(lay6)
    lay8 = keras.layers.BatchNormalization()(lay7)
    lay9, mask2 = MaxPoolingWithArgmax2D((2, 2))(lay8)

    lay10 = keras.layers.Conv2D(3, (3, 3), activation='relu', padding="same" )(lay9)
    lay11 = keras.layers.Conv2D(3, (3, 3), activation='relu', padding="same" )(lay10)
    lay12 = keras.layers.BatchNormalization()(lay11)
    lay13, mask3 = MaxPoolingWithArgmax2D((2, 2))(lay12)

    lay14 = MaxUnpooling2D((2,2))([lay13, mask3])
    lay15 = keras.layers.Conv2D(3, (3, 3), activation='relu', padding="same" )(lay14)
    lay16 = keras.layers.Conv2D(3, (3, 3), activation='relu', padding="same" )(lay15)
    lay17 = keras.layers.BatchNormalization()(lay16)

    lay18 = MaxUnpooling2D((2,2))([lay17, mask2])
    lay19 = keras.layers.Conv2D(3, (3, 3), activation='relu', padding="same" )(lay18)
    lay20 = keras.layers.Conv2D(3, (3, 3), activation='relu', padding="same" )(lay19)
    lay21 = keras.layers.BatchNormalization()(lay20)

    lay22 = MaxUnpooling2D((2,2))([lay21, mask1])
    lay23 = keras.layers.Conv2D(3, (3, 3), activation='relu', padding="same" )(lay22)
    lay24 = keras.layers.Conv2D(3, (3, 3), activation='relu', padding="same" )(lay23)
    lay25 = keras.layers.BatchNormalization()(lay24)

    lay26 = keras.layers.Conv2D(n_labels, (1, 1), activation='relu', padding="valid")(lay25)
    lay27 = keras.layers.BatchNormalization()(lay26)
    lay28 = keras.layers.Reshape((128*200, n_labels),input_shape=(128,200, n_labels))(lay27)

    outputs = keras.layers.Activation("softmax")(lay28) #sigmoid for binary and softmax for more classes

    model = keras.Model(inputs=terrain, outputs=outputs)
    return model

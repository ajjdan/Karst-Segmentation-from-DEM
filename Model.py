"""A simplified U-Net model.
//arxiv.org/pdf/1505.04597
source: https://github.com/mrubash1/keras-semantic-segmentation/blob/develop/src/semseg/models/unet.py
"""

from keras.models import Model
from keras.layers import (
    Input, concatenate, Convolution2D, MaxPooling2D, UpSampling2D, Activation,
    Reshape, BatchNormalization, ZeroPadding2D, Cropping2D)

def make_conv_block(nb_filters, input_tensor, block):
    def make_stage(input_tensor, stage):
        x = Convolution2D(nb_filters,(3,3), activation='relu',  padding = "same")(input_tensor)
        x = BatchNormalization()(x)
        x = Activation('relu')(x)
        return x

    x = make_stage(input_tensor, 1)
    x = make_stage(x, 2)
    return x


def make_KaI(input_shape, nb_labels):
    """Make a U-Net model.
    # Arguments
        input_shape: tuple of form (nb_rows, nb_cols, nb_channels)
        nb_labels: number of labels in dataset
    # Return
        The Keras model
    """
    #nb_rows, nb_cols, _ = input_shape
    
    terrain = Input(input_shape)
    pad_in = ZeroPadding2D(14)(terrain)
    
    conv1 = make_conv_block(32, pad_in, 1)
    pool1 = MaxPooling2D(pool_size=(2, 2), padding="same")(conv1)

    conv2 = make_conv_block(64, pool1, 2)
    pool2 = MaxPooling2D(pool_size=(2, 2), padding="same")(conv2)

    conv3 = make_conv_block(128, pool2, 3)
    pool3 = MaxPooling2D(pool_size=(2, 2), padding="same")(conv3)

    conv4 = make_conv_block(256, pool3, 4)
    pool4 = MaxPooling2D(pool_size=(2, 2))(conv4)

    conv5 = make_conv_block(512, pool4, 5)

    up6 = concatenate([UpSampling2D(size=(2, 2))(conv5), conv4], axis=3)
    conv6 = make_conv_block(256, up6, 6)

    up7 = concatenate([UpSampling2D(size=(2, 2))(conv6), conv3], axis=3)
    conv7 = make_conv_block(128, up7, 4)

    up8 = concatenate([UpSampling2D(size=(2, 2))(conv7), conv2], axis=3)
    conv8 = make_conv_block(64, up8, 5)

    up9 = concatenate([UpSampling2D(size=(2, 2))(conv8), conv1], axis=3)
    conv9 = make_conv_block(32, up9, 6)

    conv10 = Convolution2D(2,(1, 1),padding="same")(conv9)
    
    out_pad = Cropping2D((14))(conv10)
    
    output = Reshape((100 * 100, 2),input_shape=(100,100,2))(out_pad)
    output = Activation('softmax')(output)
    output = Reshape((100, 100, 2),input_shape=(100*100, 2))(output)

    model = Model(inputs=terrain, outputs=output)

    return model

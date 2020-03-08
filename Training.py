#!/usr/bin/env python
# coding: utf-8

# 
# # Training The CNN to identify karstified areas
# 

# In[1]:


from __future__ import absolute_import, division, print_function, unicode_literals

import tensorflow as tf
tf.enable_eager_execution()

from tensorflow.keras import datasets, layers, models
import matplotlib.pyplot as plt

import numpy as np

import tensorflow.keras

import os

import timeit

from matplotlib.backends.backend_pdf import PdfPages
from IPython.display import clear_output


# In[2]:


os.environ['CUDA_VISIBLE_DEVICES'] = '-1'


# ## Importing the Data

# In[3]:


path = "D:/Masterarbeit/Data/Balkans/data/data_balkans.npz"
filename = "data_balkans.npz"
categorical = True
batch_size = 20


# In[4]:


from Data import get_data_from_npz, get_class_weights, get_datagen


# In[5]:


train_examples, test_examples, train_labels_category, test_labels_category = get_data_from_npz(path, filename, categorical)


# In[6]:


train_examples, test_examples, train_labels_category, test_labels_category = train_examples[0:6600, :, :, :], test_examples[0:1660, :, :, :], train_labels_category[0:6600, :, :, :], test_labels_category[0:1660, :, :, :] 


# ## Setting training Parameters

# In[7]:


TRAIN_LENGTH = 6600
BATCH_SIZE = 20
BUFFER_SIZE = 1000
STEPS_PER_EPOCH = TRAIN_LENGTH // BATCH_SIZE


# ## Format the data as tfRecord

# In[8]:


@tf.function
def load_image_train(datapoint_1, datapoint_2):
    input_image = tf.image.resize(datapoint_1, (128, 128))
    input_mask = tf.image.resize(datapoint_2, (128, 128))
    input_mask += 1

    if tf.random.uniform(()) > 0.5:
        input_image = tf.image.flip_left_right(input_image)
        input_mask = tf.image.flip_left_right(input_mask)

    return input_image, input_mask

def load_image_test(datapoint_1, datapoint_2):
    input_image = tf.image.resize(datapoint_1, (128, 128))
    input_mask = tf.image.resize(datapoint_2, (128, 128))
    input_mask += 1
    
    return input_image, input_mask

train = tf.data.Dataset.from_tensor_slices((train_examples, train_labels_category)).map(load_image_train, num_parallel_calls=tf.data.experimental.AUTOTUNE)
test =  tf.data.Dataset.from_tensor_slices((test_examples, test_labels_category)).map(load_image_test)

train_dataset = train.cache().shuffle(BUFFER_SIZE).batch(BATCH_SIZE).repeat()
train_dataset = train_dataset.prefetch(buffer_size=tf.data.experimental.AUTOTUNE)
test_dataset = test.batch(BATCH_SIZE)


# In[9]:


#class_weights = get_class_weights(train_labels_category.reshape((6617, 128* 128, 2)))
# Treat every instance of class 1 as 50 instances of class 0 to account for biased data
# get_class_weights function is not working properly yet

class_weights = {0: 1.,
                1: 50.}


# In[10]:


print(train_examples.shape)
print(test_labels_category.shape)

print("number of samples:" + str(test_examples.shape[0] + train_examples.shape[0]))


# In[11]:


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

for image, mask in train.take(5000):
      sample_image, sample_mask = image, mask
display([sample_image, sample_mask])


# In[13]:


num_epochs = 3
batch_size = 15
num_samples = train_examples.shape[0]
num_samples_val = test_examples.shape[0]
steps_per_epoch = num_samples/batch_size
val_steps = num_samples_val/batch_size
n_labels = 2


# ### Import the model

# In[14]:


from Model import make_KaI


# In[15]:


model = make_KaI((128,128,3),2)
model.summary()


# In[15]:


import pydotplus
import keras.utils
keras.utils.vis_utils.pydot = pydotplus
tf.keras.utils.plot_model(model, to_file="D:/Masterarbeit/Data/Randbereiche/model_full_unpool.png", show_shapes=True)


# ### Compile the model

# In[16]:


sgd = tf.keras.optimizers.SGD(lr=1e-5)
adam = tf.keras.optimizers.Adam(lr=0.001)
adadelta = tf.keras.optimizers.Adadelta(lr=1e-5)


# In[17]:


model.compile(optimizer=adam,
              loss= "categorical_crossentropy",
              metrics=["accuracy"])


# ### Fit the model 

# In[18]:


def create_mask(pred_mask):
    pred_mask = tf.argmax(pred_mask, axis=-1)
    pred_mask = pred_mask[..., tf.newaxis]
    return pred_mask[0]


# In[19]:


def show_predictions(dataset=None, num=1):
    if dataset:
        pred_mask = model.predict(image)
        display([image[0], mask[0], create_mask(pred_mask)])
    else:
        display([sample_image, sample_mask,
        create_mask(model.predict(sample_image[tf.newaxis, ...]))])


# In[20]:


class DisplayCallback(tf.keras.callbacks.Callback):
    def on_epoch_end(self, epoch, logs=None):
        clear_output(wait=True)
        show_predictions()
        print ('\nSample Prediction after epoch {}\n'.format(epoch+1))


# In[21]:


EPOCHS = 2
VAL_SUBSPLITS = 5
VALIDATION_STEPS = 1660//BATCH_SIZE//VAL_SUBSPLITS

start = timeit.default_timer()

model_history = model.fit(train_dataset, epochs=EPOCHS,
                          steps_per_epoch=STEPS_PER_EPOCH,
                          validation_steps=VALIDATION_STEPS,
                          validation_data=test_dataset,
                          class_weight = class_weights,
                          callbacks=[DisplayCallback()])

stop = timeit.default_timer()
print(stop-start)


# In[22]:


loss = model_history.history['acc']
val_loss = model_history.history['val_acc']

epochs = range(EPOCHS)

plt.figure()
plt.plot(epochs, loss, 'r', label='Training loss')
plt.plot(epochs, val_loss, 'bo', label='Validation loss')
plt.title('Training and Validation Loss')
plt.xlabel('Epoch')
plt.ylabel('Loss Value')
plt.ylim([0, 1])
plt.legend()
plt.show()


# In[23]:


show_predictions()


# ## View training history

# In[24]:


print(model_history.history.keys())


# In[25]:


model.save("D:/Masterarbeit/Data/Balkans/CNN_06.hdf5")


# In[33]:


from tensorflow.keras.models import load_model
model = load_model('D:/Masterarbeit/Data/Balkans/CNN_06.hdf5')


# In[31]:


with PdfPages("C:/Users/Veigel/Pictures/Memos/training_loss_balkans.pdf") as pdf:
# Plot training & validation accuracy values
    fig, (ax1, ax2) = plt.subplots(1,2, figsize=(15,5))
    ax1.plot(model_history.history['acc'])
    ax1.plot(model_history.history['val_acc'])
    ax1.set_title('Model accuracy')
    ax1.set_ylabel('Accuracy')
    ax1.set_xlabel('Epoch')
    ax1.legend(['Train', 'Test'], loc='upper left')
    fig.show()
        
        # Plot training & validation loss values
    ax2.plot(model_history.history['loss'])
    ax2.plot(model_history.history['val_loss'])
    ax2.set_title('Model loss')
    ax2.set_ylabel('Loss')
    ax2.set_xlabel('Epoch')
    ax2.legend(['Train', 'Test'], loc='upper left')
    fig.show()
    #pdf.savefig(fig)


# In[32]:


plt.close(fig="all")


# ## Make Predictions

# In[52]:


predictions = model.predict(test_examples)
#preds_reshape = predictions.reshape(num_samples_val, 100,100,2)


# In[54]:


preds = np.argmax(predictions, axis=-1)


# In[55]:


#print(preds_reshape.shape)
print(preds.shape)
#print(preds_reshape[19,:,:,0])
print(preds[19,:,:])


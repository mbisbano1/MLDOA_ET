# Daniel J. Lopes
# ECE 457/458
# 11/11/2021
# name: MLDOA.py 
# Purpose: An algorithm that trains a ML model to find the DOA of stave data

import tensorflow as tf
import pandas as pd
import matplotlib.pyplot as plt

#import csv as a pandas dataframe
df=pd.read_csv(r'Path where the CSV file is stored')
print(df)# will print out a nice looking chart

#create the feature layer
feature_columns=[] #empty list that will eventually contain all of our features

#will do a for loop for this later -Dan
#################################################################################
I1=tf.feature.column.numeric_column("I1")#names the column in the list
feature_column.append(I1) #append the column to the list

I2=tf.feature.column.numeric_column("I2")
feature_column.append(I2) #append the column to the list

I3=tf.feature.column.numeric_column("I3")
feature_column.append(I3) #append the column to the list

I4=tf.feature.column.numeric_column("I4")
feature_column.append(I4) #append the column to the list

I5=tf.feature.column.numeric_column("I5")
feature_column.append(I5) #append the column to the list

I6=tf.feature.column.numeric_column("I6")
feature_column.append(I6) #append the column to the list

I7=tf.feature.column.numeric_column("I7")
feature_column.append(I7) #append the column to the list

I8=tf.feature.column.numeric_column("I8")
feature_column.append(I8) #append the column to the list

I9=tf.feature.column.numeric_column("I9")
feature_column.append(I9) #append the column to the list

I10=tf.feature.column.numeric_column("I0")
feature_column.append(I0) #append the column to the list

##########################################################################
Q1=tf.feature.column.numeric_column("Q1")#names the column in the list
feature_column.append(Q1) #append the column to the list

Q2=tf.feature.column.numeric_column("Q2")
feature_column.append(Q2) #append the column to the list

Q3=tf.feature.column.numeric_column("Q3")
feature_column.append(Q3) #append the column to the list

Q4=tf.feature.column.numeric_column("Q4")
feature_column.append(Q4) #append the column to the list

Q5=tf.feature.column.numeric_column("Q5")
feature_column.append(I5) #append the column to the list

Q6=tf.feature.column.numeric_column("Q6")
feature_column.append(I6) #append the column to the list

Q7=tf.feature.column.numeric_column("Q7")
feature_column.append(I7) #append the column to the list

Q8=tf.feature.column.numeric_column("Q8")
feature_column.append(I8) #append the column to the list

Q9=tf.feature.column.numeric_column("Q9")
feature_column.append(I9) #append the column to the list

Q10=tf.feature.column.numeric_column("Q10")
feature_column.append(Q10) #append the column to the list
############################################################################

#convert the list into a layer.
fp_feature_layer=layer.DenseFeatures(feature_columns)

# define hyperparamters
learning_Rate=#
epochs=#
batch_size=#
label_name="DOA" #here we would put whatever the header is in the csv

#create_model
my_model=create_model(learning_Rate,fp.feature_layer)

#train model
epochs,rmse=train_model(my_model,train_df,epochs,batch_size,label_name)

#plot the loss curve
plot_the_loss_curve(epochs,rmse)

#test the model
test_features={name.np.array(value)for name, value in test_df.items()}
test_label=np.array(test_features.pop(label_name))
my_model.evaluate(x=test_features,y=test_label,batch_size=batch_size))


def create_model(myLearning_rate,feature_layer):
	# simple linear regressor - going to have to change to SVR
	model=tf.keras.models.sequential()
	model.add(feature_layer)
	
	#add one linear layer to the model to make a linear regressor
	model.add(tf.keras.layers.dense(units=1,input_shape=(#,#)))
	
	#construct the layers into something tensor flow can execute
	model.compile(optimize=tf.keras.optimizers.RMSprop(lr=myLearning_rate), loss='mean_squared_error", metrics=[tf.keras.metrics.RootMeanSquaredError()])
	return model



def train_model(model,dataset,epochs,batch_size,label_name):
	#Feed a data set in the model in order to train items
	features={name:np.array(value)for name, value in dataset.items()}
	label=np.array(features.pop(label_name))
	history= model.fit(x=features,y=label,batch_size=batch_size,epochs=epochs,shuffle=true)
	
	#the list is stored seperately
	
	epochs=history.epochs
	
	#isolate the RMS error for each epochs
	hist=pd.DataFrame(history.history)
	rmse=hist["rout mean_squared_error"]
	
	return epochs,rmse
	


def plot_the_loss_curve(epochs.rmse):
	#plot loss v.s. epochs
	
	plt.figure()
	plt.xlabel("Epoch")
	plt.ylabel("RMS Error")
	
	plt.plot(epochs,rmse,label="loss")
	plt.legend()
	plt.ylim([rmse.min()*0.94,rmse.max()*1.05])
	plt.show
	
	return
	
	


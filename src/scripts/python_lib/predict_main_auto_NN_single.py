# -*- coding: utf-8 -*-
"""
Created on Wed Feb 22 21:37:04 2017

@author: Jie Hou
"""
import sys
import os
sys.path.append('/home/jianliu/DeepRank3/src/scripts/python_lib/') 

from Data_loading import import_SVM
from keras.models import model_from_json
import numpy as np

import sys
if len(sys.argv) != 5:
          print 'please input the right parameters:'
          sys.exit(1)

opt=sys.argv[1] #nadam
test_datafile=sys.argv[2] #3
CV_dir = sys.argv[3]
results_test = sys.argv[4] 

  
modelfile = CV_dir+'/model-train-QA_model.json'
weightfile = CV_dir+'/model-train-weight-QA_model.h5'


if not os.path.exists(modelfile):
  print "Cuoldn't find file ",modelfile
  exit(-1)


if not os.path.exists(weightfile):
  print "Cuoldn't find file ",modelfile
  exit(-1)

testdata_all= import_SVM(test_datafile)



test_targets=testdata_all[:,0]
test_featuredata_all=testdata_all[:,1:]
test_featuredata_all = test_featuredata_all.reshape((test_featuredata_all.shape[0],test_featuredata_all.shape[1]))

print "######## Loading existing model ",modelfile;
# load json and create model
json_file_model = open(modelfile, 'r')
loaded_model_json = json_file_model.read()
json_file_model.close()

print("######## Loaded model from disk")
NN_model = model_from_json(loaded_model_json)        


print "######## Loading existing weights ",weightfile;
NN_model.load_weights(weightfile)
NN_model.compile(loss="mean_squared_error", metrics=['mse'], optimizer=opt)



print "###### Predicting Testing data";

predict_test= NN_model.predict([test_featuredata_all])

combine_true_predict= np.concatenate((test_targets.reshape(len(test_targets),1),predict_test.reshape(len(predict_test),1)),axis=1)

np.savetxt(results_test,combine_true_predict,delimiter='\t', fmt='%.6f')

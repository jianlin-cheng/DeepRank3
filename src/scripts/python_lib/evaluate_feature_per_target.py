# -*- coding: utf-8 -*-
"""
Created on Wed Feb 22 21:37:04 2017

@author: Jie Hou
"""
import sys
import os
sys.path.append('/home/jianliu/DeepRank3/src/scripts/python_lib/')  
from numpy import *
from Data_loading import import_SVM
#from Model_training import train_efficient_complex_win_filter_layer_opt
#from keras.models import model_from_json
import numpy as np
from scipy.stats.stats import pearsonr 
import sys
if len(sys.argv) != 3:
          print 'please input the right parameters: interval'
          sys.exit(1)

featurefile = sys.argv[1]
targetid = sys.argv[2]


traindata_all = import_SVM(featurefile)

#where_are_NaNs = isnan(traindata_all)
#traindata_all[where_are_NaNs] = 0

train_targets=traindata_all[:,0]
train_featuredata_all=traindata_all[:,1:]


#print "Target\tFeature\tMSE\tCorr\tloss\n"
for i in range(1,train_featuredata_all.shape[1]+1):
    feature_train=traindata_all[:,i]
    newtrainTargets = train_targets.reshape(len(train_targets),1)
    newtrainPredict = feature_train.reshape(len(feature_train),1)
    # calculate mse and correlation for each target models
    mse = np.mean(np.abs(newtrainTargets - newtrainPredict))
    corr= pearsonr(newtrainTargets,newtrainPredict)[0][0]
    pvalue= pearsonr(newtrainTargets,newtrainPredict)[1][0]
    
    # calculate loss for each target models
    best_native = np.max(newtrainTargets)
    best_predict = newtrainPredict[newtrainPredict.argmax(axis=0)]
    best_predict_native = newtrainTargets[newtrainPredict.argmax(axis=0)]
    
    loss = abs(best_native - best_predict_native)
    
    #print targetid,"\t",'feature_',i,"\t",mse,"\t",corr,"\t",loss[0][0]
    info = targetid+" feature_"+str(i).lstrip()+" "+str(mse)+" "+str(corr)+" "+str(loss[0][0])
    print info
    #results_performance_train = outputdir + "/feature_train_"+str(i)+'.txt'
    #fh = open(results_performance_train,'w')
    #fh.write(str(mse))
    #fh.close()

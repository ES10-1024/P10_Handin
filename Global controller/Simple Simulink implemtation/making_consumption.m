addpath("Functions\") 
load("prediction_scaled2.mat") 
scaled_prediction=scaled_prediction'; 
index1=1; 

average_scaled_prediction=(sum(reshape(scaled_prediction,4,[]))/4)'; 

addpath("Functions\") 
load("prediction_scaled2.mat") 
scaled_prediction=scaled_prediction'; 
load("consumption_scaled2")

average_scaled_prediction=(sum(reshape(scaled_prediction,4,[]))/4)'; 

%Removing to entires such that it is dividable with 4 
scaled_consumption=scaled_consumption(1:end-2); 
average_scaled_consumption=(sum(reshape(scaled_consumption,4,[]))/4)'; 



save("average_scaled_consumption.mat","average_scaled_consumption") 
save("average_scaled_prediction.mat","average_scaled_prediction") 




import scipy.io

def electricity_price_and_flow(time):
    """
    Extracts data from position x and 24 steps forward, 
    for the electricty and prediction consumption data.
    For the acutal consumption a entire is returned  

    Parameters:
    - time (int): The starting position/time .
    """
    
    dataTemp = scipy.io.loadmat('High_level/Data/average_scaled_consumption.mat')   #Loading in the actual consumption 
    consumptionActual = dataTemp['average_scaled_consumption']
    
    dataTemp = scipy.io.loadmat('High_level/Data/average_scaled_prediction.mat')    #Loading the predicted consumption 
    consumptionPred = dataTemp['average_scaled_prediction']
    
    dataTemp= scipy.io.loadmat('High_level/Data/ElPrice.mat')   #Loading in the electricty price 
    ElPrice=dataTemp['ElPrice']
    
    #Returning the desired entires     
    return consumptionActual[time],  consumptionPred[time:time+24], ElPrice[time:time+24]

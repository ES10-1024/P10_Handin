Short introduction to running the global model predictive controller 
To run the code the following is needed https://se.mathworks.com/matlabcentral/fileexchange/6922-progressbar 


To run the controller, open the file MPC. Remember to set the simulation time you want. For the current implementation only 9-10 days of eletrict price is avable so don't go over this amount! 

The result from running the global model predictive controller can be found in the results folder. 

In standardConstants, most values are present. Here, the MPC controller values, sampling, modeling parameter, and so on can be tunned from here  


In the functions folder are all the functions needed to run the code together, with the values needed for the consumption model and electricity prices. A short introduction to each function is shown below. 

mpcRun, here, the optimization problem is set up with all the constraints and cost functions, and the problem is solved. As initial values the current input is given 

Model, here the next volume in the water tower is determined

EletrictyPrices gives a vector of the needed electricity prices for the controller horizon. Be aware that if the sampling time is above one hour, it does not take a weight average return of the electricity price for the given hour 

DayLimitPumps returns a matrix with ones and zeros, used to add up the amount pumped for each pump station, dependent on the time of day. 

consumption, returns a vector of the predicted consumptions for the controller horizon here, an average of the variance and mean is made if the sample time is above 15 minutes.  It also returns a consumption with added noise  

plotsToGif, makes a Gif of the running controller 
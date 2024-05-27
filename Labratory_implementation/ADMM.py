import numpy as np
from solve_local_optimisation_problem import performOptimisation
from logging import logging
from SMPC import SSSS

class ADMM_optimiser_WDN:
    def __init__(self, conn1, conn2, stakeholder: int):
        self.conn1 = conn1      #TCP connection
        self.conn2 = conn2      #TCP connection
        self.N_vary_rho = 10       #Number of iterations with varying rho
        self.stakeholder = stakeholder      #My stakeholder id
        
        #Stopping criteria
        self.max_iterations = 200           #Maximum number of iterations  
        self.stop_criterion_start = 35      #When we start checking the stopping criteria
        self.n_iteration_stop_criteria = 5  #Run stopping criteria every xx iteration    
        self.between_stop_check = 5         #Iterations between checking stopping criteria 
        self.epsilon_pri = 0.07             #Value the primal residual needs to be under
        self.epsilon_dual = 0.2             #Value the dual residual needs to be under
        
        self.N_c = 24   #Control horizon
        self.N_s = 3    #Number of stakeholders
        self.N_q = 2    #number of pumps
        
        self.rho = 1      #Initial rho
        self.rho_last_solve = self.rho
        self.mu = 5       #Vary rho algorithm parameter
        self.tau = 1.5    #Vary rho algorithm parameter

        self.z=np.zeros((self.N_c*self.N_q, 1)) #Initialization ADMM
        self.log = logging("ADMM" + str(stakeholder))

        self.smpc_summer = SSSS(self.conn1, self.conn2, stakeholder, self.log)

    def optimise(self, hour : int , water_height: float):
        self.lambda_i = np.zeros((self.N_c*self.N_q, 1))    #ADMM Initialisation
        self.x_bar = np.zeros((self.N_c*self.N_q, 1))       #ADMM Initialisation
        
        #Timeshift initial guess
        self.z = np.roll(self.z, -2)
        self.z[-1] = self.z[-3]
        self.z[-2] = self.z[-4]  

        self.rho = self.rho_last_solve

        self.log.log("simulated_hour", hour, 1)
        self.log.log("water_height", water_height, 1)  

        k = 0       # Iteration number
    
        while k < self.max_iterations:
            k = k+1 #Increase the iteration count
            print("Iteration", k)
            self.log.log("k", k,1)

            #Solve local problem
            try: 
                self.x_i = performOptimisation(hour, water_height, self.stakeholder,self.rho,self.lambda_i,self.z)
                self.x_i= self.x_i.reshape(-1, 1)
            except:                                             #Have never seen this happen
                self.x_i = 3/4*self.x_i + 1/4*self.z    	    
                print("Local optimisation failed")
                self.log.log("optimisation failed", 1, 0)
            self.log.log("x_i", self.x_i, 5)

            ### BEGIN ADMM
            self.z_i = self.x_i + (1/self.rho)*self.lambda_i    #Stakeholders entry in calculation of z
            self.z = self.smpc_summer.sum(self.z_i) / self.N_s  #SMPC calculation of z
            self.log.log("z_i", self.z_i, 5)
            self.log.log("z", self.z, 5)
            
            self.lambda_i = self.lambda_i + self.rho*(self.x_i - self.z)   #Calculation of z 
            self.log.log("lambda_i", self.lambda_i, 5)       
            ### END ADMM 
            
           ### BEGIN find rho
            if(k<=self.N_vary_rho):
                self.x_bar_old = self.x_bar
                self.x_bar = 1/self.N_s*self.smpc_summer.sum(self.x_i)
                
                self.r_i = np.linalg.norm(self.x_i - self.x_bar, 2)**2
                
                self.r_norm_squared =  self.smpc_summer.sum(self.r_i)
                self.s_norm = self.N_s*self.rho**2*np.linalg.norm(self.x_bar - self.x_bar_old,2)**2
                self.log.log("r_norm_squred", self.r_norm_squared, 3)
                self.log.log("s_norm", self.s_norm, 3)

                if(np.sqrt(self.r_norm_squared)>self.mu*np.sqrt(self.s_norm)):
                    self.rho = self.rho * self.tau
                elif(np.sqrt(self.s_norm) > self.mu*np.sqrt(self.r_norm_squared)):
                    self.rho = self.rho / self.tau
                print("rho: ", self.rho)
                self.log.log("rho", self.rho, 2)
                 ### End find rho
                
            #Increase rho with factor 500 at iteration 30
            if(k==30):
                self.rho_last_solve = self.rho
                self.rho = self.rho*500
                
                
            ###### Stopping criteria ######
            #One iteration prior to running the stopping criteria, calculte x_bar_old
            if k >= self.stop_criterion_start - 1 and k % self.n_iteration_stop_criteria == self.n_iteration_stop_criteria-1:
                self.x_bar_old = 1/self.N_s*self.smpc_summer.sum(self.x_i)
                
            #Checking if it is time to stop       
            if k >= self.stop_criterion_start and k % self.n_iteration_stop_criteria == 0:
                self.log.log("stoppingCriterionCheck", 1, 3)
                self.x_bar = 1/self.N_s*self.smpc_summer.sum(self.x_i)
                
                self.r_i = np.linalg.norm(self.x_i - self.x_bar, 2)**2
                
                self.r_norm_squared = self.smpc_summer.sum(self.r_i)
                self.r_norm = np.sqrt(self.r_norm_squared)
                
                
                self.s_norm = np.sqrt( self.N_s*self.rho**2*np.linalg.norm(self.x_bar - self.x_bar_old,2)**2)
                self.log.log("r_norm", self.r_norm, 5)
                self.log.log("s_norm", self.s_norm, 5)
                #Checking if stopping criteria is fulfilled
                if self.r_norm <= self.epsilon_pri and self.s_norm <= self.epsilon_dual:
                    return self.x_i       #return solution, escape function           
        return self.x_i     #More than max number of iterations, return current solution
                 
        
    



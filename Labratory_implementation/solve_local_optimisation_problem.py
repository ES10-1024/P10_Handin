'''
This Function solve one of the 3 consensus ADMM local problems, 
it setup the optimization problem with its constraints and solve the problem   
''' 
import numpy as np
import casadi
from constants import c_general, c_tower, c_pump1, c_pump2
from Get_Electricity_Flow import electricity_price_and_flow

#Someting stupid that casadi wants 
Uc = casadi.MX.sym('Uc', c_general['N_c']*c_general['N_q'])

#Generate matrices needed to write cost function and constraints, a function is made to make A_31 and A_31 
def define_A_3(pump_no):

    v = np.zeros([c_general['N_q'],1])
    v[pump_no-1] = 1
    A_3 = np.kron(np.eye(c_general['N_c'],dtype=int),v.T)
    return A_3


A_1 = np.kron(np.eye(c_general['N_c'],dtype=int),np.ones((1, c_general['N_q'])) )
A_2 = np.tril(np.ones((c_general['N_c'], c_general['N_c'])))

A_31 = define_A_3(1)
A_32 = define_A_3(2)

#Gotta declare vectors and matrices of ones and zeros ahead of time to make casadi obey
ones_Nc = np.ones((c_general['N_c'], 1))
zeros_NcNq = np.zeros((c_general['N_c']*c_general['N_q'], 1))
eye_NcNq = np.eye((c_general['N_c']*c_general['N_q']))

#Function for defining the constraints for each pump, not include lower mass flow. 
def pump_specific_constraints(pump_constants, pump_no, A_3):
    
#Daily extraction limit

    #Create a vector to only take out the indeces of U for the given pump station
    v1 = np.zeros((c_general['N_c']*c_general['N_q'], 1))
    v1[pump_no-1::c_general['N_q']] = 1

    A_Q_max = v1.T * c_general['t_s'] / 3600
    b_Q_max = pump_constants['Q_max']

#Max flow
    A_q_max = A_3
    b_q_max = ones_Nc*pump_constants['q_max']   
    
    return A_Q_max, b_Q_max, A_q_max, b_q_max



def define_Jp(pump_constants, A_3, J_e, h_V, d):
    # Function to define the eletricty part of the cost function for the two pumps 

    #Elevation and water height
    elevation =    ((c_tower['rho_w']*c_tower['g_0'])/c_general['condition_scaling'])*(pump_constants['h']* (A_3 @ Uc))
    water_height = ((c_tower['rho_w']*c_tower['g_0'])/c_general['condition_scaling'])*(h_V*(A_3 @ Uc))

    #Pipe resistances
    pipe_resistance = pump_constants['r_f']/c_general['condition_scaling']*(A_3 @ (Uc * casadi.fabs(Uc)*casadi.fabs(Uc)))
    combined_pipe_resistance = (A_3 @ Uc) * (c_general['r_fsigma']/c_general['condition_scaling'] * (casadi.fabs((A_1 @ Uc)-d))*((A_1 @ Uc)-d))                                                    
    
    #Total power consumption
    P = 1/pump_constants['eta'] * (pipe_resistance + combined_pipe_resistance + water_height + elevation)
    
    #Final cost function for J_p
    return J_e.T @ P


def define_cost_func_and_constraints_ADMM(d,V_0, J_e, stakeholderID,rho,Lambda,z): 
    #Must be defined before cost function can be found
    
    #Flow into the tower
    q_sigma = (A_1 @ (Uc* c_general['hours_to_seconds']*c_general['t_s']))  - (d* c_general['hours_to_seconds']*c_general['t_s']) 

    
    h_V = 1/c_tower['A_t']* (A_2 @ q_sigma + V_0)   #Height of water in tower
    
    if stakeholderID==1: 
        #Water tower
        J_p=0   #Private part of cost function

        #Constraints
        #Positive pump flow
        A_q_min = -eye_NcNq
        b_q_min = zeros_NcNq
        
        #Minimum volume in tower
        A_tower_min_vol = -A_2 @ A_1 * c_general['t_s'] / 3600
        b_tower_min_vol = - c_tower['V_min'] * ones_Nc + V_0*ones_Nc - (A_2 @ d)*c_general['t_s']/3600
    
        #Maximum volume in tower
        A_tower_max_vol = A_2 @ A_1 * c_general['t_s']/3600
        b_tower_max_vol = c_tower['V_max'] * ones_Nc - V_0*ones_Nc + (A_2 @ d)*c_general['t_s']/3600
        
        #Concatenating constraints into a single A and b
        A = np.vstack((A_q_min , A_tower_min_vol, A_tower_max_vol))
        b = np.vstack((b_q_min , b_tower_min_vol, b_tower_max_vol))

    
    if stakeholderID==2: 
        #Pump 1
        
        J_p= define_Jp(c_pump1, A_31, J_e, h_V, d)  #Private part of cost function

        #Constraints 
        #Positive pump flow
        A_q_min = -eye_NcNq
        b_q_min = zeros_NcNq
        #Constraints max flow for the pumps, and Daily extraction limit
        A_Q_max1, b_Q_max1, A_q_max1, b_q_max1 = pump_specific_constraints(c_pump1, 1 , A_31)
        
        #Concatenating constraints into a single A and b
        A = np.vstack((A_q_min , A_Q_max1, A_q_max1))
        b = np.vstack((b_q_min , b_Q_max1, b_q_max1))

        
        
    if stakeholderID==3: 
        #Pump 2
        J_p = define_Jp(c_pump2, A_32, J_e, h_V, d) #Private part of cost function
    
        #Constraints
        #Positive pump flow
        A_q_min = -eye_NcNq
        b_q_min = zeros_NcNq
        
        #Constraints max flow for the pumps, and Daily extraction limit
        A_Q_max2, b_Q_max2, A_q_max2, b_q_max2 = pump_specific_constraints(c_pump2, 2 , A_32)
        
        #Concatenating constraints into a single A and b
        A = np.vstack((A_q_min , A_Q_max2, A_q_max2))
        b = np.vstack((b_q_min , b_Q_max2, b_q_max2))

        

        
    #Cost function for difference in tower before and after
    J_V = c_tower['kappa']/3*((c_general['t_s']*ones_Nc.T) @ (A_1 @ (Uc * c_general['hours_to_seconds'])-(d* c_general['hours_to_seconds'])))**2
    
    #Augemnt Lagrange part of cost function: 
    J_L =  Lambda.T @ (Uc - z) +rho/2 * ((Uc - z).T @ (Uc - z))

    # Defining the entire cost function
    J_k=J_L+J_V+J_p 
    return J_k, A, b 
    
def performOptimisation(time, WaterHeightmm, stakeholderID,rho,Lambda,z):  
    consumption, d, J_e = electricity_price_and_flow(time)
    J_e = np.round(J_e, 4)  #Electricity price vector
    d = np.round(d, 4)      #Predicted demand vector
    
    V_0 = np.round(WaterHeightmm/1000*c_tower['A_t'], 4)    #Volume of water in tower
    
    J_k, A, b = define_cost_func_and_constraints_ADMM(d, V_0, J_e, stakeholderID,rho,Lambda,z)
    J_k_c = casadi.Function('J_k_c', [Uc], [J_k])   #Make Casadi cost function with optimsation variables U_c

    
    opti = casadi.Opti()    #Initialise optimisation problem
    U_k = opti.variable(c_general["N_c"]*c_general['N_q'], 1)   #Define optimisation variable
    opti.minimize(J_k_c(U_k))       #Define optimisation problem
    
    opti.subject_to(A @ U_k <= b)   #Define constraints
    
    p_printing_opts = dict(print_time=False, verbose=False) #Make printing settings for Casadi
    s_printing_opts = dict(print_level=0)

    opti.solver('ipopt', p_printing_opts, s_printing_opts)  #Chose solver, set prinitng options
    
    
    solution = opti.solve()
    u_hat = solution.value(U_k)
    u_hat = np.round(u_hat, 4)
    
    return u_hat



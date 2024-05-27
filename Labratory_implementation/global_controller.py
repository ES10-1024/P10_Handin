import casadi
import numpy as np
from Get_Electricity_Flow import electricity_price_and_flow
from constants import c_general, c_tower, c_pump1, c_pump2

np.set_printoptions(threshold=np.inf)   #Print all of matrices


Uc = casadi.MX.sym('Uc', c_general['N_c']*c_general['N_q'])

def define_A_3(pump_no):

    v = np.zeros([c_general['N_q'],1])
    v[pump_no-1] = 1
    A_3 = np.kron(np.eye(c_general['N_c'],dtype=int),v.T)
    return A_3
 

A_1 = np.kron(np.eye(c_general['N_c'],dtype=int),np.ones((1, c_general['N_q'])) ) # Generate matrices needed in cost function
A_2 = np.tril(np.ones((c_general['N_c'], c_general['N_c'])))

A_31 = define_A_3(1)    #Generate matrices needed in cost function
A_32 = define_A_3(2)


ones_Nc = np.ones((c_general['N_c'], 1))    #Matrices needed for casadi
zeros_NcNq = np.zeros((c_general['N_c']*c_general['N_q'], 1))
eye_NcNq = np.eye((c_general['N_c']*c_general['N_q']))


def define_Jp(pump_constants, A_3, J_e, h_V, d):
    #Electricity bill for one pump station

    #Elevation and water height
    elevation =    ((c_tower['rho_w']*c_tower['g_0'])/c_general['condition_scaling'])*(pump_constants['h']* (A_3 @ Uc))
    water_height = ((c_tower['rho_w']*c_tower['g_0'])/c_general['condition_scaling'])*(h_V*(A_3 @ Uc))

    #Pipe resistances
    pipe_resistance = pump_constants['r_f']/c_general['condition_scaling']*(A_3 @ (Uc * casadi.fabs(Uc)*casadi.fabs(Uc)))
    combined_pipe_resistance = (A_3 @ Uc) * (c_general['r_fsigma']/c_general['condition_scaling'] * (casadi.fabs((A_1 @ Uc)-d))*((A_1 @ Uc)-d))                                                    
    
    #Power consumption
    P = 1/pump_constants['eta'] * (pipe_resistance + combined_pipe_resistance + water_height + elevation)
    
    #Return cost function
    return J_e.T @ P

def cost_functions_constraints_global_controller(d, V_0, J_e):

    q_sigma = (A_1 @ (Uc* c_general['hours_to_seconds']*c_general['t_s']))  - (d* c_general['hours_to_seconds']*c_general['t_s']) #Flow into the tower
    h_V = 1/c_tower['A_t']* (A_2 @ q_sigma + V_0)   #Height of water in the tower



    #Cost function for difference in tower before and after
    J_V = c_tower['kappa']*((c_general['t_s']*ones_Nc.T) @ (A_1 @ (Uc * c_general['hours_to_seconds'])-(d* c_general['hours_to_seconds'])))**2

    J_p_1 = define_Jp(c_pump1, A_31, J_e, h_V, d)   #Electricity bill for one pump station
    J_p_2 = define_Jp(c_pump2, A_32, J_e, h_V, d)

    J_k = J_p_1 +J_p_2 + J_V    #Cost function 

    #Constraints
    #Positive pump flow
    A_q_min = -eye_NcNq
    b_q_min = zeros_NcNq
    
    #Constraints for min and max flow for the pumps
    A_Q_max1, b_Q_max1, A_q_max1, b_q_max1 = pump_specific_constraints(c_pump1, 1 , A_31)
    A_Q_max2, b_Q_max2, A_q_max2, b_q_max2 = pump_specific_constraints(c_pump2, 2 , A_32)

    #Minimum volume in tower
    A_tower_min_vol = -A_2 @ A_1 * c_general['t_s'] / 3600
    b_tower_min_vol = - c_tower['V_min'] * ones_Nc + V_0*ones_Nc - (A_2 @ d)*c_general['t_s']/3600
    
    #Maximum volume in tower
    A_tower_max_vol = A_2 @ A_1 * c_general['t_s']/3600
    b_tower_max_vol = c_tower['V_max'] * ones_Nc - V_0*ones_Nc + (A_2 @ d)*c_general['t_s']/3600
    
    #Concatenating everything above vertically into a single A and b
    A = np.vstack((A_q_min , A_Q_max1, A_q_max1, A_Q_max2, A_q_max2, A_tower_min_vol, A_tower_max_vol))
    b = np.vstack((b_q_min , b_Q_max1, b_q_max1, b_Q_max2, b_q_max2, b_tower_min_vol, b_tower_max_vol))

    return J_k, A, b

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





def global_controller_optimisation(time, water_height):

    consumption, d, J_e = electricity_price_and_flow(time)
    J_e = np.round(J_e, 4)      #Reduce the number of decimals
    d = np.round(d, 4)
    V_0 = np.round(water_height/1000*c_tower['A_t'], 4)    #Volume of water in the tower

    J_k, A, b = cost_functions_constraints_global_controller(d, V_0, J_e)   #Define cost function and constraints
    
    J_k_c = casadi.Function('J_k_c', [Uc], [J_k])   #Turn the cost function into casadi format

    
    opti = casadi.Opti() #Initialise optimisation problem
    
    U_k = opti.variable(c_general["N_c"]*c_general['N_q'], 1) #Define optimisation variable
    opti.minimize(J_k_c(U_k))       
    opti.subject_to(A @ U_k <= b)   #Set constraints
    opti.solver('sqpmethod')

    sol = opti.solve()
    
    u_hat = sol.value(U_k)
    u_hat = np.round(u_hat, 4)
    
    print('U: ', u_hat)
    print('Sum', np.sum(u_hat))

    return u_hat


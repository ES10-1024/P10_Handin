c_pump1 = {
    "Q_min":0,                  #Minimum daily limit[m^3/day]
    "Q_max":3.6,                #TYEL [m^3/day]
    "q_min":0,                  #Minimum mass flow [m^3/h]
    "q_max":0.3,                #Maximum mass flow[m^3/h]
    "eta":0.909,                #Efficiency of pump
    "r_f":0.35*(10**5),         #Pipe resistance
    "h":2                       #Pipe elevation
}

c_pump2 = {
    "Q_min":0,                  #Minimum daily limit[m^3/day]
    "Q_max":3.6,                #TYEL [m^3/day]
    "q_min":0,                  #Minimum mass flow [m^3/h]
    "q_max":0.3,                #Maximum mass flow[m^3/h]
    "eta":0.796,                #Efficiency of pump
    "r_f":0.42*(10**5),         #Pipe resistance
    "h":1.5                     #Pipe elevation
}

c_tower = {
    "h_V_min":0.1,              #Minimum height in water tower [m]
    "h_V_max":0.55,             #Maximum height in water tower [m]
    "V_min":28/1000,            #Minimum volume of water in tower [m^3]
    "V_max":155/1000,           #Maximum volume of water in tower [m^3]
    "A_t":0.283,                #Water surface area in tower [m^2]
    "rho_w":997,                #Density of water [kg/m^3]
    "g_0":9.82,                 #Gravitational acceleration [m/s^2]
    "kappa":900                 #Volume cost
}

c_general = {
    "r_fsigma":0.29*(10**5),    #Combined pipe resistance
    "N_q":2,                    #Number of pump stations
    "N_d":1,                    #Number of consumption groups
    "N_c":24,                   #Control horizon
    "t_s": 600,                 #Sample time [s]
    "acc_time":6,               #Number of accelerated hours in one real-life hour
    "condition_scaling":10000,  #Scaling variable for conditioning
    "hours_to_seconds":1/3600   #Use when going from m^3/h to m^3/s
}

settings_pump1 = {  #Module 144
    "sampletime":1,
    "proportional_gain":6.5/2,      #6.5 in repot 
    "integral_gain":3.5,
    "initial_integral_value":50/3.5,
    "lower_saturation_limit":0,
    "upper_saturation_limit":100,
    "ip_pump":"192.168.100.42",
    "register_pump":5,
    "register_aux_pump1":8,
    "register_aux_pump2":9,
    "register_pump_tank":4,
    "ip_tower":'192.168.100.34',
    "register_tower_tank":7,
    "ip_pipe":'192.168.100.20',
    "register_flow_pipe":1,
    "pump_tank_min":100,
    "consumer_tank_max":575
}


settings_pump2 = { #Module 43
    "sampletime":1,
    "proportional_gain":16/2, #16 in report
    "integral_gain":3,
    "initial_integral_value":44/3,
    "lower_saturation_limit":0,
    "upper_saturation_limit":100,
    "ip_pump":"192.168.100.43",
    "register_pump":7,
    "register_aux_pump1":8,
    "register_aux_pump2":9,
    "register_pump_tank":4,
    "ip_tower":'192.168.100.34',
    "register_tower_tank":7,
    "ip_pipe":'192.168.100.20',
    "register_flow_pipe":2,
    "pump_tank_min":100,
    "consumer_tank_max":575
}

settings_consumer = {
    "ip_consumer":"192.168.100.32",
    "register_valve1":1,
    "register_valve2":2,
    "register_flow1":16,  
    "register_flow2":17,  
    "register_tank":7,
    "tank_min": 70,
    "tank_max": 575,
    "switching_limit":0.275 
}

import time
import socket
import numpy as np
import multiprocessing
from pyModbusTCP.client import ModbusClient
import random

from ADMM import ADMM_optimiser_WDN
from constants import c_general
from constants import settings_pump1
from low_level_control import low_level_controller
from logging import logging
from Get_Electricity_Flow import electricity_price_and_flow

use_low_level_ctrl = True
use_high_level_ctrl = True
always_simulated = False 



if __name__ == '__main__':

    log = logging("pump1")

    if(use_low_level_ctrl==True):    
        ll_reference_queue = multiprocessing.Queue(1)      #Make queue with one spot
        ll_reference_queue.put(0)                          #Set reference to zero
        low_level_control_process = multiprocessing.Process(target = low_level_controller, args = (settings_pump1, ll_reference_queue, 2,))
        low_level_control_process.start() 
        print("Low level controller started")

        MB_tower = ModbusClient(host = settings_pump1['ip_tower'], port = 502, auto_open = True)    #Connection to read water level in tower


    if(use_high_level_ctrl==True):  
        #Set up connection to tower as client 
        tower_IP = '192.168.100.32'
        tower_IP = "127.0.0.1"
        port_tower_pump1 = 5400
        s_tower = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s_tower.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)       #If port is in ues steal it
        s_tower.connect((tower_IP, port_tower_pump1))
        print("Connected to tower")

        #Set up connection to pump 2 as server
        pump1_IP = '192.168.100.144'
        pump1_IP = "127.0.0.2"
        port_pump2 = 5402
        s_pump2 = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s_pump2.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        s_pump2.bind((pump1_IP, port_pump2))
        s_pump2.listen()
        conn_pump2, addr_pump1 = s_pump2.accept()
        print("Connected to pump 2, all TCP connections setup")

        optimiser = ADMM_optimiser_WDN(s_tower, conn_pump2, 2)
        
    
    simulated_hour = 1
    current_sample_time = time.time()

    while True:
        print("Simulated hour:", simulated_hour)
        log.log("Simulated_hour", simulated_hour, 1)

        if(use_low_level_ctrl==True):
              tower_tank_level = MB_tower.read_input_registers(settings_pump1['register_tower_tank'], 1)[0]     #Read water level in tower [mm]
        else:
             tower_tank_level = 200
        log.log("tower_tank_level", tower_tank_level, 1)

        if(use_high_level_ctrl == True):
            U=optimiser.optimise(simulated_hour, tower_tank_level) #Calculated actuation
            print(U)
            log.log("Solution", U, 5)
            consumption, demand_pred, electricity_price = electricity_price_and_flow(simulated_hour)
            log.log("demand_pred", demand_pred, 5)
            log.log("electricity_price", electricity_price, 2)
            flow_pump = U.item(0)
        else:
            flow_pump = random.uniform(0,0.3)

        if(use_low_level_ctrl == True):
            ll_reference_queue.put(flow_pump)   #Send command to low level controller
        if(always_simulated == False):  
            next_sample_time = current_sample_time + c_general["t_s"]     
            sleep_time = next_sample_time - time.time()
            if sleep_time > 0:  
                time.sleep(sleep_time)
        simulated_hour = simulated_hour + 1
        current_sample_time = time.time()
        

        

     

            
            
            





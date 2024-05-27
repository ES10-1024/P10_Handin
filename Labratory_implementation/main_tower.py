import time
import socket
import numpy as np
import multiprocessing
from pyModbusTCP.client import ModbusClient
import random

from ADMM import ADMM_optimiser_WDN
from constants import c_general
from constants import settings_pump2
from logging import logging

use_low_level_ctrl = True
use_high_level_ctrl = True

always_simulated = False 

print("Halow world")
log  = logging("tower")

if(use_low_level_ctrl==True):
        MB_tower = ModbusClient(host = settings_pump2['ip_tower'], port = 502, auto_open = True)    #Connection to read water level in tower

if(use_high_level_ctrl):        
        tower_IP = '192.168.100.32'
        tower_IP = "127.0.0.1"
        port_pump1 = 5400
        port_pump2 = 5401
        s_pump1 = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s_pump1.bind((tower_IP, port_pump1))
        s_pump2= socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s_pump2.bind((tower_IP, port_pump2))
        print("Binded to both pumps")

        s_pump1.listen()
        conn_pump1, addr_pump1 = s_pump1.accept()
        print("Connected to pump 1")

        s_pump2.listen()
        conn_pump2, addr_pump2 = s_pump2.accept()
        print("Connected to pump 2, all TCP connections setup")

        optimiser = ADMM_optimiser_WDN(conn_pump1, conn_pump2, 1)


simulated_hour = 1
current_sample_time = time.time()

while True:
        print("Simulated hour:", simulated_hour)
        log.log("Simulated_hour", simulated_hour,1)
        if(use_low_level_ctrl==True):
              tower_tank_level = MB_tower.read_input_registers(settings_pump2['register_tower_tank'], 1)[0]     #Read water level in tower [mm]
              log.log("tank_tower_mm", tower_tank_level, 1)
        else:
             tower_tank_level = 200

        if(use_high_level_ctrl == True):
            U=optimiser.optimise(simulated_hour, tower_tank_level) #Calculated actuation
            print(U)
            log.log("Solution", U, 5)

        next_sample_time  = current_sample_time + c_general["t_s"]     
        sleep_time = next_sample_time - time.time()
        if (always_simulated == False): 
                if sleep_time > 0:  
                        time.sleep(sleep_time)
                else:
                        log.log("High level controller can not keep up with sampling time", 1, 1)
        simulated_hour = simulated_hour + 1
        current_sample_time = time.time()



import time
import multiprocessing
from pyModbusTCP.client import ModbusClient


from constants import settings_pump1, settings_pump2
from constants import c_general
from low_level_control import low_level_controller
from logging import logging
from global_controller import global_controller_optimisation
from Get_Electricity_Flow import electricity_price_and_flow
print("Imports finished")

if __name__ == '__main__':
    log = logging("global_control")
    print("in Main")

    ll_reference_queue1 = multiprocessing.Queue(1)      #Make queue with one spot
    ll_reference_queue1.put(0)                          #Set reference to zero
    low_level_control_process1 = multiprocessing.Process(target = low_level_controller ,args = (settings_pump1, ll_reference_queue1, 1,))
    low_level_control_process1.start() 
    print("Low level controller started")

    ll_reference_queue2 = multiprocessing.Queue(1)      #Make queue with one spot
    ll_reference_queue2.put(0)                          #Set reference to zero
    low_level_control_process2 = multiprocessing.Process(target = low_level_controller, args = (settings_pump2, ll_reference_queue2, 2,))
    low_level_control_process2.start() 
    print("Low level controller started")

    MB_tower = ModbusClient(host = settings_pump1['ip_tower'], port = 502, auto_open = True)    #Connection to read water level in tower
    

    simulated_hour = 1
    current_sample_time = time.time()

    while True:
        print("Simulated hour:", simulated_hour)
        log.log("Simulated_hour", simulated_hour, 1)

        
        tower_tank_level = MB_tower.read_input_registers(settings_pump1['register_tower_tank'], 1)[0]     #Read water level in tower [mm]
        log.log("tower_tank_level", tower_tank_level, 1)

        
        U=global_controller_optimisation(simulated_hour, tower_tank_level) #Calculated actuation
        print(U)
        log.log("Solution", U, 5)
        consumption, demand_pred, electricity_price = electricity_price_and_flow(simulated_hour)
        log.log("demand_pred", demand_pred, 5)
        log.log("electricity_price", electricity_price, 2)
        
        ll_reference_queue1.put(U.item(0))   #Send command to low level controller
        ll_reference_queue2.put(U.item(1))   #Send command to low level controller

        next_sample_time  = current_sample_time + c_general["t_s"]     
        sleep_time = next_sample_time - time.time()
        if sleep_time > 0:  
            time.sleep(sleep_time)
        simulated_hour = simulated_hour + 1
        current_sample_time = time.time()


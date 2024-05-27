from pyModbusTCP.client import ModbusClient
from constants import settings_consumer, settings_pump1, settings_pump2
from low_level_control import consumer_valve_controller
from logging import logging
import time
import scipy.io
from constants import c_general
from math import floor as math_floor
import numpy




MB_tower = ModbusClient(host = settings_pump2['ip_tower'], port = 502, auto_open = True)    #Connection to read water level in tower
MB_pump1 = ModbusClient(host = settings_pump1['ip_pump'], port = 502, auto_open=True)
MB_pump2 = ModbusClient(host = settings_pump2['ip_pump'], port = 502, auto_open=True)
MB_cons = ModbusClient(host= settings_consumer['ip_consumer'], port= 502, auto_open= True)

valve1_ctrl = consumer_valve_controller(settings_consumer['register_flow1'], 1) 
valve2_ctrl = consumer_valve_controller(settings_consumer['register_flow2'], 2) 

demand_temp = scipy.io.loadmat('High_level/Data/average_scaled_consumption.mat')
demand_vector = demand_temp['average_scaled_consumption']



tank_pump_max = 530 #[mm]
tank_tower_min = 75
tank_consumer_min = 75
tank_consumer_max = 570
tank_pump_ref = 380
aux_pump_switch_time = 60 # [s]
last_turn_on_time = time.time()

last_sample_time = time.time()
start_time = time.time()
log  = logging("return_and_consumer_valve_ctrl")

try:
    while True: 
        #Perform return water control
        tank_consumer = MB_cons.read_input_registers(settings_consumer['register_tank'], 1)[0]
        tank_pump1 = MB_pump1.read_input_registers(settings_pump1['register_pump_tank'], 1)[0]
        tank_pump2 = MB_pump2.read_input_registers(settings_pump2['register_pump_tank'], 1)[0]
        tank_tower = MB_tower.read_input_registers(settings_pump1['register_tower_tank'], 1)[0]
        log.log("tank_consumer_mm", tank_consumer, 1)
        log.log("tank_pump1_mm", tank_pump1, 1)
        log.log("tank_pump2_mm", tank_pump2, 1)
        log.log("tank_tower_mm", tank_tower, 1)

        MB_cons.write_single_register(3, 10000)    #Open bottom valve
        MB_tower.write_single_register(3, 10000)   #Open bottom valve


        if(tank_consumer > tank_consumer_max):           #Set both aux pumps max power
            MB_pump1.write_single_register(8, 100*100)
            MB_pump1.write_single_register(9, 100*100)
            MB_pump2.write_single_register(8, 100*100)
            MB_pump2.write_single_register(9, 100*100)
            print("Consumer overfull")
            
        elif(tank_consumer < tank_consumer_min):        #Turn off both aux pumps
            MB_pump1.write_single_register(8, 0)
            MB_pump1.write_single_register(9, 0)
            MB_pump2.write_single_register(8, 0)
            MB_pump2.write_single_register(9, 0)
            print("Consumer empty")

        elif( tank_pump1 > tank_pump_max and tank_pump2 > tank_pump_max):
            MB_pump1.write_single_register(8, 0)
            MB_pump1.write_single_register(9, 0)
            MB_pump2.write_single_register(8, 0)
            MB_pump2.write_single_register(9, 0)
            print("Pump stations overfull")
            #Bad but sufficient check. If one is overfull the flow is not stopped, before next switch time. Saved by safety level control on the modules

        elif( tank_pump1 < tank_pump_ref or tank_pump2 < tank_pump_ref):
            if(time.time() > last_turn_on_time + aux_pump_switch_time):     #If below reference and long time since settings change
                last_turn_on_time= time.time()
                if(tank_pump1 < tank_pump2):
                    MB_pump1.write_single_register(8, 100*100)
                    MB_pump1.write_single_register(9, 100*100)
                    MB_pump2.write_single_register(8, 0)
                    MB_pump2.write_single_register(9, 0)
                    print("Return water to pump 1")
                else:                                        
                    MB_pump1.write_single_register(8, int(0))
                    MB_pump1.write_single_register(9, 0)
                    MB_pump2.write_single_register(8, 100*100)
                    MB_pump2.write_single_register(9, 100*100)
                    print("Return water to pump 2")

        #PID controller for consumer unit

        simulated_hour = math_floor( (time.time() - start_time) / c_general['t_s'] ) + 1 #simulated_hour is 1 indexed per definition 
        print("Simulated hour:", simulated_hour)
        log.log("Simulated_hour", simulated_hour, 1)

        demand_ref = demand_vector.item(simulated_hour)
        log.log("Demand",demand_ref, 5)
        
        flow_valve1 = 0.06/100*MB_cons.read_input_registers(settings_consumer['register_flow1'], 1)[0]
        flow_valve2 = 0.06/100*MB_cons.read_input_registers(settings_consumer['register_flow2'], 1)[0]
        log.log("Flow_valve1", flow_valve1, 5)
        log.log("Flow_valve2", flow_valve2, 5)

        #Safety control, close valves if the consumer is too full or the tower too empty. Otherwise, initiate control
        if(tank_consumer > settings_consumer['tank_max'] or tank_tower < tank_tower_min):
            MB_cons.write_single_register(settings_consumer['register_valve1'], 0)     
            MB_cons.write_single_register(settings_consumer['register_valve2'], 0)     
            print("Safety level control (valve controller) active")
        else:
            #Determine whether one or two valves should be operating based on a switching limit
            if(demand_ref > settings_consumer['switching_limit']):
                OD_valve1 = valve1_ctrl.consumption_PI(demand_ref/2, flow_valve1)
                OD_valve2 = valve2_ctrl.consumption_PI(demand_ref/2, flow_valve2)
            else:
                OD_valve1 = valve1_ctrl.consumption_PI(demand_ref, flow_valve1)
                OD_valve2 = valve2_ctrl.consumption_PI(0, flow_valve2)          
            #Write to the registers
            MB_cons.write_single_register(settings_consumer['register_valve1'], int(100*OD_valve1))
            MB_cons.write_single_register(settings_consumer['register_valve2'], int(100*OD_valve2))

        time.sleep(1)

except Exception as error:
    MB_pump1.write_single_register(8, 0)   #Turn off pumps
    MB_pump1.write_single_register(9, 0)
    MB_pump2.write_single_register(8, 0)
    MB_pump2.write_single_register(9, 0)

    MB_cons.write_single_register(3, 0)    #Close bottom valve 
    MB_tower.write_single_register(3, 0)   #Close bottom valve 
  
    MB_cons.write_single_register(1, 0)    #Open top valve
    MB_cons.write_single_register(2, 0)    #Open top valve

    print("Pumps turned off and valves closed due to exception")

    print(error)
    print(type(error).__name__)

except: 
    MB_pump1.write_single_register(8, 0)   #Turn off pumps
    MB_pump1.write_single_register(9, 0)
    MB_pump2.write_single_register(8, 0)
    MB_pump2.write_single_register(9, 0)

    MB_cons.write_single_register(3, 0)    #Close bottom valve 
    MB_tower.write_single_register(3, 0)   #Close bottom valve 
  
    MB_cons.write_single_register(1, 0)    #Open top valve
    MB_cons.write_single_register(2, 0)    #Open top valve

    print("Pumps turned off and valves closed due to exception")




























        

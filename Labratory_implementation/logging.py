
import csv 
import os 
from datetime import datetime
import numpy as np
import time 

class logging: 
    def __init__(self, filename):  
        #Getting timestamp for the filename
        timestamp = datetime.now().strftime("%m-%d_%H-%M-%S")
        self.filename = f"Logging/Log_files/{filename}_{timestamp}.csv"
        self.header = ['ID','Data','Time']  # Use the passed header value
        self.init_time = 1714561011         # To make time stamp values smaller

        # Check if the file exists, if not, create it
        if not os.path.exists(self.filename):
            with open(self.filename, 'w', newline='') as csv_file:
                if self.header:
                    csv_writer = csv.writer(csv_file)
                    csv_writer.writerow(self.header)
                    csv_writer.writerow([])
                    
    # Writing data to the log file              
    def log(self, ID, data, n_decimals):
         data=[ID, np.round(data, n_decimals), np.round(time.time()-self.init_time,3)]
        
         with open(self.filename, 'a', newline='') as csv_file:
            csv_writer = csv.writer(csv_file)
            csv_writer.writerow(data)
         

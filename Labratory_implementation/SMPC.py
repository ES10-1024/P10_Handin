import numpy as np
import random

class SSSS: 
    def __init__(self, conn1, conn2, stakeholder_id: int,log ):
        self.conn1 = conn1      #TCP connection
        self.conn2 = conn2      #TCP connection
        self.log = log 
        self.offset = 5         #Offset to avoid negative values, see report
        self.scaling = 10000    #Scaling such rounding becomes insignificant
        self.Beta = int (4294967029) # Prime number used for SSSS    
        self.N_s = 3            #Number of stakeholders
        self.stakeholder_id = stakeholder_id 
    
    #Generating shares based on secret. Secret is at first casted to finite field. Support for vector and scalar inputs
    def get_shares(self, secret): 
        
        n_rows = secret.shape[0]     #Number of rows in secret
        b = np.zeros((3, n_rows))    #Preallocating matrix for the shares
         
        for row in range(n_rows):        #Looping over rows in secret
            scaledOffset = int( np.round(self.scaling * (secret[row] + self.offset)))        #Cast to finite field
            
            a1 = random.randint(0, self.Beta - 1)   #Chose random coefficients for polynomial 
            a2 = random.randint(0, self.Beta - 1)
            
            for x in range(1,4):
                b[x-1, row]= (scaledOffset + a1*x + a2*x**2) % self.Beta  #Calculate shares for the chosen b_i(x), % is modulo

        return b  #Return the share matrix
    
    #Calculate sum based on the summed shares
    def get_sum(self, summed_shares): 
        n_rows = summed_shares.shape[1]     #Number of rows in secret/sum vector 
        sum = np.zeros((n_rows, 1))         #Preallocating vector for the sum
        delta = np.array([3, -3, 1])          #Recombination vector, predefined based on the chosen x values

        for row in range(n_rows):           #Loop over the rows in the sum
            sum[row] = (delta @ summed_shares[:,row]) % self.Beta        #Calculate entry in sum @ is matrix product, % is modulo
            sum[row] = (sum[row]-(self.offset*self.N_s*self.scaling))/self.scaling    #Cast back into float
        return sum
    
    #Make calculation of sum. Function includes networking
    def sum(self,secret): 
        if not isinstance(secret, np.ndarray):
            secret = np.array([secret])
        shares = self.get_shares(secret)

        if self.stakeholder_id==1:  #Water tower ID 1
            b1x1 = shares[0,:]   #Pick share vectors
            b1x2 = shares[1,:]
            b1x3 = shares[2,:]

            self.conn1.sendall(b1x2.tobytes())  #Distribute share vectors to the rest of the stakeholders: 
            self.conn2.sendall(b1x3.tobytes())
            
            b2x1 = np.frombuffer(self.conn1.recv(8*secret.shape[0]), dtype=b1x1.dtype) #Receiving share vectors the others: 
            b3x1 = np.frombuffer(self.conn2.recv(8*secret.shape[0]), dtype=b1x1.dtype)
            
            b1x1 = b1x1.reshape(-1, 1)  #Reshape to on column unknown number of entries
            b2x1 = b2x1.reshape(-1, 1)
            b3x1 = b3x1.reshape(-1, 1)
            
            b1 = (b1x1 + b2x1 + b3x1) % self.Beta   #Sum the received shares
            
            self.conn1.sendall(b1.tobytes())  #Distribute sum of shares
            self.conn2.sendall(b1.tobytes())
            
            b2 = np.frombuffer(self.conn1.recv(8*secret.shape[0]), dtype=b1.dtype) #Recive sum of shares
            b3 = np.frombuffer(self.conn2.recv(8*secret.shape[0]), dtype=b1.dtype)
            
            b1= b1.reshape(-1, 1)  
            b2= b2.reshape(-1, 1)
            b3= b3.reshape(-1, 1)
             
        if self.stakeholder_id==2: # pump 1 ID 2 
            b2x1 = shares[0, :]
            b2x2 = shares[1, :]
            b2x3 = shares[2, :]
            
            self.conn1.sendall(b2x1.tobytes())  
            self.conn2.sendall(b2x3.tobytes())
            
            b1x2 = np.frombuffer(self.conn1.recv(8*secret.shape[0]), dtype=b2x1.dtype) 
            b3x2 = np.frombuffer(self.conn2.recv(8*secret.shape[0]), dtype=b2x1.dtype)
            
            b1x2 = b1x2.reshape(-1, 1)
            b2x2 = b2x2.reshape(-1, 1)
            b3x2 = b3x2.reshape(-1, 1)
            
            b2 = (b1x2 + b2x2 + b3x2) % self.Beta
            
            self.conn1.sendall(b2.tobytes())  
            self.conn2.sendall(b2.tobytes())
            
            b1 = np.frombuffer(self.conn1.recv(8*secret.shape[0]), dtype=b2.dtype)
            b3 = np.frombuffer(self.conn2.recv(8*secret.shape[0]), dtype=b2.dtype)
            
            b1 = b1.reshape(-1, 1)
            b2 = b2.reshape(-1, 1)
            b3 = b3.reshape(-1, 1)
             
        if self.stakeholder_id==3: # pump 2 ID 3     
            b3x1 = shares[0, :]
            b3x2 = shares[1, :]
            b3x3 = shares[2, :]
        
            self.conn1.sendall(b3x1.tobytes())  
            self.conn2.sendall(b3x2.tobytes())
        
            b1x3 = np.frombuffer(self.conn1.recv(8*secret.shape[0]), dtype=b3x1.dtype) 
            b2x3 = np.frombuffer(self.conn2.recv(8*secret.shape[0]), dtype=b3x1.dtype)
        
            b1x3 = b1x3.reshape(-1, 1)
            b2x3 = b2x3.reshape(-1, 1)
            b3x3 = b3x3.reshape(-1, 1)

            b3 = (b1x3 + b2x3 + b3x3 ) % self.Beta

            self.conn1.sendall(b3.tobytes())  
            self.conn2.sendall(b3.tobytes())
        
            b1 = np.frombuffer(self.conn1.recv(8*secret.shape[0]), dtype=b3.dtype) # Receive other z_i's
            b2 = np.frombuffer(self.conn2.recv(8*secret.shape[0]), dtype=b3.dtype)
        
            b1 = b1.reshape(-1, 1)
            b2 = b2.reshape(-1, 1)
            b3 = b3.reshape(-1, 1)

        
        summed_share_matrix = np.vstack((b1.T,b2.T,b3.T))   #Make matrix of the received sum of shares
        sum = self.get_sum(summed_share_matrix)             #Calculate sum based on shares 
        
        return  sum
    
    
            
            
            
                    
        
# Example usage
#ssss = SSSS()
#secret = np.ones((48, 1))
    
#result1 = ssss.generatedOutFromFunction(secret*2)
#result2 = ssss.generatedOutFromFunction(secret*5)
#result3 = ssss.generatedOutFromFunction(secret*1)

#summed=result1+result2+result3 

#result=ssss.getSecret(summed)

#print(result)

            
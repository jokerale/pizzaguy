# This program does a single execution of the solver with some random data.
# Get as parameters:
#  - N: number of order
#  - city: one of Visano, Casaloldo, Asola, Brescia, Roma
#  - timeout (in second)
#  - d: numbr of deliverers

# The orders (destination, number of pizzas and requested time) are randomly generated.

# TO-DO:
#  - check if number of nodes calculation (with number of lines) is good or not.
#  - refactorize all
#  - generate images for deliverer path (controlled by user-option)



import sys
import argparse
import seaborn as sb
import os
import time
import networkx as nx
import matplotlib.pyplot as plt
import pandas as pd
import numpy as np
import osmnx as ox

##### FUNCTIONS DEFINITIONS #####

def ordersGeneretor(orari_possibili, n_pizze_max, n_nodi, n_ordini):
    orari = np.random.choice(orari_possibili, size=n_ordini)
    #num_pizze = np.random.randint(1, n_pizze_max+1, size=n_ordini)
    xx = np.random.gamma(2,2, size=n_ordini)
    num_pizze = np.zeros(n_ordini, dtype=int)
    for i in range(n_ordini):
        num_pizze[i] = int(np.ceil(xx[i]))
        if num_pizze[i] > 16:
            num_pizze[i] = 16
            
    dest = np.random.randint(2, n_nodi+1, size=n_ordini)
    
    return orari, num_pizze, dest

def dataStringGenerator(df, nome_variabile):
    stringa = nome_variabile +" = [";
    ## sezione per la matrice delle distanze
    if df.shape[0] == df.shape[1]:
        for i in range(df.shape[0]):
            if i == 0:
                stringa = stringa + "| "
            else:
                stringa = stringa + "         | "
            for j in range(df.shape[1]):
                stringa = stringa + str(df.iat[i, j]) 
                if j != len(df)-1:
                    stringa = stringa + ", "
                else:
                    stringa = stringa +  os.linesep # aggiunta di \n a fine della riga 

        stringa = stringa + "         |];"
    # sezione per i semplici array di numeri
    else:
        for i in range(df.shape[0]):
            if i != df.shape[0]-1:
                stringa = stringa + str(df.iat[i,0]) + ", "
            else:
                stringa = stringa + str(df.iat[i,0])
        
        stringa = stringa + "];"
    
    return stringa

##### ARGUMENTS #####

parser = argparse.ArgumentParser(description="Descrizione")

parser.add_argument("-c", "--city", nargs=1, required=True, help="city to use")
parser.add_argument("-t", "--timeout", nargs=1, type=int, required=True, help="max time for Minizinc execution (in seconds)")
parser.add_argument("-N", "--Norders", nargs=1, type=int, required=True, help="number of orders")
parser.add_argument("-d", "--deliverers", nargs=1, type=int, required=True, help="number of deliverers")
parser.add_argument('--plot-map', dest='plot', action='store_true', help='generate and save figure of map with paths')
#parser.add_argument("-p", "--place", nargs=1, required=True, help="città da cui prendere la mappa \n(formato: città, provincia, nazione)")

input_var = parser.parse_args()



##### MAIN PROGRAM #####

filename = 'data/' + str(input_var.city[0]) + '_graph.xml'
filename_dij = 'data/' + str(input_var.city[0]) + '_dijkstra.dzn'
timelimit = input_var.timeout[0]*1000
N = input_var.Norders[0]
d = input_var.deliverers[0]
plot = input_var.plot

# Needed for images generation (in the future)
g = ox.load_graphml(filepath=filename)

# Get number of nodes
with open(filename_dij, 'r') as fp:
    for count, line in enumerate(fp):
        pass
k = count

# Random generator
orari_possibili = ["19.00", "19.15", "19.30", "19.45", "20.00", "20.15", "20.30", "20.45", "21.00", "21.15", "21.30"]
orari, pizze, nodi = ordersGeneretor(orari_possibili, 16, k, N)

dfOrari = pd.DataFrame(orari)
dfPizze = pd.DataFrame(pizze)
dfNodi = pd.DataFrame(nodi)

stringaOrari = dataStringGenerator(dfOrari, "orario")
stringaPizze = dataStringGenerator(dfPizze, "num_pizze")
stringaNodi = dataStringGenerator(dfNodi, "dest")

# push random data on a temporary file
file = open('data/temp-order.dzn', 'w')
file.write(stringaOrari + os.linesep 
           + stringaPizze + os.linesep 
           + stringaNodi+ os.linesep
           + "N = " + str(N) + ";" + os.linesep
           + "k = " + str(k) + ";" + os.linesep
           + "d = " + str(d) + ";" + os.linesep)
file.close()


# command to execute
cmd = 'minizinc --solver Gecode --time-limit ' + str(timelimit) + ' v01.mzn ' + filename_dij + ' data/temp-order.dzn'  


print('Grafo (' + filename + '): ' + str(g is not None))
print('Timeout: ' + str(timelimit))
print("N = " + str(N) + "\nk = " + str(k) +"\nd = " + str(d))
print('orari: ' + str(stringaOrari))
print('pizze: ' + str(stringaPizze))
print('destin: ' + str(stringaNodi))
print('Executing: ' + cmd)


start = time.perf_counter()
out = os.popen(cmd).read()
end = time.perf_counter()

t = end-start 
print("TIME: " + str(t))

print('OUT:')
print(out)
f1 = open('out.txt','w')
f1.write(out)
f1.close()
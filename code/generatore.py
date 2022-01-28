import networkx as nx
import matplotlib.pyplot as plt
import pandas as pd
import numpy as np
import os
from itertools import combinations
import random
import sys
import argparse
import osmnx as ox

#### FUNZIONI DI SUPPORTO ####
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
############ USER INTERFACE ############
parser = argparse.ArgumentParser(description="Generatore di input per il solver Minizinc.")

parser.add_argument("-d", "--deliverers", nargs=1, type=int, required=True, help="numero di deliverers")
parser.add_argument("-N", "--ordini", nargs=1, type=int, required=True, help="numero di ordini totali")
parser.add_argument("-p", "--place", nargs=1, required=True, help="città da cui prendere la mappa \n(formato: città, provincia, nazione)")

input_var = parser.parse_args()
#print(input_var)
############ GENERATORE ############
#place_name = "Casaloldo, Mantova, Italy"

# dowload del grafico
graph = ox.graph_from_place(input_var.place, network_type="drive")
# conversione delle etichette con numeri consecutivi partendo da 1
gg = nx.convert_node_labels_to_integers(graph)
# conversione ad un grafo indiretto
dGraph = gg.to_undirected()
#fig, ax = ox.plot_graph(dGraph, node_size=2)

# calcolo della minore distanza tra tutte le coppie di nodi
# --> la matrice sarà simmetrica perchè il grafo è indiretto
labels2 = nx.get_edge_attributes(dGraph, 'length')
dictDist2 = dict(nx.all_pairs_dijkstra_path_length(dGraph))
mDist2 = pd.DataFrame(dictDist2)
mDistSorted2 = mDist2.sort_index()

orari_possibili = ["19.00", "19.15", "19.30", "19.45", "20.00", "20.15", "20.30", "20.45", "21.00", "21.15", "21.30"]
# np.random.randint(1,17) --> generatore di numeri tra [1,16] aka generatore di numero di pizze
# np.random.randint(2,len(mDistSorted2)+1) aka generatore di destinazioni
#orario
#num_pizze
#dest

#deliverers = 3
N = 4
orari, pizze, nodi = ordersGeneretor(orari_possibili, 16, mDistSorted2.shape[0], N)
dfOrari = pd.DataFrame(orari)
dfPizze = pd.DataFrame(pizze)
dfNodi = pd.DataFrame(nodi)


stringa = dataStringGenerator(pd.DataFrame(mDistSorted2/18,dtype=int), "mdist")
stringaOrari = dataStringGenerator(dfOrari, "orario")
stringaPizze = dataStringGenerator(dfPizze, "num_pizze")
stringaNodi = dataStringGenerator(dfNodi, "dest")

file = open('data.dzn', 'w')
file.write(stringa + os.linesep 
           + stringaOrari + os.linesep 
           + stringaPizze + os.linesep 
           + stringaNodi+ os.linesep
           + "N = " + str(input_var.ordini) + ";" + os.linesep
           + "k = " + str(mDistSorted2.shape[0]) + ";" + os.linesep
           + "d = " + str(input_var.deliverers) + ";" + os.linesep)
file.close()
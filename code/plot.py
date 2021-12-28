import networkx as nx
import matplotlib.pyplot as plt

g = nx.Graph()

g.add_edge(1,2)
g.add_edge(1,3)
g.add_edge(2,3)

nx.draw(g, with_labels = True)
plt.savefig("prova.png")
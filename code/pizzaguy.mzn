% The pizza guy
include "globals.mzn";

% general informations
int: g = 1; % number of deliverers available
int: capacity = 16; % max number of pizzas in one travel
int: delivery_window = 30; % number of minutes beyond the decided delivery time

int: k = 9;  % number of nodes
int: E = 18; % number of edges
int: N = 3;  % number of orders

% description of the graph
array[1..E] of int: from; % array of the beginning of the edges
array[1..E] of int: to;   % array of the ending of the edges
array[1..E] of int: w;    % array fo weights of the edges

% description of the orders
array[1..N] of int: num_pizze; % array describing the number of pizzas for every order 
array[1..N] of int: orario;    % the decided time of the orders
array[1..N] of int: dest;      % the node where to deliver

%array[1..num_nodes,1..num_nodes] of int: travel_time;

array[1..k] of var bool: ns;
array[1..E] of var bool: es;

constraint path(k, E, from, to, 1, dest[1], ns, es);
%%%%

%array[int] of var bool: ns;
%array[int] of var bool: es;
%predicate path(num_nodes, num_nodes*num_nodes, travel_time, travel_time, 1, 5, ns, es);
%array[1..num_nodes*num_nodes] of var int: path;
%predicate find_path()



solve satisfy;

output [show(ns) ++ "\n" ++ show(es) ];


%% toy example

from = [1,1,1,6,5,3,2,2,7,4,10,3,9,3,8,2,8,12];
to   = [4,7,6,5,12,4,3,7,13,11,11,10,10,9,9,8,13,13];
w    = [3,2,1,6,4,9,2,5,7,6,4,1,2,3,2,6,3,3];
orario = [19,19,19];
num_pizze = [7,5,9];
dest = [9,11,5];
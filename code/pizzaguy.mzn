% The pizza guy
include "globals.mzn";

% general informations
int: g; % number of deliverers available
int: capacity = 16; % max number of pizzas in one travel
int: delivery_window = 30; % number of minutes beyond the decided delivery time

int: k;  % number of nodes
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
array[1..N] of var bool: es;

predicate path(k1, E, from, to, 1, dest[1], ns, es);
%%%%

%array[int] of var bool: ns;
%array[int] of var bool: es;
%predicate path(num_nodes, num_nodes*num_nodes, travel_time, travel_time, 1, 5, ns, es);
%array[1..num_nodes*num_nodes] of var int: path;
%predicate find_path()



solve satisfy;



%% toy example

from = [1,1,1,6,5,3,2,2,7,4,10,3,9,3,8,2,8,12];
to   = [4,7,6,5,12,4,3,7,13,11,11,10,10,9,9,8,13,13];
w    = [3,2,1,6,4,9,2,5,7,6,4,1,2,3,2,6,3,3];
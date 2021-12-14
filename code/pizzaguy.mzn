% The pizza guy
include "globals.mzn";

int: g; % number of deliverers available
int: capacity = 16; % max number of pizzas in one travel
int: delivery_window = 30; % number of minutes beyond the decided delivery time

int: num_nodes = 9; % number of nodes in the graph

array[1..num_nodes,1..num_nodes] of int: travel_time;


%%%%


% first stupid example
g = 2;

%array[int] of var bool: ns;
%array[int] of var bool: es;
%predicate path(num_nodes, num_nodes*num_nodes, travel_time, travel_time, 1, 5, ns, es);


array[1..num_nodes*num_nodes] of var int: path;

predicate find_path()
solve satisfy;



%% toy example
travel_time = 
[| 0,  2,  1, -1,  2,  2,  1,  5,  6,
 | 2,  0,  3,  7,  6, -1,  6,  7,  1,
 | 1,  3,  0,  4,  4,  8,  2,  9,  2,
 |-1,  7,  4,  0,  9,  6, -1,  1,  7,
 | 2,  6,  4,  9,  0,  5,  1,  2,  5,
 | 2, -1,  8,  6,  5,  0,  5,  8, -1,
 | 1,  6,  2, -1,  1,  5,  0,  4,  3,
 | 5,  6,  9,  1,  2,  8,  4,  0,  13,
 | 6,  1,  2,  7,  5, -1,  3,  13,  0,
 |];

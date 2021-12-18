% The pizza guy
include "globals.mzn";

% general informations
int: g = 2;                 % number of deliverers available
int: capacity = 16;         % max number of pizzas in one travel for each deliver
int: delivery_window = 30;  % number of minutes beyond the decided delivery time  

% description of the graph
array[1..E] of int: from; % array of the beginning of the edges
array[1..E] of int: to;   % array of the ending of the edges
array[1..E] of int: w;    % array fo weights of the edges

% description of the orders
array[1..N] of int: num_pizze; % array describing the number of pizzas for every order 
array[1..N] of int: orario;    % the decided time of the orders
array[1..N] of int: dest;      % the node where to deliver

%array[1..num_nodes,1..num_nodes] of int: travel_time;

%array[1..k] of var bool: ns;
array[1..k] of var bool: ns1;
array[1..k] of var bool: ns2;
array[1..k] of var bool: ns3;
array[1..k] of var bool: ns4;
%array[1..E,1..N] of var bool: es;
array[1..E] of var bool: es1;
array[1..E] of var bool: es2;
array[1..E] of var bool: es3;
array[1..E] of var bool: es4;

array[1..g] of var set of 1..N: orders_of_the_deliverer; % set of all the orders assigned to a deliverer
array[1..N] of var int:  arrival_time;                   % array of all the arrival times of the assigned orders
array[1..N] of var int: departure_time;                  % array of all the departure times of the assigned orders
array[1..1000] of var int: path;                         % array that specifies all the nodes in the path of all the work day

array[1..N+1] of var int: peso_totale;

% vincolo ordini univoci tra deliverer
constraint all_disjoint(orders_of_the_deliverer);
constraint partition_set(orders_of_the_deliverer, 1..N);
%%% forzare un deliverer ad eseguire una consegna
%constraint orders_of_the_deliverer[1] = {1};

% vincoli sui percorsi
constraint bounded_path(k, E, from, to, w,       1, dest[1], ns1, es1, peso_totale[1]);
constraint bounded_path(k, E, from, to, w, dest[1], dest[2], ns2, es2, peso_totale[2]);
constraint bounded_path(k, E, from, to, w, dest[2], dest[3], ns3, es3, peso_totale[3]);
constraint bounded_path(k, E, from, to, w, dest[3],       1, ns4, es4, peso_totale[4]);


%constraint path(k, E, from, to, 3,1, ns, es);
% constraint forall(i in 1..N)(
%   bounded_path(k,E, from, to, w, dest[i],dest[i+1],ns[i], es[i], peso_totale[i])
%   );
% %constraint bounded_path(k, E, from, to, w, 1, 3, ns, es, peso_totale[1]);
%%%%

%array[int] of var bool: ns;
%array[int] of var bool: es;
%predicate path(num_nodes, num_nodes*num_nodes, travel_time, travel_time, 1, 5, ns, es);
%array[1..num_nodes*num_nodes] of var int: path;
%%%%%predicate find_path()
var int: somma_peso_totale = sum(peso_totale);

solve minimize somma_peso_totale;

% output [ show(ns1) ++ "\n" ++ show(es1) ++ "\n" ++
%          show(ns2) ++ "\n" ++ show(es2) ++ "\n" ++
%          show(ns3) ++ "\n" ++ show(es3) ++ "\n" ++
%          show(ns4) ++ "\n" ++ show(es4) ++ "\n" ++
%          "\n peso totale: " ++ show(somma_peso_totale)];

%%% STAMPA ARCHI DA NODO A NODO
% output [ if fix(es1[i] == true) then show(from[i]) ++ "->" ++ show(to[i]) ++ " " else "" endif | i in 1..E ] ++ ["\n" ] ++
%        [ if fix(es2[i] == true) then show(from[i]) ++ "->" ++ show(to[i]) ++ " " else "" endif | i in 1..E ] ++ ["\n" ] ++
%        [ if fix(es3[i] == true) then show(from[i]) ++ "->" ++ show(to[i]) ++ " " else "" endif | i in 1..E ] ++ ["\n" ] ++ 
%        [ if fix(es4[i] == true) then show(from[i]) ++ "->" ++ show(to[i]) ++ " " else "" endif | i in 1..E ] ++ ["\n" ] ++
%        ["\n peso totale: " ++ show(somma_peso_totale)];

%%% STAMPA DEI NODI VISITATI NEI PERCORSI
output [ if fix(ns1[i] == true) then show(i) ++" " else "" endif | i in 1..k ] ++ ["\n" ] ++
       [ if fix(ns2[i] == true) then show(i) ++" " else "" endif | i in 1..k ] ++ ["\n" ] ++
       [ if fix(ns3[i] == true) then show(i) ++" " else "" endif | i in 1..k ] ++ ["\n" ] ++
       [ if fix(ns4[i] == true) then show(i) ++" " else "" endif | i in 1..k ] ++ ["\n" ] ++
       ["\n peso totale: " ++ show(somma_peso_totale)];

%%% STAMPA DELLA SOMMA DEI PESI DEGLI ARCHI NEI PERCORSI
%output ["\n peso totale" ++ show(somma_peso_totale)];
output ["\n"++show(orders_of_the_deliverer[i])| i in 1..g];

%% toy example
%%% graph #1
int: k = 13;
int: E = 18;
from = [1, 1, 1, 6,  5, 3, 2, 2,  7,  4, 10,  3,  9, 3, 8, 2,  8, 12];
to   = [4, 7, 6, 5, 12, 4, 3, 7, 13, 11, 11, 10, 10, 9, 9, 8, 13, 13];
w    = [3, 2, 1, 6,  4, 9, 2, 5,  7,  6,  4,  1,  2, 3, 2, 6,  3,  3];

%%% orders #1
int: N = 3;
orario =    [19, 19, 19];
num_pizze = [7,   5,  9];
dest =      [9,  11,  5];
% int: k = 4;
% int: E = 5;
% from = [1,2,3,4,1];
% to   = [2,3,4,1,3];
% w    = [1,1,1,1,5];


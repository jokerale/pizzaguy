include "globals.mzn";

%% -- Graph

int: k = 13;
int: E = 18;

array[1..E] of int: from; % array of the beginning of the edges
array[1..E] of int: to;   % array of the ending of the edges
array[1..E] of int: w;    % array fo weights of the edges

from = [1, 1, 1, 6,  5, 3, 2, 2,  7,  4, 10,  3,  9, 3, 8, 2,  8, 12];
to   = [4, 7, 6, 5, 12, 4, 3, 7, 13, 11, 11, 10, 10, 9, 9, 8, 13, 13];
w    = [3, 2, 1, 6,  4, 9, 2, 5,  7,  6,  4,  1,  2, 3, 2, 6,  3,  3];


%% -- Orders

int: N = 4;
array[1..N] of int: num_pizze; % array describing the number of pizzas for every order 
array[1..N] of int: orario;    % the decided time of the orders
array[1..N] of int: dest;      % the node where to deliver
orario =    [19, 19, 19, 20];
num_pizze = [7,   5,  9, 10];
dest =      [9,  11,  5, 8 ];


%% -- Delivers

% Each array contains the orders (ids) that deliver (1, 2 or 3) has to do.  
%set of int: d1;
var set of 1..N: d1;
var set of 1..N: d2;
var set of 1..N: d3;

% Each array contains the path that deliver (1, 2 or 3) has to do.  
%array[1..k*N] of int: pd1;
%array[1..k*N] of int: pd2;
%array[1..k*N] of int: pd3;


%% -- Contraints

% All the order must be assigned -- maybe not needed ? 
constraint (d1 union d2 union d3) = 1..N;
% .. to only one deliver
constraint all_disjoint([d1,d2,d3]);



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

array[1..N+1] of var int: peso_totale;


% Does not work! --> unsat
% The idea is: for each delivers, must have a path from 1 to 1 (start from the pizzeria and get back) that also reachs every node assigned to the deliver. 


constraint bounded_path(k, E, from, to, w, 1, 1, ns1, es1, peso_totale[1]);
constraint forall(i in d1)( ns1[dest[i]] = true );
 constraint bounded_path(k, E, from, to, w, 1, 1, ns2, es2, peso_totale[2]);
 constraint forall(i in d2)( ns2[dest[i]] = true );
 constraint bounded_path(k, E, from, to, w, 1, 1, ns3, es3, peso_totale[3]);
 constraint forall(i in d3)( ns3[dest[i]] = true );

var int: somma_peso_totale = sum(peso_totale);

solve satisfy;
%solve minimize somma_peso_totale;



output 
      ["d1: "] ++ [ show(dest[i]) ++ "  " | i in fix(d1) ] ++ ["\n"] ++
      ["d2: "] ++ [ show(dest[i]) ++ "  " | i in fix(d2) ] ++ ["\n"] ++
      ["d3: "] ++ [ show(dest[i]) ++ "  " | i in fix(d3) ]

        %[i | i in d1] ++ ["\n"] ++
        %[show(d2)] ++ ["\n"] ++
        %[show(d3)]
        
        ;



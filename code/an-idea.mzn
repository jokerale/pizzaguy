% WITHOUT any constraint on maximum number of pizzas in the deliver and also on the time of delivery.
% Dummy node (for pizzeria) added to let bounded_path working.
% I'm not able to specify something like "do order #1,#2,#3, go back to the pizzeria and then do order #4"
% --> in this example, with d = 1 the problem evaluates UNSAT for this reason, maybe.


include "globals.mzn";

%%%%%%%%%%%%%%%%%%%%%  INPUT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Number of delivers
int: d = 3;



%% -- Graph

int: k = 4+1; %13+1;
int: E = 4+4; %18+4;

array[1..E] of int: from; % array of the beginning of the edges
array[1..E] of int: to;   % array of the ending of the edges
array[1..E] of int: w;    % array fo weights of the edges


%from = [1, 1, 1, 6,  5, 3, 2, 2,  7,  4, 10,  3,  9, 3, 8, 2,  8, 12,     14, 14, 14, 14];
%to   = [4, 7, 6, 5, 12, 4, 3, 7, 13, 11, 11, 10, 10, 9, 9, 8, 13, 13,     4,  7,  6,  1];
%w    = [3, 2, 1, 6,  4, 9, 2, 5,  7,  6,  4,  1,  2, 3, 2, 6,  3,  3,     3,  2,  1,  0];

% node #5 is a duplicate for root (#1). For allowing bounded_path to work properly. Exists also an edge from 1 to 5 with weigth = 0. 
from  = [1, 1, 1, 2,    5, 5, 5,    1];
to    = [2, 3, 4, 3,    2, 3, 4,    5];
w     = [1, 2, 3, 4,    1, 2, 3,    0];


%       2---3
%       |  /   
%       | /    
%      1(5)----4

%% -- Orders

int: N = 4;
array[1..N] of int: num_pizze; % array describing the number of pizzas for every order 
array[1..N] of int: orario;    % the decided time of the orders
array[1..N] of int: dest;      % the node where to deliver
orario     =  [19, 19, 19, 20];
num_pizze  =  [15, 15, 6,  6];
dest       =  [2,  4,  4,  3];


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% -- Delivers

% Matrix in which each row represents a single deliver.

% Each row contains the orders (IDs) that deliver has to do.  
array[1..d, 1..N] of var 0..N: orders_of_the_delivers; 

% Each row contains the nodes (ns) and the edges (es) that deliver reach/use.  
array[1..d, 1..k] of var bool: ns;
array[1..d, 1..E] of var bool: es;

%% -- 
array[1..d] of var int: peso_totale;
var int: peso;




%% -- Contraints

% All the order must be assigned 
constraint sum(orders_of_the_delivers) = N*(N+1) / 2;
% .. to only one deliver
constraint alldifferent_except_0(orders_of_the_delivers);


% The idea is: for each delivers, must have a path that starts from pizzeria (node 1) and get back to it (node 5 - dummy node for pizzeria)
% and also reachs every node assigned to the deliver.
constraint forall(i in 1..d, j in 1..N) (
              % exists a path from pizzeria and back 
              bounded_path(k, E, from, to, w, 1, 5, row(ns, i), row(es, i), peso_totale[i]) /\  % are we able to specify something like: one or more than one of these paths, concatenated?
              % reaching all nodes assigned to them
              ((orders_of_the_delivers[i, j] > 0) -> (ns[i,dest[orders_of_the_delivers[i, j]]] = true))
            );





%solve satisfy;
solve minimize sum(peso_totale);




output   
        ["order ID\tdest"] ++ ["\n"] ++
        [show(i) ++ "\t" ++ show(dest[i]) ++ "\n" | i in 1..N] ++ ["\n"] ++
        
        
        ["deliver\torder IDs assigned "] ++ ["\n"] ++ 
          [if j=1 then show(i) ++ "\t" else "" endif ++ 
          show(orders_of_the_delivers[i,j]) 
          ++ if j=N then "\n" else "  " endif | i in 1..d, j in 1..N] ++ ["\n"] ++
        
        ["deliver\tpath to do"] ++ ["\n"] ++ 
        [ if j=1 then show(i) ++ "\t" else "" endif ++ 
        if fix(es[i,j] == true) then show(from[j]) ++ "<->" ++ show(to[j]) ++ " "  else "" endif ++
        if j=E then "\n" else "" endif | i in 1..d, j in 1..E] ++ ["\n" ] ++[""];
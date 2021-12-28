include "globals.mzn";

%%%%%% VARIABLES %%%%%%
int: d;                   % number of deliverers
int: h;                   % "half-an-hour"
int: tph;                 % travels per half-an-hour
int: max_pizzas;          % max number of pizzas in one travel
array[1..E] of int: from; % array of the beginning of the edges
array[1..E] of int: to;   % array of the ending of the edges
array[1..E] of int: w;    % array fo weights of the edges
int: k;                   % number of nodes in the graph
int: E;                   % number of edges in the graph

array[1..N] of int: num_pizze; % array describing the number of pizzas for every order 
array[1..N] of int: orario;    % the decided time of the orders
array[1..N] of int: dest;      % the node where to deliver
int: N;                        % number of orders

%%%%%% INPUT %%%%%%
% d = 2;
% h = 12;

% from = [1, 1, 1, 6,  5, 3, 2, 2,  7,  4, 10,  3,  9, 3, 8, 2,  8, 12,     14, 14, 14, 14];
% to   = [4, 7, 6, 5, 12, 4, 3, 7, 13, 11, 11, 10, 10, 9, 9, 8, 13, 13,     4,  7,  6,  1];
% w    = [3, 2, 1, 6,  4, 9, 2, 5,  7,  6,  4,  1,  2, 3, 2, 6,  3,  3,     3,  2,  1,  0];
  
% k = 13+1;
% E = 18+4;
% N = 5;

% orario     =  [19, 19, 19, 19, 20];
% num_pizze  =  [15, 15, 16, 6,  6];
% dest       =  [2,  4,  4,  4,  3];
%%%%%%%%%
d = 2;
h = 6;
tph = 2;
max_pizzas = 16;
k = 4 + 1;
E = 4 + 4;
N = 5;

from  = [1, 1, 1, 2,    5, 5, 5,    1];
to    = [2, 3, 4, 3,    2, 3, 4,    5];
w     = [1, 2, 3, 4,    1, 2, 3,    0];

orario     =  [19, 19, 19, 19, 20];
num_pizze  =  [15, 15, 16, 6,  6];
dest       =  [2,  4,  4,  4,  3];

%%%%%% INPUT %%%%%%

%%%%%% DECISION VARIABLES %%%%%%

array[1..d, 1..N, 1..(h*tph)] of var bool: scheduling;

% Each row contains the nodes (ns) and the edges (es) that deliver reach/use in each half-an-hour
array[1..d, 1..k, 1..(h*tph)] of var bool: ns;
array[1..d, 1..E, 1..(h*tph)] of var bool: es;


array[1..d, 1..(h*tph)] of var int: path_w;

% Each element constains the number of pizzas carried in the corresponding half-an-hour
array[1..d, 1..(h*tph)] of var int: pizzas_carried;


%%%%%% CONSTRAINTS %%%%%%

% All the order must be assigned ...;
constraint sum(scheduling) = N;
% .. to only one deliver.
constraint forall(j in 1..N)(
    sum([scheduling[id,j,ih]| id in 1..d, ih in 1..(h*tph)]) = 1
  );


% The idea is: for each delivers, must have a path that starts from pizzeria (node 1) and get back to it (node 5 - dummy node for pizzeria)
% and also reachs every node assigned to the deliver.
% LIMIT: only 1 "circuit" for each deliver for each half-an-hour.
constraint forall(id in 1..d, ih in 1..(h*tph)) ( % for each deliver, for each half-an-hour
    bounded_path(k, E, from, to, w, 1, 5, [ns[id,j,ih] | j in 1..k], [es[id,j,ih] | j in 1..E], path_w[id,ih]) /\
    forall(iN in 1..N) (scheduling[id,iN,ih] = true -> ns[id,dest[iN],ih] = true)
  );


% This constraints the number of pizzas that each deliverer can carry in the HALF-AN-HOUR
constraint sum(pizzas_carried) = sum(num_pizze);
constraint forall(id in 1..d, ih in 1..(h*tph))(
  pizzas_carried[id, ih] = sum([ num_pizze[j] | j in 1..N where scheduling[id, j, ih] = 1])
  );
constraint forall(id in 1..d, ih in 1..(h*tph))( pizzas_carried[id, ih] <= max_pizzas );
constraint forall(id in 1..d, ih in 1..(h*tph))( pizzas_carried[id, ih] >= 0   );

% Constraints on the weight of the path in one half-an-hour
% constraint forall(id in 1..d, ih in 1..h)(
%   path_w[id, ih] >= 0 /\
%   path_w[id, ih] <= 30
%   );

% Constraints on the weigth of the paths done in 2 travels
%   the idea is to define the maximum number of travels that a deliver can make in one half-an-hour
%   by multplying the number of times slots available by the maximum number of travels that can be done
% 
constraint forall(id in 1..d, ih in 1..h)(
  ( ( path_w[id, (ih*tph)-1] + path_w[id, (ih*tph)] ) <= 30 ) /\
  ( ( path_w[id, (ih*tph)-1] + path_w[id, (ih*tph)] ) >= 0 )   
  );

%solve satisfy;
solve minimize sum(path_w);




output   
        ["order ID\tdest"] ++ ["\n"] ++
        ["--------\t----"] ++ ["\n"] ++
        [show(i) ++ "\t" ++ show(dest[i]) ++ "\n" | i in 1..N] ++ ["\n"] ++
        
        ["deliver\t"] ++ ["ord-" ++ show(i) ++"\t" | i in 1..N] ++ ["\n"] ++
        ["-------\t"] ++ ["------\t" | i in 1..N] ++ ["\n"] ++
        
        [
          if(i=1 /\ j=1) then "(h"++show(ih)++")\n" else "" endif ++
          if (j=1) then show(i) ++ "\t" else "" endif ++
          if fix(scheduling[i,j,ih])=true then "1" else "0" endif ++ "\t" ++
          %"(" ++ show(i) ++ " " ++ show(j) ++ " " ++ show(k) ++ ") " ++
          if(j=N) then "\n" else "" endif ++
          if(j=N /\ i=d) then "\n" else "" endif
            | ih in 1..h*tph, i in 1..d, j in 1..N] ++
        
        ["deliver\tpath_w\tpath"] ++ ["\n"] ++
        ["-------\t------\t----"] ++ ["\n"] ++

        [ if i=1 /\ j=1 then "(h"++show(ih)++")\n" else "" endif ++
          if (j=1) then show(i) ++ "\t" ++ show(path_w[i,ih])++"\t" else "" endif ++

          if fix(es[i,j,ih]) = true then show(from[j]) ++ "<->" ++ show(to[j]) ++ " "  else "" endif ++
                    if(j=E) then "\n" else "" endif ++

          if(j=E /\ i=d) then "\n" else "" endif   

        | ih in 1..h*tph, i in 1..d, j in 1..E] ++
        
        ["Pizzas carried:"] ++ 
        [if j == 1 then "\n d" ++ show(i) ++": "  ++ show(pizzas_carried[i,j]) else " " ++ show(pizzas_carried[i,j]) endif 
        | i in 1..d, j in 1..h*tph]  ++
        ["\n"] ++
        
        ["tot path weight: " ++ show(sum(path_w))];
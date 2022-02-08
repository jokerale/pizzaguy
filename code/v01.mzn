include "globals.mzn";
include "data/Visano_dijkstra.dzn";
include "data/temp-order.dzn";


%%%%%% INPUT %%%%%%

% Number of delivers
int: d;

% Time of service
int: start = 19;
int: end = 22;

% Half-an-hours of service 
int: h = 6; %(19.00 -> 22.00)

% Graph 
int: k;
array[1..k, 1..k] of int: mdist; % matrix of distances

% Orders
int: N;
array[1..N] of int: num_pizze; % array describing the number of pizzas for every order 
array[1..N] of float: orario;    % the decided time of the orders
array[1..N] of int: dest;      % the node where to deliver

array[1..N] of int: ra = [ round(floor(orario[iN]-start)*60 + (orario[iN] - floor(orario[iN]))*100) | iN in 1..N]; % requested arrival time (in minutes from start time)

%%%%%% DECISION VARIABLES %%%%%%

array[1..d, 1..N, 1..h] of var bool: scheduling;

% Each element constains the number of pizzas carried in the corresponding half-an-hour
array[1..d, 1..h] of var 0..16: pizzas_carried;

array[1..N] of var 0..h*30: ea; % estimated arrival time for each order (COULD BE INT)

array[1..d, 1..N, 1..h] of var array2set(dest) union {0}: P; % destinations to reach (COULD BE INT)

array[1..d, 1..N, 1..h] of var 0..N: X; % positions of the destinations to reach collapsed

array[1..d, 1..N, 1..h] of var 0..29: distances; % partial distances to reach the node (COULD BE INT)

%%%%%% CONSTRAINTS %%%%%%

% All the order must be assigned ...
constraint sum(scheduling) = N;
% .. to only one deliver.
constraint forall(j in 1..N)(
    sum([scheduling[id,j,ih]| id in 1..d, ih in 1..h]) = 1
  );  

%% NB: this constraint enforce that all the half-an-hour before the requested arrival time must be 0
constraint forall(id in 1..d, iN in 1..N, ih in 1..h)(
  (
    ((ih*30) <= ra[iN]) -> (scheduling[id,iN,ih] = 0 /\ distances[id,iN,ih] = 0) % /\ P[id,iN,ih] = 0  
  )
  /\
  (
    (((ih-1)*30) > (ra[iN]+15)) -> (scheduling[id,iN,ih] = 0 /\ distances[id,iN,ih] = 0) % /\ P[id,iN,ih] = 0 
  )

);

% P consistency
constraint forall(id in 1..d, ih in 1..h, iN in 1..N)(
  P[id, iN, ih] = scheduling[id, iN, ih] * dest[iN]
);

% X consistency
constraint forall(id in 1..d, ih in 1..h, iN in 1..N)(
  if P[id, iN, ih] > 0 then 
%   if P[id, iN, ih] != 0 then
    count([ X[id, iNN, ih] | iNN in 1..N] ,iN,1)
    else 
    count([ X[id, iNN, ih] | iNN in 1..N] ,iN,0) 
  endif
  /\
  % push 0s at the bottom  -- WE COULD DO IT IN A DIFFERENT WAY
  ( X[id,iN,ih]=0 -> forall(j in iN..N) (X[id,j,ih] = 0) )
);

% % distances consistency
% constraint forall(id in 1..d, ih in 1..h, iN in 1..N)(
%    distances[id, iN, ih] >= 0
% %     /\
% %     distances[id, iN, ih] <= 30
% );

constraint forall(id in 1..d, ih in 1..h, iN in 1..N)(
  count([X[id,iNN,ih]| iNN in 1..N], iN, 0) -> distances[id,iN,ih] = 0
);

constraint forall(id in 1..d, iN in 1..N, ih in 1..h)(
  % calculate distances
  
  if X[id,iN,ih] !=0 then
  
    if iN == 1 then
      distances[id, X[id,iN,ih], ih] = mdist[1, P[id, X[id,iN,ih], ih]] 
    else
      distances[id, X[id,iN,ih], ih] = 
         mdist[P[id, X[id,iN - 1,ih], ih], P[id, X[id,iN,ih], ih]] 
         %+ sum([distances[id,P[id, X[id,iNN,ih], ih],ih] | iNN in 1..iN-1])
         + distances[id,X[id,iN-1,ih], ih]
    endif
  
  endif
  
);

constraint forall(id in 1..d, iN in 1..N, ih in 1..h)(
  % add constraint on total distances
  if X[id,iN,ih] !=0 then
    if iN+1 == N+1 then
      distances[id, X[id,iN,ih], ih] + mdist[P[id, X[id,iN,ih], ih],1] < 30
      %/\
      %distances[id, X[id,iN,ih], ih] + mdist[P[id, X[id,iN,ih], ih],1] >= (ih-1)*30
    else
      if X[id,iN+1,ih] == 0 then
        distances[id, X[id,iN,ih], ih] + mdist[P[id, X[id,iN,ih], ih],1] < 30
        %/\
        %distances[id, X[id,iN,ih], ih] + mdist[P[id, X[id,iN,ih], ih],1] >= (ih-1)*30
      endif
    endif
    
  endif
);

constraint forall(j in 1..N)(
    ea[j] = sum([scheduling[id,j,ih] * (distances[id,j,ih]+((ih-1)*30)) | id in 1..d, ih in 1..h])  
    %ea[j] = sum([(distances[id,j,ih]+((iNh-1)*30)) | id in 1..d, ih in 1..h])  
  );
  


% This constraints the number of pizzas that each deliverer can carry in the HALF-AN-HOUR
constraint sum(pizzas_carried) = sum(num_pizze);
constraint forall(id in 1..d, ih in 1..h)(
  pizzas_carried[id, ih] = sum([ num_pizze[j] | j in 1..N where scheduling[id, j, ih] = 1])
  );
%constraint forall(id in 1..d, ih in 1..h)( pizzas_carried[id, ih] <= 16 );
%constraint forall(id in 1..d, ih in 1..h)( pizzas_carried[id, ih] >= 0   );

% SIMMETRY BREAKING STRATEGY, this force an ordering in the number of pizzas carried by each deliverer in one half-an-hour. The first is greater than the second, which is greater then the third an so on...
constraint forall(ih in 1..h, id in 1..d-1)(
  pizzas_carried[id,ih] >= pizzas_carried[id+1,ih]
);

% must arrive in the delivery time window
constraint forall(iN in 1..N)(
  ea[iN] >= ra[iN] /\ ea[iN] < ra[iN]+30 
);


% Trying to optimize
% constraint forall(ik in 1..k)(
%  ( count(dest,k,0) -> count(P,k,0) )
%  /\
%  ( count(dest,k,1) -> count(P,k,1) )
% );



% For each line of P, the number of zeros must be the same as the
% number of zeros in the same line of X.
constraint forall(id in 1..d, ih in 1..h)(
  count([P[id,iN,ih] | iN in 1..N],0) = count([X[id,iN,ih] | iN in 1..N],0)
);



% May not improve
% constraint forall(kk in array2set(dest))(
%   count(P,kk) = count(dest,kk)
% );



% constraint forall(ik in 1..k)(
%   let{
%        var int: c;
%     } in  count(dest,k,c) -> count(P,k,c)
% %   /\
% %   ( count(dest,k,1) -> count(P,k,1) )
% );




%solve :: int_search( P,
%        first_fail, indomain_random) minimize sum(distances);
%solve satisfy;
solve minimize sum(distances);


output   

       ["order ID\tdest"] ++ ["\n"] ++
       ["--------\t----"] ++ ["\n"] ++
       [show(i) ++ "\t" ++ show(dest[i]) ++ "\n" | i in 1..N] ++ ["\n"] ++
       
       ["\nSCHEDULING\n"] ++
       ["deliver\t"] ++ ["ord-" ++ show(i) ++"\t" | i in 1..N] ++ ["\n"] ++
       ["-------\t"] ++ ["------\t" | i in 1..N] ++ ["\n"] ++
       
       [
         if(i=1 /\ j=1) then "(h"++show(ih)++")\n" else "" endif ++
         if (j=1) then show(i) ++ "\t" else "" endif ++
         if fix(scheduling[i,j,ih])=true then "1" else "0" endif ++ "\t" ++
         %"(" ++ show(i) ++ " " ++ show(j) ++ " " ++ show(k) ++ ") " ++
         if(j=N) then "\n" else "" endif ++
         if(j=N /\ i=d) then "\n" else "" endif
           | ih in 1..h, i in 1..d, j in 1..N] ++
           
       ["\nP\n"] ++    
       ["deliver\t"] ++ ["ord-" ++ show(i) ++"\t" | i in 1..N] ++ ["\n"] ++
       ["-------\t"] ++ ["------\t" | i in 1..N] ++ ["\n"] ++
       
       [
         if(i=1 /\ j=1) then "(h"++show(ih)++")\n" else "" endif ++
         if (j=1) then show(i) ++ "\t" else "" endif ++
         show(P[i,j,ih]) ++ "\t" ++
         %"(" ++ show(i) ++ " " ++ show(j) ++ " " ++ show(k) ++ ") " ++
         if(j=N) then "\n" else "" endif ++
         if(j=N /\ i=d) then "\n" else "" endif
           | ih in 1..h, i in 1..d, j in 1..N] ++
       
       ["\nX\n"] ++
       ["deliver\t"] ++ ["ord-" ++ show(i) ++"\t" | i in 1..N] ++ ["\n"] ++
       ["-------\t"] ++ ["------\t" | i in 1..N] ++ ["\n"] ++
       
       [
         if(i=1 /\ j=1) then "(h"++show(ih)++")\n" else "" endif ++
         if (j=1) then show(i) ++ "\t" else "" endif ++
         show(X[i,j,ih]) ++ "\t" ++
         %"(" ++ show(i) ++ " " ++ show(j) ++ " " ++ show(k) ++ ") " ++
         if(j=N) then "\n" else "" endif ++
         if(j=N /\ i=d) then "\n" else "" endif
           | ih in 1..h, i in 1..d, j in 1..N] ++
       
       ["\ndistances*scheduling\n"] ++
       ["deliver\t"] ++ ["ord-" ++ show(i) ++"\t" | i in 1..N] ++ ["\n"] ++
       ["-------\t"] ++ ["------\t" | i in 1..N] ++ ["\n"] ++
       
       [
         if(i=1 /\ j=1) then "(h"++show(ih)++")\n" else "" endif ++
         if (j=1) then show(i) ++ "\t" else "" endif ++
         show((distances[i,j,ih])*scheduling[i,j,ih]) ++ "\t" ++
         %show((distances[i,j,ih])*scheduling[i,j,ih]) ++ "\t" ++
         %"(" ++ show(i) ++ " " ++ show(j) ++ " " ++ show(k) ++ ") " ++
         if(j=N) then "\n" else "" endif ++
         if(j=N /\ i=d) then "\n" else "" endif
           | ih in 1..h, i in 1..d, j in 1..N] ++
           
       %["\nexpected arrival: ["] ++ [ show(start+(ea[i] div 60)) ++ "." ++ show(ea[i] mod 60) ++ if i=N then "]" else ", " endif | i in 1..N ] 
       ["\nea: "] ++ [show(ea)]
       ++["\nra: "] ++ [show(ra)]
       
       ++["\nsum(distances): "] ++ [show(sum(distances))] ++ ["\n"]
       
       % FORMATTED OUTPUT FOR PYTHON
       
       ++ ["\n\nThe above output is formatted in this way:"]
       ++ ["\n\tFirst line: number of deliverer;number of half-an-hour; number of orders"]
       ++ ["\n\tAll the other lines: d_index;h_index; dest1 dest2 .. destN\n"]
       ++ ["\nELABORATION_DATA\n"] 
       ++ [show(d) ++ ";" ++ show(h) ++ ";" ++ show(N) ++ "\n"] 
       ++ [if (iN==1) then show(id)++";"++show(ih)++";" else "" endif
           ++ if (fix(X[id,iN,ih])>0) then show(dest[X[id,iN,ih]]) else "" endif   
           ++ if (iN==N) then "\n" else " " endif 
             | ih in 1..h, id in 1..d, iN in 1..N]
       ++ ["\n"]
       
       ;
       
         
%
%         ["order ID\tdest"] ++ ["\n"] ++
%         ["--------\t----"] ++ ["\n"] ++
%         [show(i) ++ "\t" ++ show(dest[i]) ++ "\n" | i in 1..N] ++ ["\n"] ++
        
%         ["deliver\t"] ++ ["ord-" ++ show(i) ++"\t" | i in 1..N] ++ ["\n"] ++
%         ["-------\t"] ++ ["------\t" | i in 1..N] ++ ["\n"] ++
        
%         [
%           if(i=1 /\ j=1) then "(h"++show(ih)++")\n" else "" endif ++
%           if (j=1) then show(i) ++ "\t" else "" endif ++
%           if fix(scheduling[i,j,ih])=true then "1" else "0" endif ++ "\t" ++
%           %"(" ++ show(i) ++ " " ++ show(j) ++ " " ++ show(k) ++ ") " ++
%           if(j=N) then "\n" else "" endif ++
%           if(j=N /\ i=d) then "\n" else "" endif
%             | ih in 1..h, i in 1..d, j in 1..N] ++
        
%         ["deliver\t#pizzas\tpath_w\tpath"] ++ ["\n"] ++
%         ["-------\t-------\t------\t----"] ++ ["\n"] ++

%         [ if i=1 /\ j=1 then "(h"++show(ih)++")\n" else "" endif ++
%           if (j=1) then show(i) ++ "\t" ++ show(sum([scheduling[i,iN,ih] * num_pizze[iN] | iN in 1..N])) ++"\t" ++ show(path_w[i,ih])++"\t" else "" endif ++

%           if fix(es[i,j,ih]) = true then show(from[j]) ++ "<->" ++ show(to[j]) ++ " "  else "" endif ++
%                     if(j=E) then "\n" else "" endif ++

%           if(j=E /\ i=d) then "\n" else "" endif   

%         | ih in 1..h, i in 1..d, j in 1..E] ++
        
%         ["Pizzas carried:"] ++ 
%         [if j == 1 then "\n d" ++ show(i) ++": "  ++ show(pizzas_carried[i,j]) else " " ++ show(pizzas_carried[i,j]) endif 
%         | i in 1..d, j in 1.. h]  ++
%         ["\n"] ++
        
%         ["tot path weight: " ++ show(sum(path_w))]
        
%         ++ ["\nexpected arrival: ["] ++ [ show(start+(ea[i] div 60)) ++ "." ++ show(ea[i] mod 60) ++ if i=N then "]" else ", " endif | i in 1..N ];








%%%%%% INPUT %%%%%%

% (1)
% orario = [21.00, 19.45, 20.30];
% dest = [2, 3, 6];
% num_pizze = [1, 4, 3];
% k = 13;
% N = 3;
% mdist = [| 0,  7,  9,  3,   7,  1,  2,  12, 12, 10, 9,  11, 9
%          | 7,  0,  2, 10,   14, 8,  5,  6,  5,  3,  7,  12, 9
%          | 9,  2,  0,  9,   15, 10, 7,  5,  3,  1,  5,  11, 8
%          | 3,  10, 9,  0,   10, 4,  5,  14, 12, 10, 6,  14, 12
%          | 7,  14, 15, 10,  0,  6,  9,  10, 12, 14, 16, 4,  7
%          | 1,  8,  10, 4,   6,  0,  3,  13, 13, 11, 10, 10, 10
%          | 2,  5,  7,  5,   9,  3,  0,  10, 10, 8,  11, 10, 7
%          | 12, 6,  5,  14,  10, 13, 10, 0,  2,  4,  8,  6,  3
%          | 12, 5,  3,  12,  12, 13, 10, 2,  0,  2,  6,  8,  5
%          | 10, 3,  1,  10,  14, 11, 8,  4,  2,  0,  4,  10, 7
%          | 9,  7,  5,  6,   16, 10, 11, 8,  6,  4,  0,  14, 11
%          | 11, 12, 11, 14,  4,  10, 10, 6,  8,  10, 14, 0,  3
%          | 9,  9,  8,  12,  7,  10, 7,  3,  5,  7,  11, 3,  0
%          |];

% (2)
% int: k = 5;
% mdist = [| 0, 1, 2, 2, 3
%          | 1, 0, 2, 21, 3
%          | 2, 2, 0, 4, 1
%          | 2, 21, 4, 0, 5
%          | 3, 3, 1, 5, 0
%          |];
% orario     =  [19.15, 19.30, 19.30, 20.30, 19.45, 19.30, 20.30, 21.30];
% num_pizze  =  [2,     8,     8,     6,     5,     8,     8,     6];
% dest       =  [2,     4,     4,     3,     2,     5,     3,     5];
% N = 8;
include "globals.mzn";


% https://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.300.4714&rep=rep1&type=pdf

% from scheduling matrix
int: N = 10;
array[1..N] of int: dest = [2,3,4,4,2,3,4,2,4,5];
array[1..N] of int: scheduling = [1,1,0,1,0,0,0,0,0,1];


% graph
int: k = 7; 
int: E = 9; 

array[1..E] of int: from  = [1, 2, 5, 3, 4, 5, 3, 6, 1]; 
array[1..E] of int: to    = [2, 3, 1, 4, 5, 6, 6, 1, 7];
array[1..E] of int: w     = [1, 1, 1, 1, 1, 1, 1, 1, 0];

array[1..k, 1..k] of var int: mdist; % matrix of distances
mdist = [| 0, 1, 4, 4, 5, 9, 1
         | 1, 0, 2, 3, 2, 9, 1
         | 4, 2, 0, 3, 3, 9, 1
         | 4, 3, 3, 0, 7, 9, 1
         | 5, 2, 3, 7, 0, 9, 1
         | 9, 9, 9, 9, 9, 0, 1
         | 1, 1, 1, 1, 1, 1, 0
         |];




% INPUT
array[1..N] of int: P = [dest[i]*scheduling[i] | i in 1..N];



int: O = 4;
array[1..O] of var array2set(P): X;

array[1..O, 1..k] of var bool: ns;
array[1..O, 1..E] of var bool: es;
array[1..O] of var int: W;
var int: num_zeros = sum([X[i]=0 | i in 1..O]);


array[1..k, 1..k, 1..k] of var bool: xx;
array[1..k, 1..k, 1..E] of var bool: yy;

array[1..O+1] of var int: distances;

% constraint forall(i in 1..k, j in 1..k)(mdist[i,j]>=0);
% constraint forall(i in 1..k, j in 1..k)(
%   if (j>=i) then
%     mdist[i,k] = 0
%   else
%     bounded_path(k, E, from, to, w, i, j, [xx[i,j, l] | l in 1..k], [yy[i,j,m] | m in 1..E], mdist[i,j])

%   endif
% );

constraint forall(i in 1..N) (if P[i] > 0 then count(X,P[i],1) else true endif );
constraint alldifferent_except_0(X);
constraint forall(i in 1..O) (X[i]=0 -> forall(j in i..O) (X[j] = 0));

constraint distances[1] = mdist[1, X[1]];
constraint forall(i in 1..O-1)(
  distances[i+1] = mdist[X[i], X[i+1]]
);
constraint distances[O+1] = mdist[X[O], 1];

constraint forall(i in 1..O+1)(distances[i]>=0);

% array[1..O] of var int: tt;
% constraint forall(i in 1..O)(tt[i]>=0);

% constraint bounded_path(k, E, from, to, w, 1, X[1], [ns[1,j] | j in 1..k], [es[1,j] | j in 1..E], tt[1]);
%  constraint forall(i in 1..O-1) (
%     % (X[i+1] != 0 <-> bounded_path(k, E, from, to, w, X[i], X[i+1], [ns[i+1,j] | j in 1..k], [es[i+1,j] | j in 1..E], tt[i+1]))
%      true
    
% %    bounded_path(k, E, from, to, w, X[i], X[i+1], [ns[i+1,j] | j in 1..k], [es[i+1,j] | j in 1..E], tt[i+1])

%     %if X[i+1] != 0 then 
% %    (bounded_path(k, E, from, to, w, X[i], X[i+1], [ns[i+1,j] | j in 1..k], [es[i+1,j] | j in 1..E], tt[i+1]) <-> X[i+1] !=0)
%   %else
% %   /\
%     % dummy
% %    (bounded_path(k, E, from, to, w, 1, 7, [ns[i+1,j] | j in 1..k], [es[i+1,j] | j in 1..E], tt[i+1]) <-> X[i+1] = 0)
%   %endif
%  );
% predicate my_bp(int: N, int: E, array[int] of int: from, array[int] of int: to, array[int] of int: w,
%                    var int: s, var int: t, array[int] of var bool: ns, array[int] of var bool: es, var int: K) =

% all zeros at the bottom
%constraint forall(i in 1..O) (X[i] = 0 -> -> forall(j in i..O) (X[j] = 0));

%constraint forall(i in 1..N) (  dest[i]*scheduling[i] > 0 -> )


solve minimize sum(distances);

output
  ["P: "] ++ [show(P)] ++ ["\n"] ++
       ["X: "] ++ [show(X)] ++ ["\n"] ++
%       ["tt: "] ++ [show(tt)] ++
%       ["nz: "] ++ [show(num_zeros)] ++ 
 %     ["mdist: "] ++ [show(mdist)]
 ["Sdist: "] ++ [show(sum(distances))] ++ ["\n"]++
 ["dist: "] ++ [show(distances)];
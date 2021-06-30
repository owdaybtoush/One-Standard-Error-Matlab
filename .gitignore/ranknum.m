function R = ranknum(V, P)
% RANKNUM - compute the rank number (rankings) of elements
%   R = ranknum(V) returns the rank numbers of the elements of the
%   (numerical) vector V, using the dense ranking procedure for ties
%   (see below). NaNs are ignored (rank NaN). R has the same size as V.
%
%   R = RANKNUM(V, P) ranks V according to the ranking procedure P, which
%   specifies how to deal with values that tie for the same ranking
%   position. P is a number from 1 to 5.
%
%     P  | Ranking Type    | Ties get ... rank | V = [1 2 2 4] -> R =
%   ----------------------------------------------------------------------
%     1  | Dense (default) | same              |   1  2   2  3
%     2  | Ordinal         | consecutive       |   1  2   3  4
%     3  | Competition     | same minimum      |   1  2   2  4
%     4  | Modified Comp.  | same maximum      |   1  3   3  4
%     5  | Fractional      | same average      |   1 2.5 2.5 4
%
%   Examples:
%      ranknum([5 0 5 1 Inf NaN 1])   % -> 3    1  3    2    4  NaN  2
%      ranknum([5 0 5 1 Inf NaN 1],2) % -> 4    1  5    2    6  NaN  3
%      ranknum([5 0 5 1 Inf NaN 1],3) % -> 4    1  4    2    6  NaN  2
%      ranknum([5 0 5 1 Inf NaN 1],4) % -> 5    1  5    3    6  NaN  3
%      ranknum([5 0 5 1 Inf NaN 1],5) % -> 4.5  1  4.5  2.5  6  NaN  2.5
%
%   V can be a cell array of strings, for which alphabetical ordering is
%   used. An example:
%      ranknum({'C','A','C' ; 'A' 'X' 'D'}) % -> [2 1 2 ; 1 4 3]
%
%   See also SORT, UNIQUE
%            TIEDRANK, RANKSUM (Stats Toolbox)
%            FILLZERO, RUNINDEX (File Exchange)
%
%   Notes:
%   - For more info on ranking, see https://en.wikipedia.org/wiki/Ranking
%   - In the standard competition ranking, each item's ranking number is 1
%     plus the number of items ranked above it; in the modified competition
%     ranking, each item's ranking number is equal to the number of items
%     ranked equal to it or above it.

% Version 3.1.2 (feb 2019)
% (c) Jos van der Geest
% email: samelinoa@gmail.com
% http://www.mathworks.nl/matlabcentral/fileexchange/authors/10584
%
% History:
%   1.0 (dec 2005) - created
%   2.0 (jun 2015) - implemented handling of ties
%   3.0 (feb 2019) - changed everything to clever indexing and
%                    vectorisation
%   3.1 (feb 2019) - modernised, edited help, put on File Exchange
%                    3.1.2 (minor edits)

%% argument checking, preparation, pre-allocation of output
narginchk(1, 2)
R = nan(size(V)) ; % preallocate the output with the size of V

if iscellstr(V) || isstring(V)
    [~, ~, V] = unique(V) ; % convert to alphanumeric values
elseif ~isnumeric(V)
    error(['First input should be a numeric array,' ...
        'a cell array of strings, or a string array.']) ;
end
if nargin == 1, P = 1 ; end % default: Dense Ranking "1223"

qNaN = ~isnan(V) ;
V = reshape(V(qNaN), 1, []) ; % remove NaNs from V and make it a row vector
% we can now specify dimensions to sort, diff and cumsum to speed things up

%% Do the ranking
switch P % P specifies the ranking procedure
    case 1                    %== DENSE RANKING "1223"
        [~, ~, Rx] = unique(V, 'sorted') ; % easy :-)
        
    case 2                    %== ORDINAL RANKING "1234"
        [~, Ri] = sort(V, 2, 'ascend') ;
        Rx(Ri) = 1:numel(V) ; % left-hand indexing trick, also easy :-)
        
    case 3                    %== STANDARD COMPETITION RANKING "1224"
        [V, Ri] = sort(V, 2, 'descend') ; % competition
        Rx(Ri) = local_comprank(V) ;
        
    case {4, 5}               %== MODIFIED COMPETITION "1334" 
                              %   (or fractional)
        [~, Ri] = sort(V, 2, 'descend') ;
        [Rx(Ri), hasTies] = local_comprank(V(Ri)) ;
        Rx = numel(V) + 1 - Rx ;
        % Rx is the modified competition ranking
        
        if P == 5 && hasTies  %== FRACTIONAL RANKING "1 2.5 2.5 4"
            % Fractional ranking equals the average of both competition
            % rankings, which only differ when there are ties!!
            [V, Ri] = sort(V, 2, 'ascend') ; % re-sort V to get ..
            RxS(Ri) = local_comprank(V) ;    % .. standard competition
            Rx = (Rx + RxS) / 2 ;            % average -> fractional
        end
        
    otherwise % invalid ranking procedure
        error(['Second input must be a scalar value between 1 and 5.' ...
            '\nSee the help of %s.'], mfilename) ;
end
R(qNaN) = Rx ; % fill in the ranks, leaving NaNs in place

% == END OF MAIN FUNCTION =================================================

function [Rx, hasTies] = local_comprank(W)
% Local function to get a competition ranking. W is a sorted row vector
% and no error checking is needed, so it is quite fast.
dW0 = diff(W, 1, 2) == 0 ; % dW0(k) is true when W(k+1)==W(k)
hasTies = any(dW0) ;
if hasTies
    I = [1 find(~dW0)+1] ; % ranks of untied, or first of tied items
    % Create a new vector R with the differences in ranks at those indices.
    % We use the trick X([N 1 ; ..]) = [1 ...] to create 1-by-N vector.
    Rx([numel(W) I]) = [0 1 diff(I, 1, 2)] ;
    % R is 0 for values that are tied with the previous values
    % with cumsum convert differences into ranks and fill in the zeros.
    Rx = cumsum(Rx, 2) ; 
else
    Rx = 1:numel(W) ; % no ties
end

%% AN ALTERNATIVE for FRACTIONAL RANKING
% using sort, unique and accumarray; slower & not so nicely vectorised :-)
% function R = fractional_ranknum(V)
% [~, R] = sort(V(:)) ;  % sort V
% R(R) = 1:numel(V) ;    % get the ordinal ranks
% [~, ~, R2] = unique(V(:)) ; % get the ties
% average ordinal ranks accross ties
% X = accumarray(R2, R, [max(R2) 1] , @mean) ;
% R = reshape(X(R2), size(V)) ;



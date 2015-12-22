function [factblock] = factorizeblock(vars,rmode)
%-------------------------------------------------------------------------%
% Factorial block
% Make full factorial block for all your variables.
%
% Input
%   - vars:     struct with all variables as separate field. Each variable
%               should contain all possible values that variable can take
%               in your design
%   - rmode:    string to specify randomization mode
%               'sort'    -> ordered, factorial trialblock (default)
%               'shuffle' -> shuffled trials
%
%                                                                J.F. 2015
%-------------------------------------------------------------------------%

% check input
if nargin < 2; rmode = 'sorted'; end;
varnames  = fieldnames( vars )';
nvar      = length( varnames );

% count number of levels for every variable
n = NaN(1,nvar);
for i_var = 1:nvar
    n(i_var) = eval( [ 'length( vars.' varnames{i_var} ' );' ] ); 
end

% make output array
factblock = NaN(prod(n),nvar);
for i_var = 1:nvar
    curr_var = eval( [ 'sort( repmat( vars.' varnames{i_var} ', 1, prod(n(1:' num2str(i_var) '-1) ) ) );' ] );
    factblock(:,i_var) = repmat( curr_var, 1, prod(n) / length(curr_var) )';
end

% randomize if requested
switch rmode
    case 'sort'
        % leave block sorted as it is
        
    case 'shuffle'
        rand_rowIdx = Shuffle(1:prod(n));
        factblock = factblock(rand_rowIdx,:);
    otherwise
        error('Incorrect randomization mode entered. Please use "sort" or "shuffle"');
end


end


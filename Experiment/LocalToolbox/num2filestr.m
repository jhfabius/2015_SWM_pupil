function subjstr = num2filestr(subjnum,maxdigit)
%-------------------------------------------------------------------------%
% num2filestr
%
% convert file number to string, with zero's preceding file number if
% smaller than specified number of max digits.
%
% maxdigit defaults to 2
%
% example:
% subjnum = 3
% subjstr = subjnum2str(3,2);
% subjstr: '03' 
%-------------------------------------------------------------------------%

% default of maxdigit = 10
if nargin < 2
    maxdigit = 2;
end

% convert to string
subjstr = num2str(subjnum);

% add zeros if applicable
if subjnum < 10^(maxdigit-1)
    
    for jnk = 1:maxdigit-1
        subjstr = [ '0' subjstr ];
    end
    
end

end
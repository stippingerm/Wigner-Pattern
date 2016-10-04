function [varargout] = num2var(a,dims)
%NUM2VAR Convert numeric array into array of variables.
%Inspred by NUM2CELL
%   C = NUM2VAR(A) converts numeric array A into cell array C by placing
%   each element of A into a separate cell in C. The output array has the
%   same size and dimensions as the input array. Each cell in C contains
%   the same numeric value as its respective element in A.
%
%   C = NUM2VAR(A, DIM) converts numeric array A into a cell array of
%   numeric vectors, the dimensions of which depend on the value of the DIM
%   argument. Return value C contains NUMEL(A)/SIZE(A,DIM) vectors, each of
%   length SIZE(A, DIM). The DIM input must be an integer with a value from
%   NDIMS(A) to 1.
%
%   C = NUM2VAR(A, [DIM1, DIM2, ...]) converts numeric array A into a cell
%   array of numeric arrays, the dimensions of which depend on the values
%   of arguments [DIM1, DIM2, ...]. Given the variables X and Y, where
%   X=SIZE(A,DIM1) and Y=SIZE(A,DIM2), return value C contains
%   NUMEL(A)/PROD(X,Y,...) arrays, each of size X-by-Y-by-.... All DIMn
%   inputs must be an integer with a value from NDIMS(A) to 1.
%
%   NUM2VAR works for all array types.
%
%   Use CELL2MAT or CAT(DIM,C{:}) to convert back.
%
%   See also MAT2CELL, CELL2MAT

%   Clay M. Thompson 3-15-94
%   Copyright 1984-2012 The MathWorks, Inc.

narginchk(1,2);
if nargin==1
    varargout = cell(size(a));
    %if size(varargout) ~= size(a)
    %    error(message('Input and output must be aligned'));
    %end
    for i=1:numel(a)
        varargout{i} = a(i);
    end 
    return
end

% Size of input array
siz = [size(a),ones(1,max(dims)-ndims(a))];

% Create remaining dimensions vector
rdims = 1:max(ndims(a),max(dims));
rdims(dims) = []; % Remaining dims

% Size of extracted subarray
bsize(sort(dims)) = siz(dims);
bsize(rdims) = 1; % Set remaining dimensions to 1

% Size of output cell
csize = siz;
csize(dims) = 1; % Set selected dimensions to 1
varargout = cell(csize);
%if size(varargout) ~= csize
%    error(message('Input and output must be aligned'));
%end

% Permute A so that requested dims are the first few dimensions
a = permute(a,[dims rdims]); 

% Make offset and index into a
offset = prod(bsize);
ndx = 1:prod(bsize);
for i=0:prod(csize)-1,
  varargout{i+1} = reshape(a(ndx+i*offset),bsize);
end

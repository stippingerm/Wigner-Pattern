function [ N ] = normalize( M, axis )
%NORMALIZE Normalize data in array along a given axis
%   Detailed explanation goes here

mn = mean(M, axis);
sd = std(M, 1, axis);
sd(sd==0) = 1;

N = bsxfun(@minus,M,mn);
N = bsxfun(@rdivide,N,sd);

end


function dst = get_acc_dst(pos)
% GET_ACC_DST get the distance accumulated during the lap
%
% INPUTS:
%   pos: n_tics x n_dim array

% Marcell Stippinger, 2016

if size(pos,1)==1 && size(pos,2)>1
    pos = pos';
end

    sqr_dst      = sum((pos(2:end,:) - pos(1:end-1,:)).^2,2);
    dst          = [0; cumsum(sqrt(sqr_dst))];


function [idx_out] = get_wheel_running(wheel, idx_lap)
% GET_WHEEL_RUNNING get the support of the time series
% wheel(idx_lap(1):idx_lap(2))
%
% INPUTS:
%   wheel: n_tics x 1 time series
%   idx_lap: 1x2 indices

% Marcell Stippinger, 2016


%if sect_in == 13
% for wheel section extract spikes when the wheel is moving
% TODO: move test to a variable "condition" because it's more general
%       apply it to all sections; verify whether we need a continuous
%       interval or moments with moving wheel
wheelNonZero    = find(wheel(idx_lap(1):idx_lap(2))~=0);
if isempty(wheelNonZero)
    idx_out = [idx_lap(1) idx_lap(1)-1];    
else
    idx_whl_lap    = [wheelNonZero(1), wheelNonZero(end)];
    idx_out        = idx_lap(1) + idx_whl_lap - 1;
end

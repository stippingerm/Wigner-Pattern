function [R, varargout] = reshape_laps(D, keep_neurons, max_length, varargin)
%RESHAPE_LAPS is a utility to format spiking data for the GPFA implementation
%    additionally it
%    * restricts the set of available neurons
%    * splits long laps into smaller units improving the speed of GPFA
%      while trying to preserve correlations using overlapping units
%Input:
%    D: spike data with fields spike_field (default: 'spike_count' or 'y')
%    keep_neurons: channels to keep
%    max_length: maximal duration to be kept as one lap
%    You can optionally overrife varagin.
%
% Author:
% Marcell Stippinger, 2016

%TODO: implement overlapping splittings to simulate continuity over time

if isfield(D,'spike_count')
    spike_field = 'spike_count';
else
    spike_field = 'y';
end
%duration_field  = 'T';
assignopts(who, varargin);

n_laps          = length(D);
separators      = cell(1,n_laps);
n_pieces        = 0;

for i_lap = 1 : n_laps
    %lap_length  = D(i_lap).(duration_field);
    lap_length  = size(D(i_lap).(spike_field),2);
    if max_length
        lap_pieces  = ceil(lap_length*1./max_length);
    else
        lap_pieces  = 1;
    end
    n_pieces    = n_pieces + lap_pieces;

    ls          = round(linspace(1,lap_length+1,lap_pieces+1));
    sep1        = [ls(1:end-1)' ls(2:end)'];
    ls          = round([1 mean(sep1,2)' lap_length+1]);
    sep2        = [ls(1:end-1)' ls(2:end)'];
    separators{i_lap} = [sep1; sep2];
end

% copy only the field names from D and
% create fields y and T if not already existing (for later assignment)
if ~isfield(D,'T')
    [D(1).T]=[];
end
if ~isfield(D,'y')
    [D(1).y]=[];
end
R               = struct(D(1:0));
n_pieces        = 0;
originals       = zeros(n_pieces,1);


% TODO: deal with fields spikes and spike_count, e.g. remove them

for i_lap = 1 : n_laps
    lap_sepa    = separators{i_lap};
    lap_pieces  = size(lap_sepa,1);

    %R(n_pieces+1:n_pieces+lap_pieces) = repmat(D(i_lap),lap_pieces);
    
    for j = 1 : lap_pieces
        R(n_pieces+j) = D(i_lap);
        R(n_pieces+j).T = lap_sepa(j,2)-lap_sepa(j,1);
        R(n_pieces+j).y = D(i_lap).(spike_field)(keep_neurons,lap_sepa(j,1):lap_sepa(j,2)-1);
    end
    originals(n_pieces+1:n_pieces+lap_pieces) = i_lap;
    n_pieces = n_pieces + lap_pieces;
end

if nargout > 1
    varargout{1} = originals;
end
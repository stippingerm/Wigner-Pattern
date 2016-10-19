function [D, varargout] = extract_general(Fs, bw, spk, pos, laps, events, ...
                                          meta, varargin)
% EXTRACT_LAPS Takes the elements of the HC-5 database as single time series
% and calculates spike rates and divides the vectors into laps.
% More formation about the database in
% crcns.org/files/data/hc-5/crcns-hc5-data-description.pdf
%
% INPUTS:
%   Fs:     sampling frequency (Hz, Default: 1250)
%   bw:     width of bins (s, Default: 0.040)
%           NOTE: to get spike trains set bw=1/Fs
%                 roundoff errors migh occur
%   spk:    n_clust x 1 cell array, each cell containing spike times (clock
%           tics) for the given neuron
%   pos:    T x d_dims vector of position of the animal in the x-axis for
%           the whole experiment
%   laps:   n_laps x 2 vector containing the start/end clock tic for each
%           lap
%   events: n_laps x 1 cell array containing the vector of event tics for
%           each lap (Default: cell())
%   meta:   n_laps x 1 struct array with metadata (Default: struct([]))
%
%   extra input arrays of the same length as pos are extracted per lap
%   into extra output variables
% 
%   Keyword arguments (must be last among varargin)
%       useSqrt (bool) :  perform square root transformation
%       useRates (bool) : calculate instantaneous spiking rate instead of
%                         spike counts
%       format ('hc5', 'view') : which format spk complies with
%
%   TODO:   implement maxTime (maximal duration of trials)
%   TODO:   decimate pos or downsample?
%
%
% See also branch2, branch2_cleaned.m

% Revision:  Sep14: generalized method and variables
% Marcell Stippinger, 2016


useSqrt         = 1; % square root tranform for pre-processing?
useRates        = 1; % use spike rates (rather than counts)
useFloats       = 0; % spike times are floats
format          = 'hc5';
nXtra           = 0;

for i = 1:length(varargin)
    if ischar(varargin{i})
        assignopts(who,varargin(i:end));
        nXtra   = i-1;
        break
    end
end

% shape of the data
if strcmp(format,'hc5')
    n_laps      = length(laps);
    n_clust     = length(spk);
elseif strcmp(format,'view')
    fprintf('Using view format\n');
    [n_clust, n_laps] = size(spk);
else
    error('Unknown data structure');
end

if nargin<6 || isempty(events)
    events = cell(n_laps,1);
end
if nargin<7 || isempty(meta)
    meta = repmat(struct([]),n_laps,1);
end


% Extract spks when the rat is in the sections [section_range]
D = meta;

if bw == 0
    tics_per_bin = 1;
else
    tics_per_bin = bw*Fs;
end
if tics_per_bin < 1
    err('Oversampling or interpolation is not permitted');
end

for i_lap = 1:n_laps
    
    % lap information
    tic_lap      = laps(i_lap,:);
    duration_lap = tic_lap(2) - tic_lap(1) + 1;
    
    % bins for spikes
    n_bins       = ceil(duration_lap/tics_per_bin);
    if useFloats
        edges    = (0:n_bins)*bw;
    else
        edges    = (0:n_bins)*tics_per_bin; %linspace(1, t_lap, tics_per_bin);
    end

    % event timings in bins
    event_lap    = floor((events{i_lap} - tic_lap(1))/tics_per_bin) + 1;

    % metadata
    if isempty(pos)
        pos_lap  = [];
    else
        sel      = floor((0:n_bins-1)*tics_per_bin) + 1;
        pos_lap  = pos(sel,:);
    end
    
    
    % Collect data for neurons
    spikes_lap   = cell(n_clust,1);
    spk_count    = zeros(n_clust, n_bins);
    spk_freq     = zeros(n_clust, 1);
    if n_bins
        for i_clust=1:n_clust
            if strcmp(format,'hc5')
                %filtering was introduced because get_spikes only uses
                %lap start times and idx_lap(:) might differ
                idx              = spk{i_clust}>=tic_lap(1) & ...
                                   spk{i_clust}<=tic_lap(2);
                %align to the start of the section
                spikes_lap{i_clust}   = spk{i_clust}(idx) - tic_lap(1);
            elseif strcmp(format,'view')
                spikes_lap{i_clust}   = spk{i_clust,i_lap};
            end

            %convolve the spike counts with a gauss filter 100 ms
            %firing(cnt,:)    = Fs*conv(tmp, kernel, 'same');
            spk_count(i_clust, :) = histcounts(spikes_lap{i_clust}, edges);
            spk_freq(i_clust) = mean(spk_count(i_clust, :))/bw;

            if useRates
                spk_count(i_clust, :) = spk_count(i_clust, :)/bw;
            end
            if useSqrt
                spk_count(i_clust, :) = sqrt(spk_count(i_clust, :));
            end
            %NOTE: if you want to introduce time-incertainty instead of spatial
            %incertainty then yo need the explicit binary spike count not the
            %spike count
        end
    else
        D(i_lap).valid = false;
    end
    
    for i=1:nXtra
        % TODO: decimate
        varargout{i}{lap} = varargin{i}(tic_lap(1):tic_lap(2)); %#ok<AGROW>
    end
   
    D(i_lap).trialId            = i_lap;
    D(i_lap).spikes             = spikes_lap;
    D(i_lap).pos                = pos_lap;
    D(i_lap).events             = event_lap;
    D(i_lap).spike_count        = spk_count; %repmat(spk_count,1,2);
    D(i_lap).spike_freq         = spk_freq;
    D(i_lap).duration           = (tic_lap(2) - tic_lap(1))/Fs;
    D(i_lap).start              = tic_lap(1)/Fs;
    clear spikes *_lap tmp
end    


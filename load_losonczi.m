function [D, allowed_ch, model_trials] = load_losonczi(fn, settings)
% Load data from the passive viewing project and prepare it for GPFA. The
% variables have the following fields:
%    D is a 1 x n_trials struct:
%       spike_count (nChannels x n_bins)
%       start (s)
%       duration (s)
%       spikes (nChannels x 1) cell with spike times (s)
%       pos (empty)
%       events (1 x 2) lap start and end (bin_id)

%========================       Source data      ==========================
data            = load(fn);
nLaps         = length(data.transients);
Fs              = 8;
lapDuration     = [0];
events          = cell(1,nLaps);
durations       = [10,20,15,5,9];
lapEvents      = cumsum([0, durations]);
lapEvents      = [Fs*lapEvents(1:end-1)', Fs*lapEvents(2:end)'-1];

D = repmat(struct([]), nLaps);

for i_lap = 1:nLaps
    % TODO: make this more comprehensive, add transition D -> S -> R
    D(i_lap).trialId       = i_lap; %#ok<*SAGROW>
    D(i_lap).spikes        = [];
    D(i_lap).pos           = [];
    D(i_lap).events        = lapEvents;
    D(i_lap).spike_count   = data.transients{i_lap};
    D(i_lap).spike_freq    = mean(data.transients{i_lap},2)*Fs;
    D(i_lap).duration      = size(data.transients{i_lap},2)/Fs;
    D(i_lap).start         = lapDuration(i_lap)/Fs;
    D(i_lap).valid         = 1;
    lapDuration(i_lap+1)= lapDuration(i_lap) + size(data.transients{i_lap},2);
    events{i_lap}       = lapEvents;
end
totalDuration   = lapDuration(end);

nChannels         = length(data.rois);
allowed_ch      = ones(nChannels,1);
clear data
% String descriptions
Typetrial_tx    = {'Baseline', 'CS+', 'CS-'};
Typebehav_tx    = {'demotivated', 'fear', 'brave'};
Typeside_tx     = {'W+', 'W-'};


%%
% ========================================================================%
%==============   (1) Extract trials              ========================%
%=========================================================================%



%show one lap for debug purposes 
if settings.debug
    %D = extract_general(Fs, settings.bin_size, spk_clust, pos, ...
    %                    idx_lap, events, meta);
    figure(testTrial)
    raster(D(testTrial).spikes), hold on
    plot(90.*D(testTrial).speed./max(D(testTrial).speed),'k')
    plot(90.*D(testTrial).wh_speed./max(D(testTrial).wh_speed),'r')
end


                
% ========================================================================%
%============== (3) Segment the spike vectors     ========================%
%=========================================================================%


if settings.filterTrails
    train_laps         = filter_laps(D);
else
    train_laps         = true;
end

model_trials.all   = ones(nLaps,1);

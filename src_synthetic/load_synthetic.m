function [D, allowed_ch, model_trials] = load_synthetic(fn, settings)
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
data            = dlmread(fn,'',1,0);

RUN_pos         = dlmread(strrep(fn,'spike','pos'),'',0,0);
try
    state       = dlmread(strrep(fn,'spike','state'),'',0,0);
catch ME
    state       = [];
end
try
    SPW_pos     = dlmread(strrep(fn,'spike','posSPW'),'',0,0);
catch ME
    SPW_pos     = [];
end
pos             = [RUN_pos state SPW_pos];

%========================Paramteres and variables==========================
nLaps         = settings.n_trials;
Fs              = 100;
data(:,1)       = round(data(:,1)*Fs);
totalDuration   = max(data(:,1));

lapDuration     = round(linspace(0,totalDuration,nLaps+1));
idx_lap         = cell2mat(events);
idx_sec         = cell2mat(events);
nChannels         = max(data(:,2));
allowed_ch      = ones(nChannels,1);
spk_clust       = get_spikes(data(:,2), data(:,1));

TrialType       = num2cell(ones(1,nLaps));

meta            = repmat(struct('valid',true),nLaps,1);
[meta.type]     = TrialType{:};
for i_lap = 1:nLaps
    meta(i_lap).events = [lapDuration(i_lap)+1 lapDuration(i_lap+1)];
end

clear data
% String descriptions
Typetrial_tx    = {'free_run'};


%%
% ========================================================================%
%==============   (1) Extract trials              ========================%
%=========================================================================%

%show one lap for debug purposes 
if settings.debug
    D = extract_general(Fs, settings.bin_size, spk_clust, pos, ...
                    idx_lap, events, meta);

    figure(testTrial)
    raster(D(testTrial).spikes), hold on
    plot(90.*D(testTrial).speed./max(D(testTrial).speed),'k')
    plot(90.*D(testTrial).wh_speed./max(D(testTrial).wh_speed),'r')
end

% ========================================================================%
%============== (3) Segment the spike vectors     ========================%
%=========================================================================%

R = extract_general(Fs, settings.bin_size, spk_clust, pos, ...
                    idx_sec, events, meta);

if settings.filterTrails
    train_laps     = filter_laps(R);
else
    train_laps     = true;
end

model_trials.all   = ones(nLaps,1) & train_laps;


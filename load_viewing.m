function [D, allowed_ch, model_trials] = load_viewing(fn, settings)
% Load data from the passive viewing project and prepare it for GPFA. The
% variables have the following fields:
%    D is a 1 x n_trials struct:
%       spike_count (nChannels x n_bins)
%       start (s)
%       duration (s)
%       spikes (nChannels x 1) cell with spike times (s)
%       pos (empty)
%       events (1 x 2) lap start and end (bin_id)

%========================Paramteres and variables==========================
data            = load(fn);
project         = regexprep(fn,['.*/' settings.pattern],'$1');


spk_clust       = data.MUA;
[nChannels, nLaps] = size(data.MUA);
Fs              = 1000;

pos             = [];

% handle different paradigms
if isfield(data,'Images')
    % attention task
    TrialType = num2cell(data.Images);
else
    % passive viewing
    TrialType = num2cell(data.Cond);
end

clear data

% Extract spks when the rat is running in the sections [section_range]
lap_duration    = zeros(nLaps,1); % s

meta = repmat(struct('valid',true),nLaps,1);
codes = code_table_view();
digits = codes.(project);
[meta.type]     = TrialType{:};
%mydigits        = num2cell(digits([TrialType{:}]));
%[meta.digit]    = mydigits{:};
[meta.digit]    = num2var(digits([TrialType{:}]));

for i_lap = 1:nLaps
    lap_duration(i_lap) = max(spk_clust{i_lap});
    meta(i_lap).events  = [0, lap_duration(i_lap)];
end
idx_lap=[zeros(nLaps,1),lap_duration];
idx_sec=[zeros(nLaps,1),lap_duration];

% validate channels
fprintf('Validate channels\n');
D = get_binned_spikes(1, 1.0/Fs, spk_clust, pos, ...
                      idx_lap, meta, 'format', 'split');

n_bins = zeros(nLaps,1);
for i_lap = 1:nLaps
    n_bins(i_lap) = size(D(i_lap).spike_count,2);
end

sraster = zeros(nLaps,nChannels,max(n_bins));
for i_lap = 1:nLaps
    sraster(i_lap,1:end,1:n_bins(i_lap)) = D(i_lap).spike_count;
end
if settings.debug
    plot(squeeze(mean(sraster,1))');
end


if strcmp(settings.filterParametrization,'lowRate')
    channelFilter.maxTrialAvgTh = 0.10; % isisc369 has lower firing rates
    channelFilter.peakFirstRatioTh = 4;
    channelFilter.peakFirstDiffTh = 0.05;
elseif strcmp(settings.filterParametrization,'highVariance')        
    channelFilter.maxTrialAvgTh = 0.15;
    channelFilter.peakFirstRatioTh = 5;
    channelFilter.peakFirstDiffTh = 0.15;
elseif strcmp(settings.filterParametrization,'standard')
    channelFilter.maxTrialAvgTh = 0.15;
    channelFilter.peakFirstRatioTh = 4.7;
    channelFilter.peakFirstDiffTh = 0.07;
else
    error('Unknown filter parametrisation\n')
end            

% filterParametrization: the channel filter looks at three things: (i) the
% maximum of the firing rate shouldn't be too low, (ii) the ratio and (iii)
% the difference between the spontaneous activity and the transient peak
% shouldn't be too low. There are some predefined threshold sets I worked
% out for sessions I had, you might need to experiment with the values to
% accept the channels that look all right to you visually
trialAvgR = squeeze(mean(sraster,1))'; % trialLength x nChannel
maxOfTrialAvgPerChannel = max(trialAvgR); % this is the peak of the evoked transient 
firstOfEachTrial = squeeze(sraster(:,:,1)); % nTrials x nChannel    
trialAvgOfFirstPerChannel = mean(firstOfEachTrial); % this is the beginning of the trial
peakFirstDiff = maxOfTrialAvgPerChannel - trialAvgOfFirstPerChannel;
peakFirstRatio = maxOfTrialAvgPerChannel ./ trialAvgOfFirstPerChannel;                        

goodChannelsLogical = maxOfTrialAvgPerChannel > channelFilter.maxTrialAvgTh & ...
                      peakFirstRatio > channelFilter.peakFirstRatioTh & ...
                      peakFirstDiff > channelFilter.peakFirstDiffTh;
goodChannels        = find(goodChannelsLogical);

fprintf('%d ', goodChannels);
fprintf('\n');

allowed_ch          = goodChannelsLogical';


%%
% ========================================================================%
%==============   (1) Show trials                 ========================%
%=========================================================================%


%show one lap for debug purposes (TODO)
if settings.debug
    fprintf('Show spikes\n');
    D = get_binned_spikes(1, 1.0/Fs, spk_clust, pos, ...
                          idx_lap, meta, 'format', 'split');
    figure(testTrial)
    raster(D(testTrial).spikes), hold on
    plot(90.*D(testTrial).speed./max(D(testTrial).speed),'k')
    plot(90.*D(testTrial).wh_speed./max(D(testTrial).wh_speed),'r')
end

train_laps = true;

fprintf('Prepare data\n');
D = get_binned_spikes(1, settings.bin_size, spk_clust, pos, ...
                      idx_sec, meta, 'format', 'split');
                
model_trials.all       = train_laps & ones(nLaps,1);
model_digits.all       = -1;

% collect trials with same label
Digits = unique([D.type]);
%descr = repmat([],len(Digits))
for type = Digits
    %descr(type).type = sprintf('%02d',type);
    name = sprintf('num%02d',type);
    model_trials.(name) = train_laps & ([D.type]' == type);
    model_digits.(name) = digits(type);
end

% collect trials with overrepresented symbol
nNormalDigit = 10;
nOverrep = 4;
nExtraDigit = floor((length(unique([D.type]))-nNormalDigit)/nOverrep);
for extra = 1:nExtraDigit
    name = sprintf('ext%02d',extra);
    extra_laps = false;
    for type = nNormalDigit+(extra-1)*nOverrep+1:nNormalDigit+extra*nOverrep
        extra_laps = extra_laps | (train_laps & ([D.type]' == type));
    end
    model_trials.(name) = extra_laps;
    model_digits.(name) = digits(nNormalDigit+extra*nOverrep);
end

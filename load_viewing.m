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
filterFs        = 1000;

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
[codes, channels] = code_table_view();
type2digit = codes.(project);
[meta.type]     = TrialType{:};
%mydigits        = num2cell(digits([TrialType{:}]));
%[meta.digit]    = mydigits{:};
[meta.digit]    = num2var(type2digit([TrialType{:}]));

for i_lap = 1:nLaps
    lap_duration(i_lap) = max(max([spk_clust{:,i_lap}])); % normally only one max needed
end
max_duration = max(lap_duration);
min_duration = min(lap_duration);

lap_duration(:) = min_duration;

idx_lap=[zeros(nLaps,1),lap_duration];
idx_sec=[zeros(nLaps,1),lap_duration];

on_trans  = [0.4 0.55];
off_trans = [1.2 1.35];

for i_lap = 1:nLaps
    meta(i_lap).events  = [0, on_trans(1);
                           on_trans;
                           on_trans(2), off_trans(1);
                           off_trans;
                           off_trans(2), lap_duration(i_lap)];
    try
        s_in = str2double(settings.section.in);
    catch
        s_in = settings.section.in;
    end
    try
        s_out = str2double(settings.section.out);
    catch
        s_out = settings.section.out;
    end
    time_in  = meta(i_lap).events(s_in,1);
    time_out = meta(i_lap).events(s_out,2);
    idx_sec(i_lap,:) = [min(time_in) max(time_out)];
end



% auto detect or use given Filter
if strcmp(settings.filterParametrization,'auto')
    if strncmp(project,'isis',4)
        filterParametrization = 'lowRate';
    else
        filterParametrization = 'standard';
    end
else
    filterParametrization = settings.filterParametrization;
end

if strcmp(filterParametrization,'lowRate')
    channelFilter.maxTrialAvgTh = 0.10; % isisc369 has lower firing rates
    channelFilter.peakFirstRatioTh = 4;
    channelFilter.peakFirstDiffTh = 0.05;
elseif strcmp(filterParametrization,'highVariance')        
    channelFilter.maxTrialAvgTh = 0.15;
    channelFilter.peakFirstRatioTh = 5;
    channelFilter.peakFirstDiffTh = 0.15;
elseif strcmp(filterParametrization,'standard')
    channelFilter.maxTrialAvgTh = 0.15;
    channelFilter.peakFirstRatioTh = 4.7;
    channelFilter.peakFirstDiffTh = 0.07;
else
    error('Unknown filter parametrisation\n')
end            

if settings.channelsFromDB
    allowed_ch      = channels.(project);
    allowed_ch      = allowed_ch(:);
else
    % validate channels (at pre-determined bin size)
    fprintf('Validate channels\n');
    D = get_binned_spikes(1, 1.0/filterFs, spk_clust, pos, ...
                          idx_lap, meta, 'format', 'split');

    n_bins = zeros(nLaps,1);
    for i_lap = 1:nLaps
        n_bins(i_lap) = size(D(i_lap).spike_count,2);
    end

    
    % data for filtering
    sraster = zeros(nLaps,nChannels,max(n_bins));
    for i_lap = 1:nLaps
        sraster(i_lap,1:end,1:n_bins(i_lap)) = D(i_lap).spike_count;
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
    
    % filterParametrization: the channel filter looks at three things: (i) the
    % maximum of the firing rate shouldn't be too low, (ii) the ratio of the
    % spontaneous activity and the transient peak measured from a baseline
    % shouldn't be too low. There are some predefined threshold sets I worked
    % out for sessions I had, you might need to experiment with the values to
    % accept the channels that look all right to you visually
    trialAvgR = squeeze(mean(sraster,1))'; % trialLength x nChannel
    %trialStdR = squeeze(std(trialAvgR,1))'; % trialLength x nChannel
    q = quantile(trialAvgR,[0.25,0.75,0.995],1);
    maxOfTrialAvgPerChannel = q(3,:); % this is the peak of the evoked transient 
    refLevelPerChannel = q(1,:); % this is the baseline of the trial
    stdLevelPerChannel = q(2,:); % this is the standard activity of the trial
    peakDiff = maxOfTrialAvgPerChannel - refLevelPerChannel;
    peakRatio = peakDiff ./ (stdLevelPerChannel-refLevelPerChannel);                        

    goodChannelsLogical = maxOfTrialAvgPerChannel > channelFilter.maxTrialAvgTh & ...
                          peakRatio > (channelFilter.peakFirstRatioTh-1); %& ...
                          %peakFirstDiff > channelFilter.peakFirstDiffTh;
    goodChannels        = find(goodChannelsLogical);
    fprintf('%d ', goodChannels);
    fprintf('\n');
    
    if settings.debug
        fprintf('Show spike rates\n');
        cha = squeeze(mean(sraster,1));
        tmpx = 1:size(cha,2);
        colors = { 'r', [0 0.5 0] };
        sRows = 2; sCols = 4; sChannels = 2;
        nSubplots = sRows * sCols * sChannels;
        for iFig = 1:ceil(nChannels/nSubplots);
        figure(iFig);
        for iRow = 1:sRows
        for iCol = 1:sCols
            labels = cell(sChannels,1);
            iSubplot = (iRow-1)*sCols + iCol;
            subplot(sRows,sCols,iSubplot)
            for iLine = 1:sChannels
                iChannel = (iFig-1)*nSubplots + (iSubplot-1)*sChannels + iLine;
                isGood = goodChannelsLogical(iChannel);
                %plot(tmpx,cha(iChannel,:),'Marker','.',...
                %    'color',colors{isGood+1}), hold on
                scatter(tmpx,cha(iChannel,:),[],colors{isGood+1},...
                    'Marker','.'), hold on
                labels{iLine} = sprintf('Ch %d',iChannel);                    
            end
            scatter([on_trans off_trans]*filterFs,ones(4,1)*0.1,[],'b');
            labels{sChannels+1} = 'events';
            xlabel('Time (ms)');
            ylabel('Spike count');
            legend(labels);
        end
        end
        end
    end
    
    allowed_ch      = goodChannelsLogical';
end

% TODO: display channels used

%%
% ========================================================================%
%==============   (1) Show trials                 ========================%
%=========================================================================%


%show one lap for debug purposes (TODO)
if settings.debug
    fprintf('Show spikes\n');
    D = get_binned_spikes(1, 1.0/filterFs, spk_clust, pos, ...
                          idx_lap, meta, 'format', 'split');
    figure()
    raster(D(settings.testTrial).spikes), hold on
    %plot(90.*D(settings.testTrial).speed./max(D(testTrial).speed),'k')
    %plot(90.*D(settings.testTrial).wh_speed./max(D(testTrial).wh_speed),'r')
end

train_laps = true;

% prepare output (at user-requested bin size)
fprintf('Prepare data\n');
D = get_binned_spikes(1, settings.bin_size, spk_clust, pos, ...
                      idx_sec, meta, 'format', 'split');
                
model_trials.all       = train_laps & ones(nLaps,1);
model_trials.onefold   = train_laps & ones(nLaps,1);
%model_digits.all       = -1;

% collect trials with same label (largest label corresponds to blank trial)
Types = unique([D.type]);

% trials representing a digit
name = 'digit';
model_trials.(name) = train_laps & ([D.type]' ~= max(Types));

% collect trials representing a digit
name = 'digit';
model_trials.(name) = train_laps & ([D.type]' ~= max(Types));

% collect trials with same label
for type = Types
    name = sprintf('num%02d',type);
    model_trials.(name) = train_laps & ([D.type]' == type);
    %model_digits.(name) = type2digit(type);
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
    %model_digits.(name) = type2digit(nNormalDigit+extra*nOverrep);
end

% collect trials for control groups: digits 2..5 or digit 6..9
nNormalDigit = 2;
nOverrep = 4;
nExtraDigit = 2;
for extra = 1:nExtraDigit
    name = sprintf('grp%02d',extra);
    extra_laps = false;
    for type = nNormalDigit+(extra-1)*nOverrep+1:nNormalDigit+extra*nOverrep
        extra_laps = extra_laps | (train_laps & ([D.type]' == type));
    end
    model_trials.(name) = extra_laps;
    %model_digits.(name) = type2digit(nNormalDigit+extra*nOverrep);
end

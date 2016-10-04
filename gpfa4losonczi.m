%GPFA4SYNTHETICDIMENSIONALITY This script reads the fitted GPFA models and
%plots the log likelihood of the different latent dimensionality.
%
%        DESCRIPTION: This script can be used for dimesionality estimation.
%Version 1.0 Marcell Stippinger


clc, close all; %clear all;

workpath        = '~/marcell/napwigner/work/';
name_save_file  = 'trainedGPFA';

if ~exist('settings_file','var')
    settings_file = 'gpfa4losoncziSettings.m';
end

run(settings_file);


%========================       Source data      ==========================

[files, roots, animals] = get_matFiles(settings.basepath,settings.pattern);
fprintf('\nSelecting %d: %s\n\n',settings.animal,files{settings.animal});

project         = regexprep(animals{settings.animal},settings.pattern,'$1');
savepath        = [workpath project];
fn              = [project '_' ...
                   name_save_file '_' settings.namevar '_' ...
                   sprintf('%02d',settings.zDim) '.mat'];
if ~exist(savepath,'dir')
    mkdir(savepath);
end

trained         = false;



%========================Paramteres and variables==========================
data            = load(files{settings.animal});
nLaps         = length(data.transients);
Fs              = 8;
lapDuration     = [0];
events          = cell(1,nLaps);
durations       = [10,20,15,5,9];
lapEvents      = cumsum([0, durations]);
lapEvents      = [Fs*lapEvents(1:end-1)', Fs*lapEvents(2:end)'-1];

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
pos             = zeros(totalDuration,1);
nChannels         = length(data.rois);
inChannels   = ones(nChannels,1);
clear data
% String descriptions
Typetrial_tx    = {'Baseline', 'CS+', 'CS-'};
Typebehav_tx    = {'demotivated', 'fear', 'brave'};
Typeside_tx     = {'W+', 'W-'};
% GPFA training
showpred        = false; %show predicted firing rate
testTrial        = 10;


laps.all        = ones(nLaps,1);


%%
% ========================================================================%
%==============   (1) Extract trials              ========================%
%=========================================================================%

%D = extract_general(Fs, settings.bin_size, spk_clust, pos, ...
%                    idx_lap, events, meta);


%show one lap for debug purposes 
if settings.debug
    figure(testTrial)
    raster(D(testTrial).spikes), hold on
    plot(90.*D(testTrial).speed./max(D(testTrial).speed),'k')
    plot(90.*D(testTrial).wh_speed./max(D(testTrial).wh_speed),'r')
end

% ========================================================================%
%==============  (2)  Extract Running Sections    ========================%
%=========================================================================%

%S = get_section(D, in, out, debug, namevar); %lap#1: sensor errors
%S = extract_general(Fs, settings.bin_size, spk_clust, pos, ...
%                    idx_sec, events, meta);
S = D;

                
% ========================================================================%
%============== (3) Segment the spike vectors     ========================%
%=========================================================================%

cluster.MeanFiringRate = mean([S([S.valid]).spike_freq],2);
cluster.MedianFiringRate = median([S([S.valid]).spike_freq],2);

gpfaChannels = (settings.minFiringRate<cluster.MeanFiringRate) & ...
    (settings.medianFiringRate<cluster.MedianFiringRate) & ...
    (inChannels);
fprintf('%d neurons fulfil the criteria for GPFA\n',sum(gpfaChannels));


%load run model and keep the same neurons
if isCommandWindowOpen() && exist([savepath fn],'file') && ~settings.train
    fprintf('Will load from %s\n', [savepath fn]);
    info = load([savepath fn], 'M', 'laps', 'R', 'gpfaChannels', 'settings');
    gpfaChannels = info.gpfaChannels;
    fprintf('Successfully loaded file, you may skip Section (4).\n');
end

%R = extract_general(Fs, settings.bin_size, spk_clust, pos, ...
%                    idx_sec, events, meta);
R = S;

if settings.filterTrails
    train_laps         = filter_laps(R);
else
    train_laps         = true;
end


%%
% ========================================================================%
%============== (4)         Train GPFA            ========================%
%=========================================================================%
try
    fields             = fieldnames(laps);
    for i_model = 1:numel(laps)
        field          = fields{i_model};
        M.(field)      = trainGPFA(R, gpfaChannels, train_laps & laps.(field), ...
                                   settings.zDim, showpred, settings.nFolds, ...
                                   'max_length',settings.maxLength,...
                                   'spike_field','spike_count');
    end
    
    trained = true;
catch ME
    fprintf('Error training GPFA for %s: %s\n', field, ME.identifier);
    rethrow(ME);
end


% ========================================================================%
%============== (5)           Saved data          ========================%
%=========================================================================%

if trained
    fprintf('Will save at %s\n', [savepath fn]);
    save([savepath fn], 'M', 'laps', 'R', 'gpfaChannels', 'settings');
    trained = false; %#ok<NASGU>
    exit;
else
    M = info.M; %#ok<UNRCH>
end


%%
% ========================================================================%
%============== (6)    Show Neural Trajectories   ========================%
%=========================================================================%

%colors = cgergo.cExpon([2 3 1], :);
linecol = hsv(4);
labels = [R.type];
Xorth = show_latent({M.all}, R, linecol, labels, Typetrial_tx);
saveas(gcf,[savepath strrep(fn,'mat','pdf')],'pdf');
saveas(gcf,[savepath strrep(fn,'mat','fig')],'fig');

if debug
    %sel = find(Tstate);
    [Xorth, Vorth] = show_latent({M.all}, R, linecol, labels, Typetrial_tx, Tstate);
    fig_export(gcf,[savepath strrep(fn,'.mat','_annotated')],240,150);
    T = length(Xorth{1});
    time_grid = (1:T)*settings.bin_size;
    markers = { 'bo', 'rx' };
    figure();
    ax1 = subplot(2,1,1);
    plot(time_grid, Xorth{1}');
    hold on
    xlabel('Time (s)');
    ylabel('\itx_i');
    for i = 1:max(Tstate)
        sel = find(Tstate==i);
        plot(time_grid(sel),zeros(size(sel)),markers{i});
    end
    hold off;
    ax2 = subplot(2,1,2);
    plot(time_grid, Vorth{1}');
    hold on;
    xlabel('Time (s)');
    ylabel('{\itv_i}, |{\bfv}|');
    v_scalar = sqrt(sum(abs(Vorth{1}).^2,1));
    plot(time_grid, v_scalar, 'k');
    for i = 1:max(Tstate)
        sel = find(Tstate==i);
        plot(time_grid(sel),zeros(size(sel)),markers{i});
    end
    hold off;
    linkaxes([ax1,ax2],'x');
    fig_export(gcf,[savepath strrep(fn,'.mat','_timetraj')],200,100);
    clear markers sel;
end  
if ~isCommandWindowOpen()
    exit;
end

%%
%=========================================================================%
%=========(7) Compare mean spike counts              =====================%
%=========================================================================%
figure(7)
set(gcf,'position',[100 100 500*1.62 500],'color','w')
%plot(mean([R(laps.all).y],2),'r','displayname','firintg rate')
plot(mean([S(laps.all).spike_train],2)*Fs,'r','displayname','firintg rate');
hold on
plot(gpfaChannels,'bx','displayname','firintg rate');
hold off
ylabel('Average firing rate')
xlabel('Cell No.')
set(gca,'fontsize',14)
savefig()
%=========================================================================%
%=========(8a) Compute loglike P(run|model_run)      =====================%
%=========================================================================%

%load([roots{settings.animal} name_save_file])
%R           = shufftime(R);
%Classification stats of P(run events|model) 
models      = {M.all};
clear cmp;
scaleK = 1;
scaleRate = 1;
Xtats       = classGPFA(R, models,'scaleK',scaleK,'scaleRate',scaleRate);
cm          = [Xtats.conf_matrix];
fprintf('scaleK: %2.2f%, scaleRate: %2.2f%\n', scaleK, scaleRate)
fprintf('hitA: %2.2f%%, hitB: %2.2f%%\n', 100*cm(1,1),100*cm(2,2));
LLsepar(scaleK,scaleRate) = Xtats;
save([savepath 'Scaling_study.mat'],'cmp');

%show likelihood given the models
% plot show likelihood given the models
label.title = 'P(run_j | Models_{left run, right run})';
label.modelA = 'Left alt.';
label.modelB = 'Right alt.';
label.xaxis = 'j';
label.yaxis = 'P(run_j| Models_{left run, right run})';
compareLogLike(R, Xtats, label)

%XY plot
cgergo = load('colors');

label.title = 'LDA classifier';
label.xaxis = 'P(run_j|Model_{left run})';
label.yaxis = 'P(run_j|Model_{right run})';
LDAclass(Xtats, label, cgergo.cExpon([2 3], :))

%% =======================================================================%
%=========(8b) Compute loglike P(window|model_run) to detect SPWS  =======%
%=========================================================================%

scaleK=15;
scaleRate=5;
models      = {M.all};
clear LLsepar;
for win = 1:2:31
    Ztats       = gpfaConsistency(R, models,'scaleK',scaleK,'scaleRate',scaleRate,'width',win);
    tmp         = plot_consistency(events,Ztats,R,Fs,settings,...
                                   Tstate,win);
    LLsepar(win)= tmp;
    fig_export(gcf,[savepath strrep(fn,'.mat',sprintf('_win%02d_K%d_R%d',win,scaleK,scaleRate))],300,100);
end
save([savepath sprintf('SPW_sensitivity_K%d_R%d.mat',scaleK,scaleRate)],'LLsepar');

fig = figure();
hold on;
absc = ~cellfun(@isempty,struct2cell(LLsepar')');
absc = find(absc(:,1));
xlabel('GPFA window width (bin)');
ylabel('log Likelihood');

varname = { 'all', 'spk', 'spw', 'replay', 'incons' };
dispname = { 'All activity', 'Normal spiking', 'Sharp wave', 'Replay', 'Inconsistent' };
linecol = {'y', 'k', 'c', 'b', 'r' };
markers = {'s', '.', '+', 'o', 'x'};

for i = [1 2 4 5]
    col = linecol{i};
    errorbar(absc,[LLsepar.([varname{i} '_mean'])],[LLsepar.([varname{i} '_stdev'])],...
        [col '.'],'Marker','none');
    h(i) = errorbar(nan,nan,nan,[col markers{i}],'DisplayName',dispname{i});
    quan = cell2mat({LLsepar.([varname{i} '_quan'])}');
    plot(absc,quan(:,1),[col ':'],absc,quan(:,2),[col '-.'],absc,quan(:,3),...
        [col markers{i} '--'],absc,quan(:,4),[col '-.'],absc,quan(:,5),[col ':']);
end

hold off;
legend(gca,h([1 2 4 5]),'Location','southeast');
xlim([0,max(absc)+1]);
ylim([min([LLsepar.incons_mean]),0]);

fig_export(fig,[savepath strrep(fn,'.mat',sprintf('_wins_K%d_R%d',scaleK,scaleRate))],160,120);

%[Rs, Malt.all] = normalizedatanmodel(R, M.all);
%Zalt        = trajGPFAconsistency(R, {Malt.all});
%plot_consistency(events,Zalt,R,Fs,settings,state);



%% =======================================================================%
%=========(9) Compute loglike P(wheel|run_model)     =====================%
%=========================================================================%
%#TODO: Separate this part v in a different script

in              = 'wheel';
out             = 'wheel';
maxTime         = 6;
allTrials       = true; %use all trials of running to test since they are 
                        %all unseen to the wheel model

S = get_section(D, in, out, debug, namevar); %lap#1: sensor errors 
W = segment(S, bin_size, Fs, gpfaChannels,...
                [namevar '_spike_train'], maxTime);
W = filter_laps(W);
W = W(randperm(length(W))); 

models      = {M_left, M_right};
Xtats       = classGPFA(W, models,[],allTrials);
cm          = [Xtats.conf_matrix];
fprintf('hitA: %2.2f%%, hitB: %2.2f%%\n', 100*cm(1,1),100*cm(2,2))

% plot show likelihood given the models
label.title = 'P(wheel_j | run model)';
label.modelA = 'Run rigth alt.';
label.modelB = 'Run left alt.';
label.xaxis = 'j';
label.yaxis = 'P(wheel_j|run model)';
compareLogLike(R, Xtats, label)

%XY plot
label.title = 'Class. with Fisher Disc.';
label.xaxis = 'P(wheel_j|run right)';
label.yaxis = 'P(wheel_j|run left)';
LDAclass(Xtats, label)     
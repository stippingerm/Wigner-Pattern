%BRANCH2_CLEANED This script contains a modularized version of the analysis
%        included in the script branch2d.m, that process the HC-5 database.
%
%        DESCRIPTION: This script carried out most of the analysis in the files
%        branch2.m using functions. See branch2.m for further details.
%Version 1.0 Marcell Stippinger


clc, close all; %clear all;
workpath        = '~/marcell/napwigner/work/';
name_save_file  = 'trainedGPFA';

if ~exist('settings_file','var')
    settings_file = 'gpfa4syntheticSectionSettings.m';
end

run(settings_file);

%project         = strrep(animals{settings.animal},'.dat','');
%savepath        = [workpath project '/'];
%fn              = [project '_' ...
%                   name_save_file '_' sprintf('%02d',settings.zDim) '.mat'];

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
data            = dlmread(files{settings.animal},'',1,0);
nLaps         = 12;
Fs              = 100;
data(:,1)       = round(data(:,1)*Fs);
totalDuration   = max(data(:,1));
lapDuration     = round(linspace(0,totalDuration,nLaps+1));
events          = cell(nLaps,1);
for n = 1:nLaps
events{n}       = [lapDuration(n)+1 lapDuration(n+1)];
end
idx_lap         = cell2mat(events);
idx_sec         = cell2mat(events);
pos             = dlmread(strrep(files{settings.animal},'spike','pos'),'',0,0);
try
    state       = dlmread(strrep(files{settings.animal},'spike','state'),'',0,0);
    SPW_X       = dlmread(strrep(files{settings.animal},'spike','posSPW'),'',0,0);
catch ME
    state       = zeros(totalDuration,1);
    SPW_X       = zeros(totalDuration,size(pos,2));
end
pos             = [pos state SPW_X];
nChannels         = max(data(:,2));
inChannels   = ones(nChannels,1);
spk_clust       = get_spikes(data(:,2), data(:,1));
meta = repmat(struct('valid',true),nLaps,1);

TrialType       = ones(1,nLaps);
BehavType       = ones(1,nLaps) .* (1+1);
clear data
% String descriptions
Typetrial_tx    = {'free_run'};
Typebehav_tx    = {'first', 'regular', 'uncertain'};
Typeside_tx     = {'none'};
% GPFA training
showpred        = false; %show predicted firing rate
testTrial        = 10;


laps.all        = select_laps(BehavType, TrialType, settings.namevar);



%%
% ========================================================================%
%==============   (1) Extract trials              ========================%
%=========================================================================%

D = extract_general(Fs, settings.bin_size, spk_clust, pos, ...
                    idx_lap, events, meta);

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
S = extract_general(Fs, settings.bin_size, spk_clust, pos, ...
                    idx_sec, events, meta);


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

R = extract_general(Fs, settings.bin_size, spk_clust, pos, ...
                    idx_sec, events, meta);

if settings.filterTrails
    train_laps         = filter_laps(R);
else
    train_laps         = true;
end

%Tstate = (2*(cell2mat(Rstate')>0) - (cell2mat(Rstate') & cell2mat(Rcons')));


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

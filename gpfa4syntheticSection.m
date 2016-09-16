%BRANCH2_CLEANED This script contains a modularized version of the analysis
%        included in the script branch2d.m, that process the HC-5 database.
%
%        DESCRIPTION: This script carried out most of the analysis in the files
%        branch2.m using functions. See branch2.m for further details.
%Version 1.0 Marcell Stippinger


clc, close all; %clear all;
run('gpfa4syntheticSectionSettings.m');

basepath        = '~/marcell/_Data_ubi_hpc/';
workpath        = '~/marcell/napwigner/work/';
[files, roots, animals] = get_matFiles(basepath,'spike_.*\.dat');


%========================Paramteres and variables==========================
fprintf('\nSelecting %d: %s\n\n',settings.animal,files{settings.animal});
data            = dlmread(files{settings.animal},'',1,0);
%mazesect        = data.Laps.MazeSection;
numLaps         = 12;
Fs              = 100;
data(:,1)       = round(data(:,1)*Fs);
totalDuration   = max(data(:,1));
lapDuration     = round(linspace(0,totalDuration,numLaps+1));
events          = cell(1,numLaps);
for n = 1:numLaps
events{n}(:,1)  = ones(13,1)*lapDuration(n)+1;
events{n}(:,2)  = ones(13,1)*lapDuration(n+1);
end
X               = dlmread(strrep(files{settings.animal},'spike','pos'),'',0,0);
Y               = zeros(totalDuration,size(X,2));
try
    state       = dlmread(strrep(files{settings.animal},'spike','state'),'',0,0);
    SPW_X       = dlmread(strrep(files{settings.animal},'spike','posSPW'),'',0,0);
catch ME
    state       = zeros(totalDuration,1);
    SPW_X       = zeros(totalDuration,size(X,2));
end
%eeg             = data.Track.eeg;
speed           = zeros(totalDuration,1);
wh_speed        = ones(totalDuration,1);
n_cells         = max(data(:,2));
isIntern        = zeros(n_cells,1);
spk_clust       = get_spikes(data(:,2), data(:,1));
n_pyrs          = sum(isIntern==0);
TrialType       = ones(1,numLaps);
BehavType       = ones(1,numLaps) .* (1+1);
clear data
% String descriptions
Typetrial_tx    = {'free_run'};
Typebehav_tx    = {'first', 'regular', 'uncertain'};
Typeside_tx     = {'none'};
% GPFA training
showpred        = false; %show predicted firing rate
train_split     = false; %train GPFA on left/right separately?
name_save_file  = 'trainedGPFA';
test_lap        = 10;
trained         = false;


project         = strrep(animals{settings.animal},'.dat','');
savepath        = [workpath project '/'];
fn              = [project '_' ...
                   name_save_file '_' sprintf('%02d',settings.zDim) '.mat'];
if ~exist(savepath,'dir')
    mkdir(savepath);
end

%%
% ========================================================================%
%==============   (1) Extract trials              ========================%
%=========================================================================%

D = extract_laps(Fs, spk_clust, ~isIntern, events, ...
                 struct('in','all','out','all'), TrialType, BehavType, ...
                 X, Y, speed, wh_speed);

%show one lap for debug purposes 
if settings.debug
    figure(test_lap)
    raster(D(test_lap).spikes), hold on
    plot(90.*D(test_lap).speed./max(D(test_lap).speed),'k')
    plot(90.*D(test_lap).wh_speed./max(D(test_lap).wh_speed),'r')
end

% ========================================================================%
%==============  (2)  Extract Running Sections    ========================%
%=========================================================================%

%S = get_section(D, in, out, debug, namevar); %lap#1: sensor errors
[S, Sstate, Scons, SSPW_X] = extract_laps(Fs, spk_clust, ~isIntern, events, ...
                settings.section, TrialType, BehavType, ...
                X, Y, speed, wh_speed, state, SPW_X<4, SPW_X);

% ========================================================================%
%============== (3) Segment the spike vectors     ========================%
%=========================================================================%
%load run model and keep the same neurons
if isCommandWindowOpen() && exist([savepath fn],'file') && ~settings.train
    fprintf('Will load from %s\n', [savepath fn]);
    info = load([savepath fn], 'M', 'laps', 'R', 'keep_neurons', 'settings');
    keep_neurons = info.keep_neurons;
    M = info.M;
    fprintf('Successfully loaded file, you may skip Sections (4)-(5).\n');
else
    keep_neurons = 1;
end

[R, keep_neurons, Rstate, Rcons, RSPW_X] = segment(S, 'spike_train', settings.bin_size, Fs, ...
                                 keep_neurons, settings.min_firing, settings.maxTime, ...
                                 Sstate, Scons, SSPW_X);
                             
Tstate = (2*(cell2mat(Rstate')>0) - (cell2mat(Rstate') & cell2mat(Rcons')));

laps.all               = select_laps(BehavType, TrialType, settings.namevar);
laps.left              = select_laps(BehavType, TrialType, settings.namevar, 1);
laps.right             = select_laps(BehavType, TrialType, settings.namevar, 2);


%%
% ========================================================================%
%============== (4)         Train GPFA            ========================%
%=========================================================================%
try
    clear M
    M.all                  = trainGPFA(R, laps.all, settings.zDim, showpred, ...
                                       settings.n_folds,'max_length',settings.maxLength);

    if train_split
        if settings.filterTrails
            keep_laps      = filter_laps(R(laps.left));
            laps.left      = laps.left(keep_laps);
            keep_laps      = filter_laps(R(laps.right),'bins');
            laps.right     = laps.right(keep_laps);
        end

        M.left             = trainGPFA(R, laps.left, settings.zDim, showpred, ...
                                       settings.n_folds,'max_length',settings.maxLength);
        M.right            = trainGPFA(R, laps.right, settings.zDim, showpred, ...
                                       settings.n_folds,'max_length',settings.maxLength);
    end
    trained = true;
catch ME
    fprintf('Error training GPFA: %s\n', ME.identifier);
    rethrow(ME);
end


% ========================================================================%
%============== (5)           Saved data          ========================%
%=========================================================================%

if trained
    fprintf('Will save at %s\n', [savepath fn]);
    save([savepath fn], 'M', 'laps', 'R', 'keep_neurons', 'settings');
    trained = false; %#ok<NASGU>
    %exit;
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
plot(keep_neurons,'bx','displayname','firintg rate');
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
W = segment(S, bin_size, Fs, keep_neurons,...
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
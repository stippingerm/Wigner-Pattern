%BRANCH2_CLEANED This script contains a modularized version of the analysis
%        included in the script branch2d.m, that process the HC-5 database.
%
%        DESCRIPTION: This script carried out most of the analysis in the files
%        branch2.m using functions. See branch2.m for further details.
%Version 1.0 Ruben Pinzon@2015


clc, close all; %clear all;

workpath        = '~/marcell/napwigner/work/';
name_save_file  = 'trainedGPFA';

if ~exist('settings_file','var')
    settings_file = 'gpfa4runSectionSettings.m';
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
mazesect        = data.Laps.MazeSection;
events          = data.Par.MazeSectEnterLeft;
Fs              = data.Par.SamplingFrequency;
pos             = cat(2,data.Track.X,data.Track.Y,...
                        data.Track.speed,data.Laps.WhlSpeedCW);
%eeg             = data.Track.eeg;
wh_speed        = data.Laps.WhlSpeedCW;
isIntern        = data.Clu.isIntern;
numLaps         = length(events);
spk_clust       = get_spikes(data.Spike.totclu, data.Spike.res);
TrialType       = num2cell(data.Par.TrialType);
BehavType       = num2cell(data.Par.BehavType+1);
clear data
% String descriptions
Typetrial_tx    = {'left', 'right', 'errorLeft', 'errorRight'};
Typebehav_tx    = {'first', 'regular', 'uncertain'};
Typeside_tx     = {'left', 'right', 'right', 'left'};
% GPFA training
showpred        = false; %show predicted firing rate
test_lap        = 10;
side_select     = [1 2 2 1];

allowed_clust   = settings.interneuron_allowed | isIntern(:);

% Extract spks when the rat is running in the sections [section_range]
idx_lap=zeros(numLaps,2);
idx_sec=zeros(numLaps,2);
meta = repmat(struct('valid',true),numLaps,1);
[meta.type]     = TrialType{:};
[meta.behav]    = BehavType{:};
[meta.side]     = num2var(side_select(cell2mat(TrialType)));

for i_lap = 1:numLaps
    
    % in some rare cases both left and right sections are visited
    % but non-visited section have entering and leaving time "0"
    [sect_in,  time_in]  = get_section_id('all', events{i_lap}(:,1));
    [sect_out, time_out] = get_section_id('all', events{i_lap}(:,2));
    idx_lap(i_lap,:) = [min(time_in), max(time_out)];
    [sect_in,  time_in]  = get_section_id(settings.section.in, events{i_lap}(:,1));
    [sect_out, time_out] = get_section_id(settings.section.out, events{i_lap}(:,2));
    idx_sec(i_lap,:) = [min(time_in), max(time_out)];
    if sect_in == 13
        idx_sec(i_lap,:) = get_wheel_running(wh_speed, idx_sec(i_lap,:));
        if idx_sec(i_lap,1) >= idx_sec(i_lap,2)
            fprintf('Skipped lap %d without wheel run\n',i_lap);
        end
    end
end


laps.all               = select_laps([meta.behav], [meta.type], settings.namevar);
laps.left              = select_laps([meta.behav], [meta.type], settings.namevar, 1);
laps.right             = select_laps([meta.behav], [meta.type], settings.namevar, 2);

%%
% ========================================================================%
%==============   (1) Extract trials              ========================%
%=========================================================================%

D = extract_general(Fs, settings.bin_size, spk_clust, pos, ...
                    idx_lap, events, meta);

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

%lap#1: sensor errors
S = extract_general(Fs, 1.0/Fs, spk_clust, pos, ...
                    idx_sec, events, meta);

% ========================================================================%
%============== (3) Segment the spike vectors     ========================%
%=========================================================================%

cluster.MeanFiringRate = mean([S([S.valid]).spike_freq],2);
cluster.MedianFiringRate = median([S([S.valid]).spike_freq],2);

keep_neurons = (settings.min_firing<cluster.MeanFiringRate) & ...
    (settings.median_firing<cluster.MedianFiringRate) & ...
    (allowed_clust);
fprintf('%d neurons fulfil the criteria for GPFA\n',sum(keep_neurons));


%load run model and keep the same neurons
if isCommandWindowOpen() && exist([savepath fn],'file') && ~settings.train
    fprintf('Will load from %s\n', [savepath fn]);
    info = load([savepath fn], 'M', 'laps', 'R', 'keep_neurons', 'settings');
    keep_neurons = info.keep_neurons;
    fprintf('Successfully loaded file, you may skip Section (4).\n');
end
    
R = extract_general(Fs, settings.bin_size, spk_clust, pos, ...
                    idx_sec, events, meta);

if settings.filterTrails
    train_laps         = filter_laps(R);
else
    train_laps         = true;
end

% FIXME: put keep_neurons in reshape_laps
% also deal with field names spk_count -> y and duaration -> T

%%
% ========================================================================%
%============== (4)         Train GPFA            ========================%
%=========================================================================%
try
    clear M
    fields             = fieldnames(laps);
    for i_model = 1:numel(laps)
        field          = fields{i_model};
        M.(field)      = trainGPFA(R, keep_neurons, train_laps & laps.(field), ...
                                   settings.zDim, showpred, settings.n_folds, ...
                                   'max_length',settings.maxLength,...
                                   'spike_field','spike_count');
    end
    
    trained = true;
catch ME
    fprintf('Error training GPFA for %s: %s\n', field, ME.identifier);
    rethrow(ME);
end

%%
% ========================================================================%
%============== (5)    Save / Use saved data      ========================%
%=========================================================================%

if trained
    fprintf('Will save at %s\n', [savepath fn]);
    save([savepath fn], 'M', 'laps', 'R', 'keep_neurons', 'settings');
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
colors = hsv(4);
labels = [R.type];
Xorth = show_latent({M.all}, R, colors, labels, Typetrial_tx);

%%
%=========================================================================%
%=========(7) Compare mean spike counts              =====================%
%=========================================================================%
figure(7)
set(gcf,'position',[100 100 500*1.62 500],'color','w')
plot(mean([R(laps.left).y],2),'r','displayname','wheel after left')
hold on
plot(mean([R(laps.right).y],2),'b','displayname','wheel after right')
ylabel('Average firing rate')
xlabel('Cell No.')
set(gca,'fontsize',14)
savefig()

figure(71)
plot_timescales({M.left, M.right, M.all}, colors, {'trained_{left}', 'trained_{right}', 'trained_{all}'})

%%
%=========================================================================%
%=========(8) Compute loglike P(run|model_run)       =====================%
%=========================================================================%

%load([roots{settings.animal} name_save_file])
Rs           = R;
%Rs           = shufftime(R);
%Rs           = shuffspike(R);
[Rs, Malt.left, Malt.right, Malt.all] = normalizedatanmodel(Rs, M.left, M.right, M.all);
%sufficient: 1:4 or 12:16 or 21:22 or 23:24 or 25:30? OR 31:35
%inconclusive: 5:10 and 17:18 and
%spy = [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 20 21 22 23 24 25 26 27 28 29 30 36 37 38 39 40 41 42 43 44 45 46];
%for l = 1:length(Rs)
%    Rs(l).y(spy,:)=0;
%end
%Classification stats of P(run events|model) 
models      = {M.left, M.right};
models      = {Malt.left, Malt.right};
Xtats       = classGPFA(Rs, models);
cm          = [Xtats.conf_matrix];
fprintf('hitA: %2.2f%%, hitB: %2.2f%%\n', 100*cm(1,1),100*cm(2,2))

% %show likelihood given the models
% % plot show likelihood given the models
label.title = 'P(run_j | Models_{left run, right run})';
label.modelA = 'Left alt.';
label.modelB = 'Right alt.';
%label.modelB = 'Global model';
label.xaxis = 'j';
label.yaxis = 'P(run_j| Models_{left run, right run})';
compareLogLike(Rs, Xtats, label)

%XY plot
cgergo = load('colors');

label.title = 'LDA classifier';
label.xaxis = 'P(run_j|Model_{left run})';
label.yaxis = 'P(run_j|Model_{right run})';
LDAclass(Xtats, label, cgergo.cExpon([2 3], :))

%%
%=========================================================================%
%=========(8) Compute loglike P(wheel|model_wheel)   =====================%
%=========================================================================%

%If model was not trained it can be loaded:
load([roots{animal} name_save_file])

%transformation to W testing
%W           = W(randperm(length(W))); %permutation of laps
%W           = shufftime(W); %time shuffling for each lap

errorTrials = find([W.type] > 2);                                          %erroneous trials wheel events
We          = W(errorTrials);                                              %erroneous trials struct                 

%Classification stats of P(proto_event|model) 
models      = {M_right, M_left};                                           %here models have future run label, 
Xtats       = classGPFA(W, models);

cm          = [Xtats.conf_matrix];
fprintf('Max-min Classifier hitA: %2.2f%%, hitB: %2.2f%%\n', 100*cm(1,1),100*cm(2,2))

% plot show likelihood given the models
label.title = 'P(wheel_j after error | models W)';
label.modelA = 'Wheel after rigth alt.';
label.modelB = 'Wheel after left alt.';

label.xaxis = 'j';
label.yaxis = 'P(wheel_j|model)';
compareLogLike(W, Xtats, label)                                           %P(error W | models W)

%XY plot
label.title = '';
label.modelA = 'Wheel after left alt.';
label.modelB = 'Wheel after right alt.';
label.xaxis = 'Log P(wheel|Model_{wheel after left run})';
label.yaxis = 'Log P(wheel|Model_{wheel after right run})';
LDAclass(Xtats, label, cgergo.cExpon([2 3], :))



%%
%=========================================================================%
%=========(9) Compute loglike P(wheel|run_model)     =====================%
%=========================================================================%
%#TODO: Separate this part v in a different script

in              = 'wheel'; %pre_turn
out             = 'wheel'; %lat_arm
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

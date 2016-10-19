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

%Use settings.animal corresponding to Data/spike_SPW_D2_L4.dat
%e.g. settings.animal = 28;

%========================Paramteres and variables==========================
fprintf('\nSelecting %d: %s\n\n',settings.animal,files{settings.animal});
data            = dlmread(files{settings.animal},'',1,0);
%mazesect        = data.Laps.MazeSection;
nLaps         = 12;
Fs              = 100;
data(:,1)       = round(data(:,1)*Fs);
totalDuration   = max(data(:,1));
lapDuration     = round(linspace(0,totalDuration,nLaps+1));
events          = cell(1,nLaps);
for n = 1:nLaps
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
nChannels         = max(data(:,2));
isIntern        = zeros(nChannels,1);
spk_clust       = get_spikes(data(:,2), data(:,1));
n_pyrs          = sum(isIntern==0);
TrialType       = ones(1,nLaps);
BehavType       = ones(1,nLaps) .* (1+1);
clear data
% String descriptions
Typetrial_tx    = {'free_run'};
Typebehav_tx    = {'first', 'regular', 'uncertain'};
Typeside_tx     = {'none'};
% GPFA training
showpred        = false; %show predicted firing rate
train_split     = false; %train GPFA on left/right separately?
name_save_file  = 'trainedGPFA';
testTrial        = 10;
trained         = false;


project_spw     = strrep(animals{settings.animal},'.dat','');
project_run     = strrep(project_spw,'SPW','RUN');
savepath_spw    = [workpath project_spw '/'];
savepath_run    = [workpath project_run '/'];
fn_spw          = [project_spw '_' ...
                   name_save_file '_' sprintf('%02d',settings.zDim) '.mat'];
fn_run          = strrep(fn_spw,'SPW','RUN');
if ~exist(savepath_spw,'dir')
    mkdir(savepath_spw);
end

if isempty(strfind(fn_spw, 'SPW'))
    warning('A sharp wave file is requested');
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
    figure(testTrial)
    raster(D(testTrial).spikes), hold on
    plot(90.*D(testTrial).speed./max(D(testTrial).speed),'k')
    plot(90.*D(testTrial).wh_speed./max(D(testTrial).wh_speed),'r')
end

% ========================================================================%
%==============  (2)  Extract Running Sections    ========================%
%=========================================================================%

%S = get_section(D, in, out, debug, namevar); %lap#1: sensor errors
[S, Sstate, SSPW_X] = extract_laps(Fs, spk_clust, ~isIntern, events, ...
                settings.section, TrialType, BehavType, ...
                X, Y, speed, wh_speed, state, SPW_X);

% ========================================================================%
%============== (3) Segment the spike vectors     ========================%
%=========================================================================%
%load run model and keep the same neurons

fprintf('Will load from %s\n', [savepath_run fn_run]);
info = load([savepath_run fn_run], 'M', 'laps', 'R', 'gpfaChannels', 'settings');
gpfaChannels = info.gpfaChannels;

[R, gpfaChannels, Rstate, RSPW_X] = segment(S, 'spike_train', settings.bin_size, Fs, ...
                                 gpfaChannels, settings.minFiringRate, settings.maxTime, ...
                                 Sstate, SSPW_X);

laps.all               = select_laps(BehavType, TrialType, settings.namevar);
laps.left              = select_laps(BehavType, TrialType, settings.namevar, 1);
laps.right             = select_laps(BehavType, TrialType, settings.namevar, 2);


M = info.M;

%% =======================================================================%
%=========(8) Compute loglike P(run|model_run)       =====================%
%=========================================================================%

%load([roots{settings.animal} name_save_file])
%R           = shufftime(R);
%Classification stats of P(run events|model) 
models      = {M.all};
% run -> run
scaleK = 0.5:0.1:1.5;
scaleRate = 0.4:0.2:2.4;
% run -> spw
%scaleK = 1:2:41;
%scaleRate = 1:20;
clear LLcmp;
LLsurf = zeros(length(scaleK), length(scaleRate));
for k = 1 : length(scaleK)
    myK = scaleK(k);
    parfor r = 1:length(scaleRate)
        myR = scaleRate(r);
        Xtats       = classGPFA(R, models, 'scaleK', myK, 'scaleRate', myR, 'mergeTrials', true);
        cm          = [Xtats.conf_matrix];
        % Long way:
        %for Xfn = fieldnames(Xtats)'
        %    cmp(scaleK,scaleRate).(Xfn{1}) = Xtats.(Xfn{1});
        %end
        LLcmp(k,r) = Xtats;
        LLsurf(k,r) = mean([Xtats.likelihood]);
        fprintf('scaleK: %2.2f scaleRate: %2.2f LL: %2.2f\n', myK, myR, LLsurf(k,r));
    end
end
[LLgridX, LLgridY] = meshgrid(scaleRate, scaleK);
fn_sav          = [project_run '_' 'ModelScalingStudy' '_' settings.namevar '.mat'];

save([savepath_run fn_sav],'LLcmp','LLsurf','LLgridX','LLgridY');

fig = figure();
surf(LLgridX,LLgridY,LLsurf);
ax1 = gca;
suf = '';
xlabel('scale Firing Rate');
ylabel('scale Latent Speed');
zlabel('log Likelihood');
fig_export(fig, [savepath_run strrep(fn_sav,'.mat','') suf], 120, 90);

set(ax1,'View',[45, 30]); suf = '_3Da'; %run
set(ax1,'View',[-45, 30]); suf = '_3D'; %spw
set(ax1,'View',[0, 0]); suf = '_FR';
set(ax1,'View',[-90, 0]); suf = '_Kface';
set(ax1,'View',[180, 0]); suf = '_FRback';
set(ax1,'View',[90, 0]); suf = '_K';

settings.namevar = 'spw';
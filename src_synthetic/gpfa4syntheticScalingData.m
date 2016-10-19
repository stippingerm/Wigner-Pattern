%GPFA4SCALING This script loads data for a given session (see GPFA4BATCH)
%        and also a model fitted to a (possibly) different session. Then
%        the parameters of the model are rescaled to show how much it can
%        account for the data and which is the best rescaling.
%
%        DESCRIPTION: This script uses a settings file (see template) to
%        set the parameters for the database and the GPFA model. It first
%        discovers all available data files then loads the selected one
%        using the database-specific function given in the settings. Then
%        it loads a previously fitted GPFA model and tries to different
%        adjustments.
%
%Version 1.0 Marcell Stippinger, 2016.


clc, close all; %clear all;

workpath        = '~/marcell/napwigner/work/';
name_save_file  = 'trainedGPFA';

if ~exist('settings_file','var')
    settings_file = 'gpfa4syntheticSectionSettings.m';
end

%Use settings.animal corresponding to Data/spike_SPW_D2_L4.dat
%e.g. settings.animal = 28;

% String descriptions
Typetrial_tx    = {'free_run'};
Typebehav_tx    = {'first', 'regular', 'uncertain'};
Typeside_tx     = {'none'};

run(settings_file);


%========================       Source data      ==========================

[files, roots, animals] = get_matFiles(settings.basepath,settings.pattern);
fprintf('\nSelecting %d: %s\n\n',settings.animal,files{settings.animal});

project_data   = regexprep(animals{settings.animal},settings.pattern,'$1');
project_model  = regexprep(animals{settings.amodel},settings.pattern,'$1');
savepath_data  = [workpath project_data '/'];
savepath_model = [workpath project_model '/'];
fn_data        = [project_data '_' ...
                 name_save_file '_' settings.namevar '_' ...
                 sprintf('%02d',settings.zDim) '.mat'];
fn_model       = [project_model '_' ...
                 name_save_file '_' settings.namevar '_' ...
                 sprintf('%02d',settings.zDim) '.mat'];

if ~exist(savepath_data,'dir')
    mkdir(savepath_data);
end


%========================Paramteres and variables==========================
loader = str2func(sprintf('load_%s',settings.paradigm));
[D, inChannels, modelTrials] = loader(files{settings.animal}, settings);


%%
% ========================================================================%
%============== (5)    Save / Use saved data      ========================%
%=========================================================================%

% GPFA training

fprintf('Will load model from %s\n', [savepath_model fn_model]);
info = load([savepath_model fn_model], 'M', 'laps', 'R', 'inChannels', 'settings');
%inChannels = info.inChannels;
M = info.M;


%% =======================================================================%
%=========(8) Compute loglike P(run|model_model)       =====================%
%=========================================================================%

%load([roots{settings.animal} name_save_file])
%R           = shufftime(R);
%Classification stats of P(run events|model) 
models      = {M.all};
% run -> run
%scaleK = 0.5:0.1:1.5;
%scaleRate = 0.4:0.2:2.4;
%settings.namevar='run';
% run -> spw
scaleK = 1:2:41;
scaleRate = 1:20;
settings.namevar='spw';
clear LLcmp;
LLsurf = zeros(length(scaleK), length(scaleRate));
for k = 1 : length(scaleK)
    myK = scaleK(k);
    parfor r = 1:length(scaleRate)
        myR = scaleRate(r);
        myData = R;
        for i = 1:length(myData)
            myData(i).y = myData(i).y/sqrt(myR);
        end
        % NOTE: ScaleVar is experimental and maybe not needed
        Xtats       = classGPFA(myData, models, 'scaleK', myK, 'scaleRate', 1.0, ...
                                'scaleVar', 1.0/myR, 'mergeTrials', true);
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
fn_sav          = [project_model '_' 'DataScalingStudy' '_' settings.namevar '.mat'];

save([savepath_model fn_sav],'LLcmp','LLsurf','LLgridX','LLgridY');

fig = figure();
surf(LLgridX,LLgridY,LLsurf);
ax1 = gca;
suf = '';
xlabel('scale Firing Rate');
ylabel('scale Latent Speed');
zlabel('log Likelihood');
fig_export(fig, [savepath_model strrep(fn_sav,'.mat','') suf], 120, 90);

set(ax1,'View',[45, 30]); suf = '_3Da'; %run
set(ax1,'View',[-45, 30]); suf = '_3D'; %spw
set(ax1,'View',[0, 0]); suf = '_FR';
set(ax1,'View',[-90, 0]); suf = '_Kface';
set(ax1,'View',[180, 0]); suf = '_FRback';
set(ax1,'View',[90, 0]); suf = '_K';

settings.namevar = 'spw';
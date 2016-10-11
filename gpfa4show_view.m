%GPFA4BATCH This script contains a general data loading mechanism and the
%        training of the GPFA model along with saving the learned model.
%
%        DESCRIPTION: This script uses a settings file (see template) to
%        set the parameters for the database and the GPFA model. It first
%        discovers all available data files then loads the selected one
%        using the database-specific function given in the settings. Then
%        it fits a GPFA model with the given parameters (latent dimension,
%        etc.) and saves the results.
%
%Version 1.0 Marcell Stippinger, 2016.


clc, close all; %clear all

workpath        = '~/marcell/napwigner/work/';
name_save_file  = 'trainedGPFA';

if ~exist('settings_file','var')
    settings_file = 'gpfa4viewSectionSettings.m';
end

run(settings_file);

%%
%========================       Source data      ==========================

[files, roots, animals] = get_matFiles(settings.basepath,settings.pattern);
fprintf('\nSelecting %d: %s',settings.animal,files{settings.animal-1});
fprintf('\nSelecting %d: %s',settings.animal,files{settings.animal});
fprintf('\nSelecting %d: %s\n\n',settings.animal,files{settings.animal+1});

project_pre     = regexprep(animals{settings.animal-1},settings.pattern,'$1');
savepath_pre    = [workpath project_pre '/'];
fn_model_pre    = [project_pre '_' ...
                   name_save_file '_' settings.namevar '_' ...
                   sprintf('%02d',settings.zDim) '.mat'];
project_post    = regexprep(animals{settings.animal+1},settings.pattern,'$1');
savepath_post   = [workpath project_post '/'];
fn_model_post   = [project_post '_' ...
                   name_save_file '_' settings.namevar '_' ...
                   sprintf('%02d',settings.zDim) '.mat'];
project_on      = regexprep(animals{settings.animal},settings.pattern,'$1');
savepath_on     = [workpath project_on '/'];
fn_model_on     = [project_on '_' ...
                   name_save_file '_' settings.namevar '_' ...
                   sprintf('%02d',settings.zDim) '.mat'];
if ~exist(savepath_on,'dir')
    mkdir(savepath_on);
end


%========================Paramteres and variables==========================
loader = str2func(sprintf('load_%s',settings.paradigm));
modeler = str2func(sprintf('model_%s',settings.paradigm));
[D_pre, inChannels, modelTrials] = loader(files{settings.animal-1}, settings);
[D_post, inChannels, modelTrials] = loader(files{settings.animal+1}, settings);
[D_on, inChannels, modelTrials] = loader(files{settings.animal}, settings);


%%
% ========================================================================%
%============== (4)    Save / Use saved data      ========================%
%=========================================================================%

fprintf('Will load from %s\n', [savepath_on fn_model_on]);
%info = load([savepath fn_model],  'M', 'modelTrials', 'D', 'inChannels', 'settings');
%info = load([savepath_run fn_run], 'M', 'laps', 'R', 'keep_neurons', 'settings');
info_pre = modeler([savepath_pre fn_model_pre], settings);
info_post = modeler([savepath_post fn_model_post], settings);
info_on = modeler([savepath_on fn_model_on], settings);


%%
%=========================================================================%
%=========(5) Model posterior of overrepresented digit   =================%
%=========    in pre- and post exposure                  =================%
%=========================================================================%


%Classification stats of P(run events|model)


try
% Imprved prediction based on annotated models (use model_{paradigm}.m loader)
models             = {info_on.M.ext01, info.M.ext02};
catch ME
models             = {info_on.M.ext01};
end

Xtats_pre          = classGPFAimproved(D_pre, models, 'labelField', info_on.labelField);
Xtats_on           = classGPFAimproved(D_on, models, 'labelField', info_on.labelField);
Xtats_post         = classGPFAimproved(D_post, models, 'labelField', info_on.labelField);

mean(Xtats_pre.likelihood)
mean(Xtats_on.likelihood)
mean(Xtats_post.likelihood)


like = [Xtats_pre.likelihood(:); Xtats_on.likelihood(:); Xtats_post.likelihood(:)];
grp = [ repmat({'pre'}, numel(Xtats_pre.likelihood), 1 ); ... 
        repmat({'on'}, numel(Xtats_on.likelihood), 1 ); ... 
        repmat({'post'}, numel(Xtats_post.likelihood), 1 ) ];

figure();
boxplot(like,grp);
xlabel('Session')
ylabel('Log likelihood')
title('Posterior of model based on overrepresented digit')


%%
%=========================================================================%
%=========(6) Model posterior of pre- and post exposure models  ==========%
%=========    on pre- and post exposure trials                  ==========%
%=========================================================================%


%Classification stats of P(run events|model)


models             = {info_pre.M.num01, info_post.M.num01};

Xtats_pre          = classGPFAimproved(D_pre, models, 'labelField', info_on.labelField);
Xtats_on           = classGPFAimproved(D_on, models, 'labelField', info_on.labelField);
Xtats_post         = classGPFAimproved(D_post, models, 'labelField', info_on.labelField);

mean(Xtats_pre.likelihood,2)
mean(Xtats_post.likelihood,2)


like = [Xtats_pre.likelihood(:); Xtats_on.likelihood(:); Xtats_post.likelihood(:)];
grp = [ repmat({'M_{pre}:D_{pre}'; 'M_{post}:D_{pre}'}, size(Xtats_pre.likelihood,2), 1 ); ... 
        repmat({'M_{pre}:D_{on}'; 'M_{post}:D_{on}'}, size(Xtats_on.likelihood,2), 1 ); ... 
        repmat({'M_{pre}:D_{post}'; 'M_{post}:D_{post}'}, size(Xtats_post.likelihood,2), 1 ) ];

% FIXME: number of neurons differs !!!
figure();
boxplot(like,grp);
xlabel('Session')
ylabel('Log likelihood')
title('Posterior of model based on session')



%%
%=========================================================================%
%=========(7) Model posterior of post exposure            ================%
%=========    on evoked activity trials                   ================%
%=========================================================================%


%Classification stats of P(run events|model)


models             = {info_post.M.num01};

Xtats_on           = classGPFAimproved(D_on, models, 'labelField', info_on.labelField);


like = [Xtats_on.likelihood(:)];
grp = [D_on(:).digit];

figure();
boxplot(like,grp); hold on
scatter(grp(:),like(:))
xlabel('Trial type (digit)')
ylabel('Log likelihood')
title('Posterior of post-exposure model based on trial type (evoked)')




%%
%=========================================================================%
%========(9a) Model posterior of evoked activity digits  =================%
%========     in pre- and post exposure                  =================%
%=========================================================================%


%Classification stats of P(run events|model)


models             = {info_on.M.all};

Xtats_pre          = classGPFAimproved(D_pre, models, 'labelField', info_on.labelField);
Xtats_on           = classGPFAimproved(D_on, models, 'labelField', info_on.labelField);
Xtats_post         = classGPFAimproved(D_post, models, 'labelField', info_on.labelField);

mean(Xtats_pre.likelihood)
mean(Xtats_post.likelihood)


like = [Xtats_pre.likelihood(:); Xtats_on.likelihood(:); Xtats_post.likelihood(:)];
grp = [ repmat({'pre'}, numel(Xtats_pre.likelihood), 1 ); ... 
        repmat({'on'}, numel(Xtats_on.likelihood), 1 ); ... 
        repmat({'post'}, numel(Xtats_post.likelihood), 1 ) ];

figure();
boxplot(like,grp);
xlabel('Session')
ylabel('Log likelihood')
title('Posterior of model based on evoked activity (digits)')



%%
%=========================================================================%
%========(9b) Model posterior of pre- and post exposure models ===========%
%========     on evoked activity trials                        ===========%
%=========================================================================%


%Classification stats of P(run events|model)


models             = {info_pre.M.num01, info_post.M.num01};

Xtats_on           = classGPFAimproved(D_on, models, 'labelField', info_on.labelField);


like_pre = [Xtats_on.likelihood(1,:)];
like_post = [Xtats_on.likelihood(2,:)];
grp = [D_on(:).digit];

figure();
boxplot(like_pre,grp);
xlabel('Trial type (digit)')
ylabel('Log likelihood')
title('Posterior of pre-exposure model based on trial type (evoked)')

figure();
boxplot(like_post,grp);
xlabel('Trial type (digit)')
ylabel('Log likelihood')
title('Posterior of post-exposure model based on trial type (evoked)')

figure();
label.model = {'pre', 'post'};
label.title = 'Classification using trial likelihood according to models';
label.xaxis = 'j';
label.yaxis = 'P(trial_i | Model_j)';
compareLogLike(D_on, Xtats_on, label)

%%

boxplot([Xtats_pre.likelihood; Xtats_post.likelihood]);

Ytats              = Xtats;
tmp                = cell2mat(models);
Ytats.class_output = [tmp(Xtats.class_output).prediction];
label.model        = {tmp.name};
[Rs.type]          = Rs.digit;

catch ME
% Basic prediction capabiliy
models             = struct2cell(info.M);
Xtats              = classGPFA(Rs, models);
Ytats              = Xtats;
Ytats.class_output = Xtats.class_output-1;
label.model = fieldnamels(info.M);
end

% %show likelihood given the models
% % plot show likelihood given the models
label.title = 'Classification using trial likelihood according to models';
label.xaxis = 'j';
label.yaxis = 'P(trial_i | Model_j)';
compareLogLike(Rs, Ytats, label)
cm = confusionmat(Ytats.real_label,Ytats.class_output);
hit_ratio = sum(diag(cm))/sum(sum(cm))

if nModels == 2
    
    % Confusion matrix (use for two models only)
    cm          = [Xtats.conf_matrix];
    fprintf('hitA: %2.2f%%, hitB: %2.2f%%\n', 100*cm(1,1),100*cm(2,2))

    %XY plot
    cgergo = load('colors');

    label.title = 'LDA classifier';
    label.xaxis = 'P(run_j|Model_{left run})';
    label.yaxis = 'P(run_j|Model_{right run})';
    LDAclass(Xtats, label, cgergo.cExpon([2 3], :))
end
%%
%=========================================================================%
%=========(8) Similarity of models   =====================%
%=========================================================================%

i_model = 1;
j_model = 1;
gpfaCompare2(models{i_model},models{j_model});

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

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


%========================       Source data      ==========================

[files, roots, animals] = get_matFiles(settings.basepath,settings.pattern);
fprintf('\nSelecting %d: %s\n\n',settings.animal,files{settings.animal});

project         = regexprep(animals{settings.animal},settings.pattern,'$1');
savepath        = [workpath project '/'];
fn_model        = [project '_' ...
                   name_save_file '_' settings.namevar '_' ...
                   sprintf('%02d',settings.zDim) '.mat'];
if ~exist(savepath,'dir')
    mkdir(savepath);
end


%========================Paramteres and variables==========================
loader = str2func(sprintf('load_%s',settings.paradigm));
modeler = str2func(sprintf('model_%s',settings.paradigm));
[D, inChannels, modelTrials] = loader(files{settings.animal}, settings);


%%
% ========================================================================%
%============== (5)    Save / Use saved data      ========================%
%=========================================================================%

fprintf('Will load from %s\n', [savepath fn_model]);
%info = load([savepath fn_model],  'M', 'modelTrials', 'D', 'inChannels', 'settings');
%info = load([savepath_run fn_run], 'M', 'laps', 'R', 'keep_neurons', 'settings');
info = modeler([savepath fn_model], settings);

M = info.M;


%%
% ========================================================================%
%============== (6)    Show Neural Trajectories   ========================%
%=========================================================================%

%colors = cgergo.cExpon([2 3 1], :);
colors = hsv(numel(fieldnames(M)));
labels = [D.type];
Xorth = show_latent(struct2cell(M), D, colors, labels, ['Type']);

%%
%=========================================================================%
%=========(7) Compare mean spike counts              =====================%
%=========================================================================%
figure(7)
set(gcf,'position',[100 100 500*1.62 500],'color','w')
plot(mean([D(laps.left).y],2),'r','displayname','wheel after left')
hold on
plot(mean([D(laps.right).y],2),'b','displayname','wheel after right')
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
Rs           = D;
%Rs           = shufftime(R);
%Rs           = shuffspike(R);
%[Rs, Malt.left, Malt.right, Malt.all] = normalizedatanmodel(Rs, M.left, M.right, M.all);
%sufficient: 1:4 or 12:16 or 21:22 or 23:24 or 25:30? OR 31:35
%inconclusive: 5:10 and 17:18 and
%spy = [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 20 21 22 23 24 25 26 27 28 29 30 36 37 38 39 40 41 42 43 44 45 46];
%for l = 1:length(Rs)
%    Rs(l).y(spy,:)=0;
%end
%Classification stats of P(run events|model)

models             = info.decoder;

%models      = {M.left, M.right};
%models      = {Malt.left, Malt.right};
Xtats       = classGPFA(Rs, models);
Xtats       = classGPFAimproved(Rs, models);
cm          = [Xtats.conf_matrix];
fprintf('hitA: %2.2f%%, hitB: %2.2f%%\n', 100*cm(1,1),100*cm(2,2))

Ytats = Xtats;
for i = 1:length(Xtats)
    Ytats.class_output(i) = models{Xtats.class_output(i)}.prediction;
end
% %show likelihood given the models
% % plot show likelihood given the models
label.title = 'Classification using trial likelihood according to models';
for i = 1:length(models)
    tmp{i} = models{i}.name;
end
label.model = tmp;
%label.modelB = 'Global model';
label.xaxis = 'j';
label.yaxis = 'P(trial_i | Model_j)';
compareLogLike(Rs, Ytats, label)

%XY plot
if nModels == 2
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

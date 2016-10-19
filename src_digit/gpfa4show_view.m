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
settings.section.in  = 3;
settings.section.out = 3;

[files, roots, animals] = get_matFiles(settings.basepath,settings.pattern);
fprintf('\nSelecting %d: %s',    settings.animal-1,files{settings.animal-1});
fprintf('\nSelecting %d: %s',    settings.animal,  files{settings.animal  });
fprintf('\nSelecting %d: %s\n\n',settings.animal+1,files{settings.animal+1});

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

nNormalDigit = 10;
nOverrep = 4;
nExtraDigit = floor((length(unique([D_on.type]))-nNormalDigit)/nOverrep);

digitOverr = zeros(1,nExtraDigit);
for i = 1:nExtraDigit
    digitOverr(i) = viewing_codes.(project_on)(nNormalDigit+nOverrep*i);
end

trialOverr         = zeros(1,length(D_on)) == 1;
for i=1:nExtraDigit
    trialOverr     = trialOverr | ([D_on.digit] == digitOverr(i));
end
trialBlank         = [D_on.digit] == -1;
trialOther         = (~trialBlank) & (~trialOverr);

color = struct('pre',[0 0.7 0.3],'on',[1 0.3 0],'post',[0 0.5 1], ...
                'digit',[1 0.6 0.6],'blank',[0.6 0.6 0.6],'other',[0.8 0.5 0.8],...
               'over',[1 0.7 0.3]);
symbol = struct('pre','o','on','d','post','s', ...
                'digit','^','blank','.','other','v','over','*');

if settings.debug
    figure(); hold on
    fields         = fieldnames(color);
    count = length(fields);
    for i = 1:count;
        plot(i, 1, 'Color',color.(fields{i}),'Marker',symbol.(fields{i}));
    end
    set(gca,'XLim',[0 count+1])
    set(gca,'XTick',1:count)
    set(gca,'XTickLabel',fields)
end
            
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
% Imprved prediction trained on annotated models (use model_{paradigm}.m loader)
models             = {info_on.M.ext01, info.M.ext02};
catch ME
models             = {info_on.M.ext01};
end

Xtats_pre          = classGPFAimproved(D_pre,  models, 'labelField', info_on.labelField, 'useAllTrials', true);
Xtats_on           = classGPFAimproved(D_on,   models, 'labelField', info_on.labelField);
Xtats_post         = classGPFAimproved(D_post, models, 'labelField', info_on.labelField, 'useAllTrials', true);


%Xtats_blank        = classGPFAimproved(D_on(trialBlank), models, 'labelField', info_on.labelField);
%Xtats_overr        = classGPFAimproved(D_on(trialOverr), models, 'labelField', info_on.labelField);
%Xtats_other        = classGPFAimproved(D_on(trialOther), models, 'labelField', info_on.labelField);

mean(Xtats_pre.likelihood)
mean(Xtats_on.likelihood)
mean(Xtats_post.likelihood)

like_blank = Xtats_on.likelihood(:,trialBlank);
like_other = Xtats_on.likelihood(:,trialOther);
like_overr = Xtats_on.likelihood(:,trialOverr);

like = [Xtats_pre.likelihood(:); ...
        Xtats_on.likelihood(:); ...
        like_blank(:); ...
        like_other(:); ...
        like_overr(:); ...
        Xtats_post.likelihood(:)];
grp = [ repmat({'pre,'}, numel(Xtats_pre.likelihood), 1 ); ... 
        repmat({'on:'}, numel(Xtats_on.likelihood), 1 ); ... 
        repmat({'blank'}, numel(like_blank), 1 ); ... 
        repmat({'other'}, numel(like_other), 1 ); ... 
        repmat({'overr,'}, numel(like_overr), 1 ); ... 
        repmat({'post.'}, numel(Xtats_post.likelihood), 1 ) ];

figure();
boxplot(like,grp);
xlabel('Session')
ylabel('Log likelihood')
title('Posterior of model trained on overrepresented digit')

fign = ['fig5a-' project_on];
savefig([fign '.fig']);
saveas(gcf,[fign '.png'],'png');
saveas(gcf,[fign '.pdf'],'pdf');


%%
%=========================================================================%
%========(5b) Posterior of models trained during exposure ================%
%=========    for pre- and post exposure                  ================%
%=========================================================================%


%Classification stats of P(run events|model)


try
% Imprved prediction trained on annotated models (use model_{paradigm}.m loader)
models             = {info_on.M.digit, info_on.M.grp02, ...
                      info_on.M.ext01, info_on.M.ext02};
names              = {'all digits', 'four digits', ...
                      sprintf('overrep.d. %d',digitOverr(1)), ...
                      sprintf('overrep.d. %d',digitOverr(2)) };
ids                = {'digit','other','over','over'};
catch ME
models             = {info_on.M.digit, info_on.M.grp02, info_on.M.ext01};
names              = {'all digits', 'four digits', ...
                      sprintf('overrep.d. %d',digitOverr(1))};
ids                = {'digit','other','over'};
end

Xtats_pre          = classGPFAimproved(D_pre,  models, 'labelField', info_on.labelField, 'useAllTrials', true);
Xtats_on           = classGPFAimproved(D_on,   models, 'labelField', info_on.labelField);
Xtats_post         = classGPFAimproved(D_post, models, 'labelField', info_on.labelField, 'useAllTrials', true);

like_blank = Xtats_on.likelihood(:,trialBlank);
like_other = Xtats_on.likelihood(:,trialOther);
like_overr = Xtats_on.likelihood(:,trialOverr);

figure(); hold on

for i_model = 1:length(models)
    position = (1:2:12) - 1 + 0.4*i_model ;
    like = [Xtats_pre.likelihood(i_model,:), ...
            Xtats_on.likelihood(i_model,:), ...
            like_blank(i_model,:), ...
            like_other(i_model,:), ...
            like_overr(i_model,:), ...
            Xtats_post.likelihood(i_model,:)];
    grp = [ repmat({'pre,'}, size(Xtats_pre.likelihood,2), 1 ); ... 
            repmat({'on:'}, size(Xtats_on.likelihood,2), 1 ); ... 
            repmat({'blank'}, size(like_blank,2), 1 ); ... 
            repmat({'other'}, size(like_other,2), 1 ); ... 
            repmat({'overr,'}, size(like_overr,2), 1 ); ... 
            repmat({'post.'}, size(Xtats_post.likelihood,2), 1 ) ];
        
    boxplot(like,grp,'position',position,'width',0.18,...
        'Color',color.(ids{i_model}));
end

hBoxes = findall(gca,'Tag','Box');
% findall is used to find all the graphics objects with tag "box", i.e. the box plot
hLegend = legend(hBoxes(end:-6:1), names);
% Among the children of the legend, find the line elements
hChildren = findall(get(hLegend,'Children'), 'Type','Line');

xlabel('Session')
ylabel('Log likelihood')
title('Posterior of broad models trained on evoked activity')

fign = ['fig5b-' project_on];
savefig([fign '.fig']);
saveas(gcf,[fign '.png'],'png');
saveas(gcf,[fign '.pdf'],'pdf');


figure();
%scatter(Xtats_on.likelihood(1,:),  Xtats_on.likelihood(2,:),  [],color.on,'o');
scatter(Xtats_on.likelihood(3,trialOther), Xtats_on.likelihood(2,trialOther), [],color.other,symbol.other);  hold on
scatter(Xtats_on.likelihood(3,trialBlank), Xtats_on.likelihood(2,trialBlank), [],color.blank,symbol.blank);
scatter(Xtats_on.likelihood(3,trialOverr), Xtats_on.likelihood(2,trialOverr), [],color.over,symbol.over);
scatter(Xtats_pre.likelihood(3,:), Xtats_pre.likelihood(2,:), [],color.pre,'^');
scatter(Xtats_post.likelihood(3,:),Xtats_post.likelihood(2,:),[],color.post,'s');
mmin = min([xlim, ylim]);
mmax = max([xlim, ylim]);
plot([mmin mmax], [mmin mmax], 'k--');
xlabel(sprintf('P(D_{i}|M_{%s})',names{3}));
ylabel(sprintf('P(D_{i}|M_{%s})',names{2}));
title('Linear classification of all trials in the pre-post axis');
%lgd = legend({'i \in on','i \in pre','i \in post'},'Location','southeast');
lgd = legend({'i \in other','i \in blank','i \in over','i \in pre','i \in post'},'Location','southeast');
%title(lgd,'String',{'Trial type'});
%hlgdt = get(lgd,'Title');
%set(v,'string','Legend Title');

fign = ['fig5c-' project_on];
savefig([fign '.fig']);
saveas(gcf,[fign '.png'],'png');
saveas(gcf,[fign '.pdf'],'pdf');


%%
%=========================================================================%
%=========(6) Model posterior of pre- and post exposure models  ==========%
%=========    on pre- and post exposure trials                  ==========%
%=========================================================================%


%Classification stats of P(run events|model)

models             = {info_pre.M.all, info_post.M.all};

Xtats_pre          = classGPFAimproved(D_pre,  models, 'labelField', info_on.labelField);
Xtats_on           = classGPFAimproved(D_on,   models, 'labelField', info_on.labelField, 'useAllTrials', true);
Xtats_post         = classGPFAimproved(D_post, models, 'labelField', info_on.labelField);

mean(Xtats_pre.likelihood,2)
mean(Xtats_post.likelihood,2)


like = [Xtats_pre.likelihood(:); Xtats_on.likelihood(:); Xtats_post.likelihood(:)];
grp = [ repmat({'(D_{pre}|M_{pre})'; '(D_{pre}|M_{post})'}, size(Xtats_pre.likelihood,2), 1 ); ... 
        repmat({'(D_{on}|M_{pre})'; '(D_{on}|M_{post})'}, size(Xtats_on.likelihood,2), 1 ); ... 
        repmat({'(D_{post}|M_{pre})'; '(D_{post}|M_{post})'}, size(Xtats_post.likelihood,2), 1 ) ];

figure();
boxplot(like,grp);
xlabel('Session')
ylabel('Log likelihood')
title('Posterior of models trained on pre and post session')
ax = gca;
ax.XTickLabelRotation = 45;

fign = ['fig6a-' project_on];
savefig([fign '.fig']);
saveas(gcf,[fign '.png'],'png');
saveas(gcf,[fign '.pdf'],'pdf');

figure();
%scatter(Xtats_on.likelihood(1,:),  Xtats_on.likelihood(2,:),  [],color.on,'o');
scatter(Xtats_on.likelihood(1,trialOther), Xtats_on.likelihood(2,trialOther), [],color.other,symbol.other);  hold on
scatter(Xtats_on.likelihood(1,trialBlank), Xtats_on.likelihood(2,trialBlank), [],color.blank,symbol.blank);
scatter(Xtats_on.likelihood(1,trialOverr), Xtats_on.likelihood(2,trialOverr), [],color.over,symbol.over);
scatter(Xtats_pre.likelihood(1,:), Xtats_pre.likelihood(2,:), [],color.pre,'^');
scatter(Xtats_post.likelihood(1,:),Xtats_post.likelihood(2,:),[],color.post,'s');
mmin = min([xlim, ylim]);
mmax = max([xlim, ylim]);
plot([mmin mmax], [mmin mmax], 'k--');
xlabel('P(D_{i}|M_{pre})');
ylabel('P(D_{i}|M_{post})');
title('Linear classification of all trials in the pre-post axis');
%lgd = legend({'i \in on','i \in pre','i \in post'},'Location','southeast');
lgd = legend({'i \in other','i \in blank','i \in over','i \in pre','i \in post'},'Location','southeast');
%title(lgd,'String',{'Trial type'});
%hlgdt = get(lgd,'Title');
%set(v,'string','Legend Title');

fign = ['fig6b-' project_on];
savefig([fign '.fig']);
saveas(gcf,[fign '.png'],'png');
saveas(gcf,[fign '.pdf'],'pdf');


%%
%=========================================================================%
%========(6c) Model posterior of pre- and post exposure models ===========%
%========     on evoked activity trials                        ===========%
%=========================================================================%


%Classification stats of P(run events|model)

models             = {info_pre.M.all, info_post.M.all};

Xtats_on           = classGPFAimproved(D_on, models, 'labelField', info_on.labelField, 'useAllTrials', true);

like_pre = [Xtats_on.likelihood(1,:)];
like_post = [Xtats_on.likelihood(2,:)];
grp = [D_on(:).digit];

if sum(models{1}.keep_neurons)~=sum(models{2}.keep_neurons)
    warning('The number of neurons should be equal in the two models')
end

% groups of boxplot, based on
% https://www.mathworks.com/matlabcentral/answers/22-how-do-i-display-different-boxplot-groups-on-the-same-figure-in-matlab

position = -1:1:9;

figure();
position_pre = position-0.2;
boxplot(like_pre,grp,'colors',color.pre,'positions',position_pre,'width',0.18); hold on
xlabel('Trial type (digit)')
ylabel('Log likelihood')
title('Posterior of pre-exposure model trained on trial type (evoked)')

% fign = ['fig6c-' project_on];
% savefig([fign '.fig']);
% saveas(gcf,[fign '.png'],'png');
% saveas(gcf,[fign '.pdf'],'pdf');
% 
% figure();
position_post = position+0.2;
boxplot(like_post,grp,'colors',color.post,'positions',position_post,'width',0.18);
xlabel('Trial type (digit)')
ylabel('Log likelihood')
title('Posterior of models trained on pre and post-exposure\nfor evoked evoked activity')

% Draw a star to overrepresented digits
y = ylim;
vpos = 0.99*y(1)+0.01*y(2);
hStar = plot(digitOverr,vpos,'k*');


% boxplot legend, based on
% https://www.mathworks.com/matlabcentral/answers/127195-how-do-i-add-a-legend-to-a-boxplot-in-matlab

hBoxes = findall(gca,'Tag','Box');
% findall is used to find all the graphics objects with tag "box", i.e. the box plot
hLegend = legend([hBoxes([12 1]); hStar], {'pre', 'post', 'overr.'});
% Among the children of the legend, find the line elements
hChildren = findall(get(hLegend,'Children'), 'Type','Line');

% Set the horizontal lines to the right colors
%set(hChildren(2),'Color','b')
%set(hChildren(1),'Color','g')



set(gca,'XLim',[-2 10])
set(gca,'XTick',position)
set(gca,'XTickLabel',position)

% Save
fign = ['fig6d-' project_on];
savefig([fign '.fig']);
saveas(gcf,[fign '.png'],'png');
saveas(gcf,[fign '.pdf'],'pdf');



figure();
label.model = {'pre=1', 'post=2'};
label.title = 'Classification using trial likelihood according to models';
label.xaxis = 'j';
label.yaxis = 'P(trial_i | Model_j)';
compareLogLike(D_on, Xtats_on, label)

fign = ['fig6e-' project_on];
savefig([fign '.fig']);
saveas(gcf,[fign '.png'],'png');
saveas(gcf,[fign '.pdf'],'pdf');



figure();

twidth = 4;
triangle = [linspace(1,twidth,twidth) linspace(twidth-1,1,twidth-1)];
triangle = triangle / sum(triangle);, 'useAllTrials', true
plot(find(~trialBlank),conv(Xtats_on.class_output(~trialBlank),triangle,'same'))
set(gca,'YLim',[0.8 2.2])
set(gca,'YTick',[1 2])
set(gca,'YTickLabel',{'pre','post'})
xlabel('Trial ID');
ylabel('Smoothed decision');
title('Classification using trial likelihood according to models');

fign = ['fig6f-' project_on];
savefig([fign '.fig']);
saveas(gcf,[fign '.png'],'png');
saveas(gcf,[fign '.pdf'],'pdf');

% %%
% %=========================================================================%
% %========(5b) Model posterior of evoked activity digits  =================%
% %========     in pre- and post exposure                  =================%
% %=========================================================================%
% 
% 
% %Classification stats of P(run events|model)
% 
% 
% models             = {info_on.M.digit};
% 
% Xtats_pre          = classGPFAimproved(D_pre, models, 'labelField', info_on.labelField, 'useAllTrials', true);
% Xtats_on           = classGPFAimproved(D_on, models, 'labelField', info_on.labelField);
% Xtats_post         = classGPFAimproved(D_post, models, 'labelField', info_on.labelField, 'useAllTrials', true);
% 
% mean(Xtats_pre.likelihood)
% mean(Xtats_post.likelihood)
% 
% 
% % like = [Xtats_pre.likelihood(:); Xtats_on.likelihood(:); Xtats_post.likelihood(:)];
% % grp = [ repmat({'pre'}, numel(Xtats_pre.likelihood), 1 ); ... 
% %         repmat({'on'}, numel(Xtats_on.likelihood), 1 ); ... 
% %         repmat({'post'}, numel(Xtats_post.likelihood), 1 ) ];
% 
% like_blank = Xtats_on.likelihood(:,trialBlank);
% like_other = Xtats_on.likelihood(:,trialOther);
% like_overr = Xtats_on.likelihood(:,trialOverr);
% 
% like = [Xtats_pre.likelihood(:); ...
%         Xtats_on.likelihood(:); ...
%         like_blank(:); ...
%         like_other(:); ...
%         like_overr(:); ...
%         Xtats_post.likelihood(:)];
% grp = [ repmat({'pre,'}, numel(Xtats_pre.likelihood), 1 ); ... 
%         repmat({'on:'}, numel(Xtats_on.likelihood), 1 ); ... 
%         repmat({'blank'}, numel(like_blank), 1 ); ... 
%         repmat({'other'}, numel(like_other), 1 ); ... 
%         repmat({'overr,'}, numel(like_overr), 1 ); ... 
%         repmat({'post.'}, numel(Xtats_post.likelihood), 1 ) ];
% 
% figure();
% boxplot(like,grp);
% xlabel('Session')
% ylabel('Log likelihood')
% title('Posterior of model trained on evoked activity (digits)')
% 
% fign = ['fig5b-' project_on];
% savefig([fign '.fig']);
% saveas(gcf,[fign '.png'],'png');
% saveas(gcf,[fign '.pdf'],'pdf');





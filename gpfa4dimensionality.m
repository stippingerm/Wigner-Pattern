%GPFA4SYNTHETICDIMENSIONALITY This script reads the fitted GPFA models and
%plots the log likelihood of the different latent dimensionality.
%
%        DESCRIPTION: This script can be used for dimesionality estimation.
%Version 1.0 Marcell Stippinger


clc, close all; %clear all;

%========================Paramteres and variables==========================


maxdim = 30;


workpath        = '~/marcell/napwigner/work/';
name_save_file  = 'trainedGPFA';

if ~exist('settings_file','var')
    settings_file = 'gpfa4viewSectionSettings.m';
end

run(settings_file);

%========================       Source data      ==========================

[files, roots, animals] = get_matFiles(settings.basepath,settings.pattern);
fprintf('\nSelecting %d: %s\n\n',settings.animal,files{settings.animal});

%%
% ========================================================================%
%============== (2)  Load / Save data per project  =======================%
%=========================================================================%

for i_animal = 1:length(animals)

    fprintf('\nSelecting %d: %s\n\n',i_animal,files{i_animal});

    project         = regexprep(animals{i_animal},settings.pattern,'$1');
    savepath        = [workpath project '/'];


    M = cell(maxdim,1);
    like_train = cell(maxdim,1);
    like_test = cell(maxdim,1);
    legend_ = cell(maxdim,1);

    for zDim = 1:maxdim
        fn              = [project '_' ...
                           name_save_file '_' settings.namevar '_' ...
                           sprintf('%02d',zDim) '.mat'];

        fprintf('Will load from %s\n', fn);
        try
            % Load saved model parameters and info
            tmp = load([savepath fn], 'M');
            M{zDim} = tmp.M.all;
            % Get the likelihood train as a matrix, with folds on one axis,
            % iteration steps on the other axis (transpose either cell contents
            % or cell indexing)
            % tr = cellfun(@transpose,M{zDim}.like_train,'un',0);
            like_train{zDim} = sum(cell2mat(M{zDim}.like_train'),1);
            like_test{zDim} = sum(M{zDim}.like_test,2);
            % alternative to sum: nanmean
        catch ME
            like_train{zDim} = nan(1,200); %sum(nan(max_iter,settings.nFolds),1);
            like_test{zDim} = nan;
            fprintf('file not found: %s', ME.message);
        end
        legend_{zDim} = sprintf('%02d', zDim);
    end

    like_train = cell2mat(like_train); %#ok<NASGU>
    like_test = cell2mat(like_test); %#ok<NASGU>
    fn              = [project '_' ...
                       name_save_file '_' settings.namevar '_' ...
                       'dim' '.mat'];
    try
        save([savepath fn], 'like_train', 'like_test', 'legend_');
    catch ME
        disp('project not found: %s', EM.message);
    end

end


%%
% ========================================================================%
%============== (3)     Load all data             ========================%
%=========================================================================%


like_train = {};
like_test = {};
legend_ = {};

for i_animal = 1:length(files)
    project         = regexprep(animals{i_animal},settings.pattern,'$1');
    savepath        = [workpath project '/'];

    fn              = [project '_' ...
                       name_save_file '_' settings.namevar '_' ...
                       'dim' '.mat'];

    fprintf('Will load from %s\n', fn);
    try
        tmp = load([savepath fn]);
        like_train{end+1} = tmp.like_train(:,end); %#ok<SAGROW>
        like_test{end+1} = tmp.like_test(:,end); %#ok<SAGROW>
        
        legend_{end+1} = project; %#ok<SAGROW>
    catch EM
        fprintf('file not found: %s', EM.message);
    end
end


%%
% ========================================================================%
%============== (4)   Plot dim estimates          ========================%
%=========================================================================%


fign = sprintf('%s_all',settings.paradigm);
%plot(bsxfun(@minus,cell2mat(like_test),nanmean(cell2mat(like_test),1)),'-');
plot(cell2mat(like_test),'-');
legend(legend_{:},'Location','southeast');
xlabel('#latent dimensions for GPFA');
ylabel('cross-validated log likelihood');
savefig([fign '.fig']);
saveas(gcf,[fign '.png'],'png');
saveas(gcf,[fign '.pdf'],'pdf');

%======================== Plot per synthetic dim ==========================

if strcmp(settings.paradigm,'viewing')
    files_per_dim = 6;
    offset = 1;
else
    files_per_dim = 5;
    offset = 2;
end

for idim = offset:files_per_dim:length(files)
    fdim = min((idim+files_per_dim-1),length(files));
    fign = sprintf('%s_%d',settings.paradigm,idim);
    data = cell2mat(like_test(idim:fdim));
    idx = ~isnan(data(:,1));
    plot(find(idx),normalize(data(idx,:),1),'-');
    legend(legend_(idim:fdim),'Location','southeast');
    xlabel('#latent dimensions for GPFA');
    ylabel('cross-validated log likelihood (arbitrary scale)');
    xlim([0,21]);
    savefig([fign '.fig']);
    saveas(gcf,[fign '.png'],'png');
    saveas(gcf,[fign '.pdf'],'pdf');
end

% dimensions in rows, files in columns
alike = cell2mat(like_test);

save([workpath 'dimensionality.dat'],'alike','-ascii');

function Xtats = classGPFAimproved(P, models, varargin)
%CLASSGPFA  Given a data struct P containing spike count vectors and GPFA models, this file computes a
%           binary classification as the argmax P(data|each_model).
%
%           INPUTS:
%           P           : DataHigh type struct of dimension (1 x num events)
%           folds       : number of folds used for crossvalidation during training
%           debug       : shows debugging and verbose output
%           models      : cell containing trained GPFA models with dimension (1 x num models)
%
%           OUTPUT:
%           stats       : a struct with dimensions (1 x folds) including the fields
%                       conf_matrix, class_output, real_label, and posterior, which are
%                       the classification confusion matrix where positive samples correspond
%                       to right alternations whereas negative samples are left alternations;
%                       output of the classifier {1:right, 2:left}, real label, and the
%                       log posterior P(data|param).
%
%
%Version 1.0 Marcell Stippinger, 2016
scaleK       = 1.0;
scaleRate    = 1.0;
scaleVar     = 1.0;
labelField   = 'type';

useAllTrials = false;
mergeTrials  = false;
assignopts(who,varargin);

folds        = length(models{1}.params);
scale        = (scaleK ~= 1.0) || (scaleRate ~= 1.0) || (scaleVar ~= 1.0);
if scale
    fprintf('Scaling the GP Kernel with %2.2f, rates with %2.2f\n',scaleK, scaleRate);
end
if useAllTrials
    disp('Warning: Using all the trials for testing');
end

n_laps      = length(P);
v_laps      = [P.trialId];
model_like  = zeros(length(models), n_laps);
model_tol   = zeros(length(models), n_laps);

% TODO: do the folds in parallel instead of the models.
parfor i_model = 1 : length(models)
    fprintf('%d',i_model);
    %likelikehood   = -Inf*ones(folds, n_laps);
    likelikehood   = nan(folds, n_laps);

    for ifold = 1 : folds
        
        if ~useAllTrials
            %remove trials used during training
            usedlaps    = models{i_model}.trainTrials{ifold};
            unseenP     = ones(1,n_laps);
            for u = usedlaps
                unseenP(v_laps == u) = 0;
            end
            unseenP = find(unseenP ==1);
        else
            unseenP = 1:n_laps;
        end

        %select the model parameters from the fold#1 
        param = models{i_model}.params{ifold};
        keep_neurons = models{i_model}.keep_neurons;
        %rescale time scale of the GP if needed.
        if scale
           param.gamma = param.gamma .* (scaleK .^ 2);
           param.d = param.d .* sqrt(scaleRate);
           param.C = param.C .* sqrt(scaleRate);
           param.R = param.R .* sqrt(scaleVar);
        end
        
        if ~mergeTrials
            %for p = 1 : length(unseenP) 
                %lap   = unseenP(p);
            [tmp, originals] = reshape_laps(P(unseenP), keep_neurons, 100);
            [tmptraj, tmpll] = exactInferenceWithLLperTrial(tmp, param,'getLL',1);      
            fprintf('.');
            for p = 1 : length(unseenP)
                lap   = unseenP(p);
                sel   = originals == p;
                likelikehood(ifold,lap) = sum([tmptraj(sel).LL]) / sum([tmptraj(sel).T]) ;
            end
        else
            % evaluating trials together involves one inversion only for
            % laps of same length but ll will also be identic
            tmp = reshape_laps(P(unseenP), keep_neurons, 100);
            [tmptraj, ll] = exactInferenceWithLLperTrial(tmp, param,'getLL',1);
            likelikehood(ifold,unseenP) = ll / sum([tmp.T]);
            fprintf('*');
        end
        fprintf('\n');
        
    end
    
    %model_like(m,:) = max(likelikehood);
    model_like(i_model,:) = nanmean(likelikehood);
    model_tol(i_model,:) = (nanmax(likelikehood)-nanmin(likelikehood))/(folds-1);
end

[~, max_mod]    = max(model_like);

type            = [P.(labelField)]; %{P(proto|param) , realtag}


TP            = sum(max_mod == 1 & type == 1)/(sum(type == 1));
FN            = sum(max_mod == 2 & type == 2)/(sum(type ~= 1));
FP            = sum(max_mod == 1 & type == 2)/(sum(type == 2));
TN            = sum(max_mod == 2 & type == 1)/(sum(type ~= 2));

Xtats.conf_matrix    = [TP, FP; TN, FN];
% suggested Xtats.conf_matrix    = confusionmat(Xtats.real_label,Xtats.class_output);
Xtats.class_output   = max_mod;
Xtats.real_label     = type;
Xtats.likelihood     = model_like;
Xtats.tolerance      = model_tol;

%fprintf('Fold %d done\n',ifold)

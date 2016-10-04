function Xtats = classGPFA(P, models, varargin)
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
%Version 1.0 Ruben Pinzon@2015
scaleK       = 1.0;
scaleRate    = 1.0;
scaleVar     = 1.0;

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
    
for m = 1 : length(models)
    fprintf('%d',m);
    %likelikehood   = -Inf*ones(folds, n_laps);
    likelikehood   = nan(folds, n_laps);

    for ifold = 1 : folds
        
        if ~useAllTrials
            %remove trials used during training
            usedlaps    = models{m}.trainTrials{ifold};
            unseenP     = ones(1,n_laps);
            for u = 1 : length(usedlaps)
                %u_idx = find(v_laps == usedlaps(u));
                %unseenP(u_idx) = 0;
                unseenP(v_laps == usedlaps(u)) = 0;
            end
            unseenP = find(unseenP ==1);
        else
            unseenP = 1:n_laps;
        end

        %select the model parameters from the fold#1 
        param = models{m}.params{ifold};
        keep_neurons = models{m}.keep_neurons;
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
            like = nan(n_laps);
            parfor p = 1 : length(unseenP)
                lap   = unseenP(p);

                tmp = reshape_laps(P(lap), keep_neurons, 100);
                [traj, ll] = exactInferenceWithLL(tmp, param,'getLL',1);       
                %likelikehood(ifold,lap) = ll / sum([tmp.T]);
                like(p) = ll / sum([tmp.T]);
                %likelikehood(ifold,lap) = ll;
                fprintf('.');
            end
            for p = 1 : length(unseenP)
                lap   = unseenP(p);
                likelikehood(ifold,lap) = like(p);
            end
        else
            % evaluating trials together involves one inversion only for
            % laps of same length but ll will also be identic
            tmp = reshape_laps(P(unseenP), keep_neurons, 100);
            [traj, ll] = exactInferenceWithLL(tmp, param,'getLL',1);
            likelikehood(ifold,unseenP) = ll / sum([tmp.T]);
            fprintf('*');
        end
        fprintf('\n');
        
    end
    
    %model_like(m,:) = max(likelikehood);
    model_like(m,:) = nanmean(likelikehood);
    model_tol(m,:) = (nanmax(likelikehood)-nanmin(likelikehood))/(folds-1);
end

[~, max_mod]    = max(model_like);

type            = [P.type]; %{P(proto|param) , realtag}


TP            = sum(max_mod == 1 & type == 1)/(sum(type == 1));
FN            = sum(max_mod == 2 & type == 2)/(sum(type ~= 1));
FP            = sum(max_mod == 1 & type == 2)/(sum(type == 2));
TN            = sum(max_mod == 2 & type == 1)/(sum(type ~= 2));

Xtats.conf_matrix    = [TP, FP; TN, FN];
Xtats.class_output   = max_mod;
Xtats.real_label     = type;
Xtats.likelihood     = model_like;
Xtats.tolerance      = model_tol;

%fprintf('Fold %d done\n',ifold)

function gpfaCompare(Model1, Model2)
%gpfaCompare(fileToRead1, fileToRead2) compares the parameters of two
%stored models
%
%  Imports data from the specified files and plots histogram of the ratios
%  of d, C, R and tau. Note, that while neurons are increasingly orddered
%  and therefore identic sets are matched, latent dimensions in d and C
%  might be unmatched in the two models. The same, no effort is made to
%  match CV folds to contain the same laps. Irrespective of this these
%  plots can give a hint on the rescaling.
%
%  Usage example:
%    gpfaCompare('~/marcell/napwigner/work/spike_SPW_D2_L4/spike_SPW_D2_L4_trainedGPFA_05.mat',...
%                '~/marcell/napwigner/work/spike_RUN_D2_L4/spike_RUN_D2_L4_trainedGPFA_05.mat')
%
%  Marcell Stippinger, 27-Apr-2016

common_neurons = Model1.keep_neurons & Model2.keep_neurons;
keep1 = Model1.keep_neurons(common_neurons);
keep2 = Model2.keep_neurons(common_neurons);

i = 1; j = 1;

Params1.d = Model1.params{i}.d(keep1);
Params1.C = Model1.params{i}.C(keep1,:);
Params1.R = Model1.params{i}.R(keep1,keep1);
Params1.gamma = Model1.params{i}.gamma;

Params2.d = Model2.params{j}.d(keep2);
Params2.C = Model2.params{j}.C(keep2,:);
Params2.R = Model2.params{j}.R(keep2,keep2);
Params2.gamma = Model2.params{i}.gamma;

% Create new variables in the base workspace from those fields.
% find the corresponding permutation:
P = Params1.C \ Params2.C
% show similarity
S = Params1.C' * Params2.C;

nfolds = 1;
ratio_d = cell(1,nfolds);
ratio_C = cell(1,nfolds);
ratio_R = cell(1,nfolds);
ratio_R_diag = cell(1,nfolds);
ratio_tau = cell(1,nfolds);
for i = 1:nfolds
    ratio_d{i} = Params1.d ./ Params2.d;
    ratio_C{i} = (Params1.C*P) ./ Params2.C;
    ratio_R{i} = Params1.R ./ Params2.R;
    ratio_R_diag{i} = diag(ratio_R{i});
    % NOTE: mixing time scales is not justified at all, in addition it can
    % lead to negative timescales
    ratio_tau{i} = sqrt((Params1.gamma) ./ Params2.gamma);
end

figure();
a1 = subplot(3,2,1); hold on;
image(P,'CDataMapping','scaled')
caxis([-1,2]);
colorbar
xlabel('latent dim of M_2'); ylabel('latent dim of M_1'); title({'Permutation','M_1.C * P = M_2.C'});
hold off;

a2 = subplot(3,2,2); hold on;
image(S,'CDataMapping','scaled')
colorbar
xlabel('latent dim of M_2'); ylabel('latent dim of M_1'); title({'Similarity', 'M_1.C ^T * M_2.C'});
hold off;

subplot(3,2,3); hold on;
histogram([ratio_d{:}],linspace(0,8,81));
plot(mean(cell2mat(ratio_d)),1,'rx',median(cell2mat(ratio_d)),2,'bo');
xlabel('ratio M_1/M_2'); ylabel('count'); title({'d: expected value','(per CV fold)'});
hold off;

subplot(3,2,4); hold on;
histogram([ratio_C{:}],linspace(0,8,81));
plot(mean(cell2mat(ratio_C)),1,'rx',median(cell2mat(ratio_C)),2,'bo');
xlabel('ratio M_1/M_2'); ylabel('count'); title({'C: transformation','(per CV fold per latent dim)'});
hold off;
% note the ordering of latent dimensions might differ

subplot(3,2,5); hold on;
histogram([ratio_R_diag{:}],linspace(0,8,81));
plot(mean(cell2mat(ratio_R_diag)),1,'rx',median(cell2mat(ratio_R_diag)),2,'bo');
xlabel('ratio M_1/M_2'); ylabel('count'); title({'R: variance','(per CV fold)'});
hold off;

subplot(3,2,6); hold on;
histogram([ratio_tau{:}],linspace(0,32,81));
plot(mean(cell2mat(ratio_tau)),1,'rx',median(cell2mat(ratio_tau)),2,'bo');
xlabel('ratio M_1/M_2'); ylabel('count'); title({'1/tau: inverse timescale','(per CV fold per latent dim)'});
legend('count','mean','median');
hold off;

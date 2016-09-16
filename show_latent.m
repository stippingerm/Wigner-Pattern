function [Xorth, Vorth] = show_latent(model, data, colors, labels, TrialType_tx, annotation)
%SHOW_LATENT shows the latent trajectories in the 3D space defined by the 3
%       largest singe values decomposition vectors of A in the model Y = Cx+d+e
%       inputs:
%
%
%       model : {1 x n_models} : parameters of the GPFA model {C, d, R, gamma, eps, covType}
%       data  : {1 x n_models} : including the field y(binned spike bins)
%
%Ruben Pinzon@2015


%twoNorm = sqrt(sum(abs(M).^2,1)); %# The two-norm of each column
%pNorm = sum(abs(M).^p,1).^(1/p);  %# The p-norm of each column (define p first)
%infNorm = max(M,[],1);            %# The infinity norm (max value) of each column

n_models = length(model);
fprintf('%d models provided\n',n_models);
figure
for m = 1 : n_models    
    Params   = model{m}.params{1}; % fold #1
    traj     = exactInferenceWithLL(data, Params,'getLL',0);
    % the concatenation of pieces is not entirely justified (they might be
    % not adjoint, and even if they are the boundaries do not align smoothly)
    x        = orthogonalize([traj.xsm], Params.C);     
    Xorth{m} = x;
    v_vect   = [zeros(size(x,1),1) x(:,2:end)-x(:,1:end-1)];
    v_scalar = sqrt(sum(abs(v_vect).^2,1));
    acc_dist = cumsum([0 v_scalar]);
    Vorth{m} = v_vect;
    
    T              = [0 cumsum([traj.T])];
        
    set(gcf, 'position', [1,1,1424,973], 'color', 'w')
       
    start_traj  = []; end_traj = [];
    for ilap = 1 : length(traj)
       lap_t = T(ilap)+1:T(ilap+1);   
       c        = colors(labels(ilap),:); %this color is model, has to be the trial type

       plot_xorth(x(1,lap_t),x(2,lap_t),x(3,lap_t),[1 2 4 5 7 8],{'{\itx}_0','{\itx}_1','{\itx}_2'},c,num2str(traj(ilap).trialId))
       plot_xorth(x(1,lap_t),x(2,lap_t),[],3,{'{\itx}_0','{\itx}_1'},c)
       plot_xorth(x(2,lap_t),x(3,lap_t),[],6,{'{\itx}_1','{\itx}_2'},c)
       plot_xorth(x(1,lap_t),x(3,lap_t),[],9,{'{\itx}_0','{\itx}_2'},c)
      
    end
    
    if nargin>5
        markers = { 'bo', 'mx' };
        for i = 1:max(annotation)
            sel = annotation==i;
            z = x(:,sel);
            z = [z nan(size(x))];
            z = reshape(z,size(x,1),[]);
            subplot(3,3,[1 2 4 5 7 8])
            plot3(z(1,:),z(2,:),z(3,:),markers{i})
        end
    end
    
    %covariance ellipses    
    clear x traj
end

% subplot(3,3,[1 2 4 5 7 8])
% leg = gobjects(1,length(colors));
% for c = 1: length(colors)
%     plt=plot([nan,nan],[nan,nan],'pk', 'markersize',14, 'MarkerFaceColor',colors(c,:));
%     leg(1,c) = plt;
% end
% % WONTFIX: Legend to a spanning subplot brakes some Matlab callback functions
% legend(leg, TrialType_tx, 'Location', 'southoutside')

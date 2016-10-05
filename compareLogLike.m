function compareLogLike(D, Xtats, label) 
%Auxiliary function to plot the likelihood after class with the GPFA.
%
%
%Ruben Pinzon
figure,hold on
set(gcf, 'color','w')

%plot(Xtats.likelihood','-o')
[nModels, nTrials] = size(Xtats.likelihood);
if nTrials<80
    capSize = 6;
    xlim([0 length(D)+1]);
else
    capSize = 2;
    xlim([0 60]);
end
e = errorbar(repmat(1:nTrials,nModels,1)',Xtats.likelihood',Xtats.tolerance','-o');
    %'CapSize',capSize); % for Matlab 2016b and later
%size(e)
%for i_model = 1:nModels
%    he = e(i_model)
%    adjustErrorBarWidth(he, -0.5);
%end
xlabel('Trials')
ylabel('LogLikelihood')
legend(label.model,...
       'Location','NW')
twoModels = size(Xtats.likelihood,1)>1;   

ypos_output = min(min(Xtats.likelihood));
ypos_real = 0.1 * max(max(Xtats.likelihood)) + 0.9*min(min(Xtats.likelihood));
for t = 1 : nTrials
  typeAssigned = sprintf('%d',Xtats.class_output(t));
  if twoModels
      c = 'r';
      if Xtats.class_output(t) == Xtats.real_label(t);
          c = 'k';
      end
  else
      c = 'k';
      if Xtats.real_label(t) == 1;
          c = 'r';
      end
      
  end
  text(t, ypos_output, typeAssigned, 'color',c)
  text(t, ypos_real, num2str(Xtats.real_label(t)),'color',[1 0 1])

  if nTrials<80
    line([t+0.5 t+0.5],ylim,'linestyle','--','color',[0.6 0.6 0.6])
  end
end

set(gca,'xticklabel',[D.trialId],'xtick',1:length([D.trialId]),'xticklabelrotation',45)

set(gca,'fontsize',14)
xlabel(label.xaxis,'fontname','Georgia')
ylabel(label.yaxis,'fontname','Georgia')
title(label.title)


function adjustErrorBarWidth(hErrBar, adj)
% for Matlab 2014a and earlier
hb = get(hErrBar,'children');  
Xdata = get(hb(2),'Xdata');

temp = 4:3:length(Xdata);
temp(3:3:end) = [];

xleft = temp; xright = temp+1;

Xdata(xleft) = Xdata(xleft) - adj/2;
Xdata(xright) = Xdata(xright) + adj/2;

%// Update
set(hb(2),'Xdata',Xdata)
function compareLogLike(D, Xtats, label) 
%Auxiliary functio to plot the likelihood after class with the GPFA.
%
%
%Ruben Pinzon
figure,hold on
set(gcf, 'color','w')

plot(Xtats.likelihood','-o')
xlabel('Trials'), xlim([0 length(D)+1]), 
ylabel('LogLikelihood')
legend(label.modelA,label.modelB,...
       'Location','NW')
   
   
for t = 1 : length(Xtats.likelihood)
  typeAssigned = '2';
  
  if Xtats.likelihood(1,t) > Xtats.likelihood(2,t)
     typeAssigned = '1'; 
  end
  c = 'r';
  if Xtats.class_output(t) == D(t).type
      c = 'k';
  end
  text(t, min(min(Xtats.likelihood)), typeAssigned, 'color',c)
  line([t+0.5 t+0.5],ylim,'linestyle','--','color',[0.6 0.6 0.6])
end

set(gca,'xticklabel',[D.trialId],'xtick',1:length([D.trialId]),'xticklabelrotation',45)

set(gca,'fontsize',14)
xlabel(label.xaxis,'fontname','Georgia')
ylabel(label.yaxis,'fontname','Georgia')
title(label.title)
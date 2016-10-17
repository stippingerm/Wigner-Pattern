function LDAplot(xdata, ydata, class, label, styles)
% Perform LDA plot where xdata, ydata and class are vectors of the same size [1xN double] 
%           where N is the number of samples.
%
%Stippinger Marcell

figure(); hold on

for i = 1:max(class)
    style = styles{i};
    scatter(xdata(class==i),ydata(class==i), [], style{:});
end

mm = minmax([xdata, ydata]);
xlim(minmax(xdata))
ylim(minmax(ydata))
plot(mm, mm, 'k--');

%lgd = legend({'i \in on','i \in pre','i \in post'},'Location','southeast');
  
line([-15000 15000], [-15000 15000], 'linestyle','--','color',[0.1 0.1 0.1])
grid on

set(gca,'fontsize',14)
xlabel(label.xaxis,'fontname','Georgia')
ylabel(label.yaxis,'fontname','Georgia')
title(sprintf('%s',label.title))
set(gca,'dataaspectratio',[1 1 1])


function mm = minmax(s)
mm = [ min(s), max(s) ];

function fig_export(fig, fn, widthmm, heightmm, varargin)
% FIG_EXPORT sets all parameters then exports the figure to specified
% formats.
%
% Litterature:
% http://www.mathworks.com/help/matlab/ref/print.html
% http://www.mathworks.com/help/matlab/ref/saveas.html
% http://www.mathworks.com/help/matlab/creating_plots/save-figure-with-minimal-white-space.html
% confirmation that PaperPosition does not allow scaling:
% http://www.mathworks.com/matlabcentral/answers/26903-exporting-image-to-bounded-pdf
% http://www.mathworks.com/matlabcentral/answers/173629-how-to-change-figure-size
% useful advices:
% https://dgleich.github.io/hq-matlab-figs/
% undocumented feature for specifyig screen resolution rather than relying on the OS:
% http://www.mathworks.com/matlabcentral/newsreader/view_thread/50029
% set(0,'ScreenPixelsPerInch',80)
%
% Marcell Stippinger, 2016

if widthmm < heightmm
    orientation = 'portrait';
else
    orientation = 'landscape';
end
formats = { 'fig', 'pdf' };
restore = false;

assignopts(who, varargin);

screen_unit = fig.Units;
set(fig,'Units','centimeters','PaperUnits','centimeters');
screen_pos = fig.Position;
set(fig,'Position',[screen_pos(1) screen_pos(2) widthmm*0.1 heightmm*0.1]);
set(fig,'PaperOrientation',orientation,'PaperPositionMode','auto');
paper_pos = fig.PaperPosition;
set(fig,'PaperSize',[paper_pos(3) paper_pos(4)]);

for i = 1:length(formats)
    saveas(fig, [fn '.' formats{i}], formats{i});
end

if restore
    % order of request is important
    set(fig,'Position',screen_pos);
    set(fig,'Units', screen_unit);
end

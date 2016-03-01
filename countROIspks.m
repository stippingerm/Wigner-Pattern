function count = countROIspks(x, y, grid, show)
%COUNTROISPKS Counts the spikes inside a grid partition
%
%   COUNT = countROIspks(x, y, grid, show)
%           x and y are the coordinates of the spike event
%           grid with dimension 2 x 5 x S, containes the
%           partitions of the area in S segments. Show enables the
%           ploting of the counting and ROI regions along with the spks
%
%Ruben Pinzon
%version 1.0 2015
    
    xcopy = x;
    ycopy = y;
    count = [];
    for iroi = 1 : size(grid,3)
        ROI = grid(:,:,iroi);
        insideIndex = inpolygon(x,y,ROI(1,:),ROI(2, :));
        %remove counted spikes
        x(insideIndex) = [];
        y(insideIndex) = [];
        count(iroi)    = sum(insideIndex); 
        if show
            centroid = polygonCentroid(ROI(1,:),ROI(2, :));
            text(centroid(1), centroid(2),num2str(count(iroi)), 'color', 'r')
            plot(ROI(1,:),ROI(2,:), 'r')
        end   
    end
    if show
        plot(xcopy, ycopy, 'x')
    end
end

function [centroid, area] = polygonCentroid(varargin)
    %POLYGONCENTROID Compute the centroid (center of mass) of a polygon
    %
    %   CENTROID = polygonCentroid(POLY)
    %   CENTROID = polygonCentroid(PTX, PTY)
    %   Computes center of mass of a polygon defined by POLY. POLY is a N-by-2
    %   array of double containing coordinates of vertices.
    %
    %   [CENTROID AREA] = polygonCentroid(POLY)
    %   Also returns the (signed) area of the polygon. 
    %
    %   Example
    %     % Draws the centroid of a paper hen
    %     x = [0 10 20  0 -10 -20 -10 -10  0];
    %     y = [0  0 10 10  20  10  10  0 -10];
    %     poly = [x' y'];
    %     centro = polygonCentroid(poly);
    %     drawPolygon(poly);
    %     hold on; axis equal;
    %     drawPoint(centro, 'bo');
    % 
    %   References
    %   algo adapted from P. Bourke web page
    %
    %   See also:
    %   polygons2d, polygonArea, drawPolygon
    %

    %   ---------
    %   author : David Legland 
    %   INRA - TPV URPOI - BIA IMASTE
    %   created the 05/05/2004.
    %

    % Algorithme P. Bourke, vectorized version

    % HISTORY
    % 2012.02.24 vectorize code


    % parse input arguments
    if nargin == 1
        var = varargin{1};
        px = var(:,1);
        py = var(:,2);
    elseif nargin == 2
        px = varargin{1};
        py = varargin{2};
    end

    % vertex indices
    N = length(px);
    iNext = [2:N 1];

    % compute cross products
    common = px .* py(iNext) - px(iNext) .* py;
    sx = sum((px + px(iNext)) .* common);
    sy = sum((py + py(iNext)) .* common);

    % area and centroid
    area = sum(common) / 2;
    centroid = [sx sy] / 6 / area;
end
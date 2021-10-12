
%
% Main function
%

function [peaks, widths, proms, angles] = Segment(x, y, preprocessing, filter, plotType)

	original_x = x;
	original_y = y;

	%
	% parameters
	%

	angleExtents = 1;
	minSegmentLength = 2;
	
	%
	% smoothing
	%

	if preprocessing == "smooth"
		x = smoothdata(x);
		y = smoothdata(y);
	elseif preprocessing ~= "none"
		throw(MException("Segment", "Incorrect preprocessing argument"));
	end

	%
	% peaks/widths/proms/angles
	%

	try
		movement = calculateNorms(x, y);
		[~, peaks, widths, proms] = findpeaks(-movement);
		widths = widths / 50;	% convert to seconds
	catch me
		disp("uh oh");
		peaks = [];
		widths = [];
		proms = [];
		angles = [];
		return
	end
	
	angles = calculateAngles(x, y, peaks, angleExtents, false);
	
	%
	% filtering
	%

	if filter == "threshold"
		isPeak = ThresholdFilter(widths, proms, angles);
	elseif filter == "performance"
		[isPeak, p] = PerformanceFilter(widths, proms, angles);
	elseif filter == "none"
		isPeak = repelem(true, length(peaks))';
	else
		throw(MException("Segment", "Incorrect filter argument"));
	end

	% add peaks to the start and end
	peaks	= [1;		peaks;	length(x)];
	widths	= [inf;		widths;	inf];
	proms	= [inf;		proms;	inf];
	angles	= [0;		angles;	0];
	isPeak	= [true;	isPeak;	true];
	
	%
	% combining
	%
	
	if filter == "performance"
		p = [1; p; 1];
		isPeak = combinePeaks(x, y, peaks, isPeak, p, minSegmentLength);
	end
	
	% cull peaks from filtering and combining
	peaks = peaks(isPeak);
	widths = widths(isPeak);
	proms = proms(isPeak);
	angles = angles(isPeak);
	
	%
	% plotting
	%

	if any(plotType == ["none" "basic" "indexed" "detailed"])
		
		hold on
		scatter(x, y);
		hold off
		
		if plotType == "basic"
			plotSegmentsBasic(x, y, peaks);
		elseif plotType == "indexed"
			plotSegmentsIndexed(x, y, peaks);
		elseif plotType == "detailed"
			
			calculateAngles(x, y, peaks, angleExtents, true);
			
			if filter == "performance"
				plotSegmentsBasic(x, y, peaks);
				PerformanceFilter(widths, proms, angles, x(peaks), y(peaks));
			else
				plotSegmentsDetailed(x, y, peaks, widths, proms);
			end
		end

		axis equal
		xlim([-25 25])
		ylim([-25 25])
	else
		throw(MException("Segment", "Incorrect plot argument"));
	end
end

%
% Math functions
%

function norms = calculateNorms(x, y)
	xd = diff(x) .^ 2;
	yd = diff(y) .^ 2;
	norms = sqrt(xd + yd);
end

%
% Calculate Angles
%

function thetas = calculateAngles(x, y, segments, threshold, plotTriangles)

	thetas = zeros(length(segments), 1);

	ti = 1;
	for indexA = segments'
		
		[indexB, indexC] = findTrianglePoints(x, y, indexA, threshold);
		
		% calculate angle of triangle at segment
		sideAB = norm([x(indexB) - x(indexA), y(indexB) - y(indexA)]);
		sideBC = norm([x(indexC) - x(indexB), y(indexC) - y(indexB)]);
		sideCA = norm([x(indexA) - x(indexC), y(indexA) - y(indexC)]);
		thetas(ti) = acos((sideCA ^ 2 + sideAB ^ 2 - sideBC ^ 2) / (2 * sideCA * sideAB));
		thetas(ti) = rad2deg(thetas(ti));
		
		if plotTriangles
			hold on
			p = plot(x([indexA indexB indexC indexA]), y([indexA indexB indexC indexA]));
			p.Color = [1 0 0];
			p.LineWidth = 1;

			%text(x(indexA) + 0.5, y(indexA) - 2.25, string(thetas(ti)));
			hold off
		end
		
		ti = ti + 1;
	end
end

function [left, right] = findTrianglePoints(x, y, i, threshold)

	left = 1;
	right = length(x);
	
	for j = i-1:-1:1
		distance = norm([x(j) - x(i), y(j) - y(i)]);
		if distance > threshold
			left = j;
			break;
		end
	end

	for j = i+1:length(x)
		distance = norm([x(j) - x(i), y(j) - y(i)]);
		if distance > threshold
			right = j;
			break;
		end
	end
end

%
% Combine peaks
%

function isPeak = combinePeaks(x, y, peaks, isPeak, p, minLength)
	
	% bundles are groups of peaks that are within 
	% some threshold of each other
	bundleIndex = 1;
	bundles = {};
	
	% calculate distances between each peak
	distances = calculateNorms(x(peaks(isPeak)), y(peaks(isPeak)));
	
	% find bundles
	for i = 1:length(distances)
		
		if distances(i) < minLength
			
			if length(bundles) < bundleIndex
				bundles{bundleIndex} = [];
			end
			
			n0 = findNth(isPeak, i);
			n1 = findNth(isPeak, i+1);
			bundles{bundleIndex} = [bundles{bundleIndex} n0 n1];
		else
			bundleIndex = length(bundles) + 1;
		end
	end

	% remove all but best peaks of each bundle
	for bundle = bundles
		b = bundle{1};
		b = unique(b);
		
		[~, i] = max(p(b));
		b(i) = [];
		isPeak(b) = false;
	end
	
end

function i = findNth(vs, n)
	
	c = 0;
	i = 0;
	while c < n
		
		i = i + 1;
		
		if vs(i)
			c = c + 1;
		end
	end
end

%
% Plot functions
%

function s = plotSegmentsBasic(x, y, segments)
	hold on
	s = scatter(x(segments), y(segments));
	s.MarkerFaceColor = [0 0 0];
	s.MarkerEdgeColor = [0 0 0];
	hold off
end

function plotSegmentsIndexed(x, y, segments)
	plotLabelledSegments(x, y, segments, 1:length(segments), .5, 0);
end

function plotSegmentsDetailed(x, y, segments, widths, proms)
	plotLabelledSegments(x, y, segments, 1:length(segments),	.5, 0);
	plotLabelledSegments(x, y, segments, proms,					.5, -.75);
 	plotLabelledSegments(x, y, segments, widths,				.5, -1.5);
 	
% 	lengths = [calculateNorms(x(segments), y(segments)); 0];
% 	plotLabelledSegments(x, y, segments, lengths,				.5, -2.25);
end

function plotLabelledSegments(x, y, segments, labels, xLabelOffset, yLabelOffset)
	hold on
	s = scatter(x(segments), y(segments));
	s.MarkerFaceColor = [0 0 0];
	s.MarkerEdgeColor = [0 0 0];

	text(x(segments) + xLabelOffset, y(segments) + yLabelOffset, string(labels));
	hold off
end

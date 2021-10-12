function isPeak = ThresholdFilter(widths, proms, angles)

	isPeak = false;
	isPeak = isPeak | proms > 0.25;	% most likely peak if prominence greater than 0.25
	isPeak = isPeak | angles < 120; % most likely peak if curve is less than 120 degrees
	isPeak = isPeak & proms > 0.05; % probably not peak if prominence is less than 0.05
	isPeak = isPeak & widths > 0.1; % probably not peak if width is less than 0.1 seconds

end

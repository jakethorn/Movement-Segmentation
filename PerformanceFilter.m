
function [isPeak, p] = PerformanceFilter(widths, proms, angles, x, y)

	%
	% feature weights
	%

	w_coeff = 2;
	p_coeff = 1;
	a_coeff = 4;
	
	%
	% accuracy threshold
	%
	
	threshold = 0.6

	%
	% probability
	%
	
	widths = normalise(log(widths), -4.622, 4.164) * w_coeff;
	proms = normalise(log(proms), -11.511, 1.318) * p_coeff;
	angles = ((1 - angles / 180) .^ .2) * a_coeff;
	
	p = (widths + proms + angles) / (w_coeff + p_coeff + a_coeff);
	
	isPeak = p > threshold;
	%isPeak = kmeans([widths proms angles], 2) ~= 1;
	
	%
	% plot probabilities
	%
	
	if exist("x", "var") == 1 && exist("y", "var") == 1
		hold on
		text(x + .5, y - 0.00, string(p), "FontWeight", "bold");
% 		text(x + .5, y - 0.75, string(widths), "FontWeight", "bold");
% 		text(x + .5, y - 1.50, string(proms), "FontWeight", "bold");
% 		text(x + .5, y - 2.25, string(angles), "FontWeight", "bold");
		hold off
	end
end

function val = normalise(val, min, max)
	val = (val - min) ./ (max - min);
end

function drawRewardFeedback(in, sM)
	% drawRewardFeedback(in, sM)
	arguments(Input)
		in struct
		sM (1,1) screenManager
	end

	persistent currentCount isAnimating
	if isempty(currentCount); currentCount = 0; end
	if isempty(isAnimating); isAnimating = false; end

	if in.drawRewards

	end

end
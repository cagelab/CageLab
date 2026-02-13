%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% make sure the subject is NOT touching the screen
function r = ensureTouchRelease(r, tM, sM, afterResult)
	% r = ensureTouchRelease(r, tM, sM, afterResult)
	arguments(Input)
		r struct
		tM touchManager
		sM screenManager
		afterResult logical = false
	end
	arguments(Output)
		r struct
	end
	if ~afterResult; when="BEFORE"; else; when="AFTER"; end
	if ~isempty(r.sbg); draw(r.sbg); else; drawBackground(sM, [0 0 0]); end
	drawText(sM,'Please release touchscreen...');
	svbl = flip(sM); now = svbl; grn = 0;
	while isTouch(tM)
		if (now - svbl >= 1)
			drawBackground(sM,[1 grn 1]);
			flip(sM);
			grn = abs(~grn);
		end
		if afterResult && now - svbl > 3
			r.result = -1;
			fprintf("INCORRECT: Subject kept holding screen %s trial for %.1fsecs...\n", when, now-svbl);
			break;
		end
		now = WaitSecs(0.1);
		if grn; fprintf("Subject holding screen %s trial end %.1fsecs...\n", when, now-svbl); end
	end
	if ~isempty(r.sbg); draw(r.sbg); else; drawBackground(sM, [0 0 0]); end
	flip(sM);
end
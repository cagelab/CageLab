function startVisualOddball(in)
	% startVisualOddball(in)
	% Start a simple Visual Oddball task.
	%
	% The subject must touch the screen when a "deviant" (oddball) stimulus appears,
	% and refrain from responding to the frequent "standard" stimulus.
	%
	% in comes from CageLab GUI or can be a struct with the following fields:
	%   in.task = 'oddball'
	%   in.deviantProbability = 0.2        % proportion of deviant trials (default 0.2)
	%   in.objectSize = 8                  % size of stimuli in degrees (default 8)
	%   in.deviantSize = 8                 % size of deviant (default same as standard)
	%   in.standardY = 0                   % Y position of stimuli in degrees
	%   in.deviantY = 0                   % Y position of deviant (default same)
	%   in.trialTime = 5.0                 % max trial time in seconds
	%   in.targetHoldTime = 0.2            % target hold time in seconds
	%   in.folder = 'C:\data\stimuli'       % folder containing object images
	%   in.fixSize = 2                     % fixation size in degrees
	%   in.stimulus = 'Disc'               % 'Disc' or 'Picture' (default 'Disc')
	%   in.standardColour = [1 1 1]        % RGB colour of standard (default white)
	%   in.deviantColour = [1 0 0]         % RGB colour of deviant (default red)
	%   in.standardShape = 'circle'        % shape name for standard (default circle.png)
	%   in.deviantShape = 'triangle2'      % shape name for deviant (default triangle2.png)
	%
	% Outputs: none (runs as a blocking task)

	if ~exist('in','var'); in = struct('task','oddball'); end
	in = clutil.checkInput(in);
	bgName = 'abstract5.jpg';
	prefix = 'VODD';

	try
		%% ============================ subfunction for shared initialisation
		[sM, aM, rM, tM, r, dt, in] = clutil.initialise(in, bgName, prefix);

		%% ============================ task specific stimulus setup
		% Standard stimulus
		if matches(in.stimulus, 'Picture')
			standard = imageStimulus('size', in.objectSize, ...
				'filePath', [in.folder filesep 'shapes' filesep in.standardShape], ...
				'crop', 'square', 'circularMask', true, ...
				'xPosition', 0, 'yPosition', in.standardY);
			deviant = imageStimulus('size', in.deviantSize, ...
				'filePath', [in.folder filesep 'shapes' filesep in.deviantShape], ...
				'crop', 'square', 'circularMask', true, ...
				'xPosition', 0, 'yPosition', in.deviantY);
		else
			standard = discStimulus('size', in.objectSize, 'colour', in.standardColour, ...
				'xPosition', 0, 'yPosition', in.standardY);
			deviant = discStimulus('size', in.deviantSize, 'colour', in.deviantColour, ...
				'xPosition', 0, 'yPosition', in.deviantY);
		end
		if in.debug; standard.verbose = true; deviant.verbose = true; end

		% MetaStimulus container
		% Index 1 = standard, Index 2 = deviant
		stims = metaStimulus('stimuli', {standard, deviant});
		stims.edit(1:2, 'xPosition', 0);

		%% ============================ setup stimuli
		setup(r.fix, sM);
		setup(stims, sM);
		hide(stims);

		%% ============================ pre-compute trial type probabilities
		nTrialsPerBlock = 20;
		deviantProb = in.deviantProbability;
		standardProb = 1 - deviantProb;
		nDeviantPerBlock = max(1, round(nTrialsPerBlock * deviantProb));
		nStandardPerBlock = nTrialsPerBlock - nDeviantPerBlock;

		fprintf('===> Visual Oddball: deviantProb=%.0f%%, %i deviants / %i standards per block\n', ...
			deviantProb * 100, nDeviantPerBlock, nStandardPerBlock);

		%% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
		%% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
		while r.keepRunning

			%% ============================== build a block of trials
			% Each block has a fixed proportion of deviant/standard, shuffled
			trialTypes = [repmat("standard", 1, nStandardPerBlock), ...
						 repmat("deviant",   1, nDeviantPerBlock)];
			trialTypes = trialTypes(:, randperm(length(trialTypes)));

			for itrial = 1:length(trialTypes)
				if ~r.keepRunning; break; end

				%% ============================== initialise trial variables
				r = clutil.initTrialVariables(r);
				txt = '';
				fail = false; hld = false;

				%% ============================== configure this trial's stimulus
				currentType = trialTypes(itrial);
				if matches(currentType, "deviant")
					showSet(stims, 2);   % show deviant only
					r.stimulus = 2;
					targetRadius = in.deviantSize / 2;
					r.store.isDeviant = true;
				else
					showSet(stims, 1);   % show standard only
					r.stimulus = 1;
					targetRadius = in.objectSize / 2;
					r.store.isDeviant = false;
				end
				update(stims);

				r.summary = sprintf("TrialType: %s", currentType);
				r.store.trialType = currentType;

				%% ============================== Wait for release
				r = clutil.ensureTouchRelease(r, tM, sM, false);

				%% ============================== Initiate a touch trial
				[r, dt, r.vblInitT] = clutil.initTouchTrial(r, in, tM, sM, dt);

				%% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
				% ======================= start actual stimulus presentation
				if matches(string(r.touchInit), "yes")

					% update trial number
					r.trialN = r.trialN + 1;
					r.touchResponse = '';

					%% ============================== update touch windows
					[x, y] = stims.getFixationPositions;
					tM.updateWindow(x, y, repmat(targetRadius, 1, length(x)), ...
						repmat(in.doNegation, 1, length(x)), ones(1, length(x)), true(1, length(x)), ...
						repmat(in.trialTime, 1, length(x)), ...
						repmat(in.targetHoldTime, 1, length(x)), ones(1, length(x)));

					%% ============================== display loop
					vbl = GetSecs;
					r.vblInit = vbl + r.sv.ifi;
					r.stimOnsetTime = vbl;
					syncTime(tM, r.vblInit);

					while isempty(r.touchResponse) && vbl <= (r.vblInit + in.trialTime)
						if ~isempty(r.sbg); draw(r.sbg); end
						draw(stims);
						if in.debug && ~isempty(tM.x) && ~isempty(tM.y)
							drawText(sM, txt);
							[xy] = sM.toPixels([tM.x tM.y]);
							Screen('glPoint', sM.win, [1 0 0], xy(1), xy(2), 10);
						end
						vbl = flip(sM);
						[r.touchResponse, hld, r.hldtime, rel, reli, se, fail, tch, negation] = ...
							testHold(tM, 'yes', 'no');
						if tch || negation
							r.reactionTime = vbl - r.vblInit;
							r.anyTouch = true;
						end
						if in.debug
							txt = sprintf('Response=%i x=%.2f y=%.2f h:%i ht:%.3f r:%i rs:%i s:%i fail:%i tch:%i', ...
								r.touchResponse, tM.x, tM.y, hld, r.hldtime, rel, reli, ...
								se, fail, tch);
						end
						[~,~,c] = KbCheck();
						if c(r.quitKey); r.keepRunning = false; break; end
						if c(r.shotKey); sM.captureScreen; end
					end

				end
				%% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

				%% ============================== record final timestamp
				r.vblFinal = GetSecs;
				r.value = hld;

				%% ============================== check result logic
				% For oddball: correct =
				%   deviant touched = hit     (touchResponse='yes' AND isDeviant)
				%   standard NOT touched = correct reject (touchResponse='no' AND standard)
				% Incorrect =
				%   deviant NOT touched = miss  (touchResponse='no' AND deviant)
				%   standard touched = false alarm (touchResponse='yes' AND standard)
				isDeviant = r.store.isDeviant;
				if matches(r.touchInit, 'no')
					r.result = -5;
				elseif fail || hld == -100
					r.result = 0;
				elseif matches(r.touchResponse, 'yes')
					if isDeviant
						r.result = 1;   % hit
					else
						r.result = 0;   % false alarm
					end
				else % no response
					if isDeviant
						r.result = 0;   % miss
					else
						r.result = 1;   % correct reject
					end
				end

				%% ============================== Wait for release
				r = clutil.ensureTouchRelease(r, tM, sM, true);

				%% ============================== update this trial's results
				[dt, r] = clutil.updateTrialResult(in, dt, r, sM, tM, rM, aM);

			end % itrial (block of trials)

		end % while keepRunning

		%% ================================ Shut down session
		clutil.shutDownTask(dt, in, r, sM, tM, rM, aM);

	catch ME
		getReport(ME)
		try writelines(sprintf("Error VODD: " + ME.Message), "~/cagelab-start.txt", WriteMode="append"); end %#ok<*TRYNC>
		try if in.remote; r.status.updateStatusToStopped(); end; end
		try clutil.broadcastTrial(in, r, dt, false); end
		try if IsLinux; system('xset s 300 dpms 600 0 0'); end; end
		try reset(stims); end
		try reset(r.fix); end
		try reset(r.rtarget); end
		try reset(r.sbg); end
		try close(sM); end
		try close(tM); end
		try close(rM); end
		try close(aM); end
		try Priority(0); end
		try ListenChar(0); end
		try RestrictKeysForKbCheck([]); end
		try ShowCursor; end
		rethrow(ME)
	end

end

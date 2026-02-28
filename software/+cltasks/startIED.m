function startIED(in)
	% startIED(in)
	% Start an Intra-Dimensional / Extra-Dimensional Set Shifting Task (CANTAB derivative)
	% in comes from CageLab GUI or can be a struct with the following fields:
	% Example:
	%   in = struct();
	%   in.taskType = 'sd'; % 'sd','sr','cd','cr','ids','idr','eds','edr'
	% in.taskType stage meanings (CANTAB IED sequence):
	%   sd  - Simple Discrimination: only shape varies; learn initial rule (shape dimension relevant).
	%   sr  - Simple Reversal: same stimuli as SD; reward contingency reverses to test reversal learning.
	%   cd  - Compound Discrimination: shape + color shown; shape remains relevant while color is an irrelevant distractor.
	%   cr  - Compound Reversal: same compound setup as CD; reward contingency reverses on the same relevant dimension.
	%   ids - Intra-Dimensional Shift: new exemplars on both dimensions; relevant dimension stays the same (shape).
	%   idr - Intra-Dimensional Reversal: same exemplars as IDS; contingency reverses within the same relevant dimension.
	%   eds - Extra-Dimensional Shift: new exemplars again; relevant dimension switches (shape -> color), testing set shifting.
	%   edr - Extra-Dimensional Reversal: same exemplars as EDS; contingency reverses after the extra-dimensional shift.
	%   in.objectSize = 10; % size of objects in degrees
	%   in.objectSep = 15; % separation of objects in degrees
	%   in.sampleY = 0; % vertical position of sample object in degrees
	%   in.trialTime = 5.0; % max trial time in seconds
	%   in.targetHoldTime = 0.2; % target hold time in seconds
	%   in.folder = 'C:\data\stimuli'; % folder containing object images
	%   in.fixSize = 2; % fixation size in degrees
	%   in.fixWindow = 4; % fixation window size in degrees
	%
	% 

	if ~exist('in','var') || isempty(in); in = struct(); end
	% Merge with checkInput defaults
	defIn = clutil.checkInput();
	fNames = fieldnames(defIn);
	for i = 1:numel(fNames)
		if ~isfield(in, fNames{i})
			in.(fNames{i}) = defIn.(fNames{i});
		end
	end

	if ~isfield(in, 'taskType') || isempty(in.taskType); in.taskType = 'sd'; end
	if ~isfield(in, 'sampleY'); in.sampleY = 0; end
	if ~isfield(in, 'objectSize'); in.objectSize = 10; end
	if ~isfield(in, 'objectSep'); in.objectSep = 15; end
	if ~isfield(in, 'targetHoldTime'); in.targetHoldTime = 0.2; end
	if ~isfield(in, 'useAlyx'); in.useAlyx = false; end
	bgName = 'creammarbleD.jpg';
	prefix = 'IED';
	in.distractorY = in.sampleY;

	try
		%% ============================subfunction for shared initialisation
		[sM, aM, rM, tM, r, dt, in] = clutil.initialise(in, bgName, prefix);

		%% ============================task specific figures
		% Define the universe of shapes and colors for the session
		% 6 Shapes, 6 Colors to comfortably support IDS and EDS shifts
		allShapes = ["circle.png", "rect3.png", "triangle2.png", "heptagon.png", "star.png", "random.png"];
		allColors = {[1 0 0], [0 1 0], [0 0 1], [1 1 0], [1 0 1], [0 1 1]};
		neutralColor = [0.5 0.5 0.5]; % Used for SD and SR stages

		% Shuffle to randomize dimension pairings for this specific session
		sessionShapes = allShapes(randperm(length(allShapes)));
		sessionColors = allColors(randperm(length(allColors)));

		% Pairings based on stage logic
		% Set 1: Used for SD, SR, CD, CR
		s1_shape1 = sessionShapes(1);
		s1_shape2 = sessionShapes(2);
		s1_color1 = sessionColors{1};
		s1_color2 = sessionColors{2};

		% Set 2: Used for IDS, IDR (Novel shapes and colors)
		s2_shape1 = sessionShapes(3);
		s2_shape2 = sessionShapes(4);
		s2_color1 = sessionColors{3};
		s2_color2 = sessionColors{4};

		% Set 3: Used for EDS, EDR (Novel shapes and colors)
		s3_shape1 = sessionShapes(5);
		s3_shape2 = sessionShapes(6);
		s3_color1 = sessionColors{5};
		s3_color2 = sessionColors{6};

		% Create our two targets (Left and Right)
		targetL = imageStimulus('size', in.objectSize, 'randomiseSelection', false, 'yPosition', in.sampleY);
		targetR = clone(targetL);

		positions = [-in.objectSep/2 in.objectSep/2];
		targets = metaStimulus('stimuli', {targetL, targetR});
		targets.edit(1:2, 'yPosition', in.sampleY);
		targets{1}.xPosition = positions(1);
		targets{2}.xPosition = positions(2);
		targets.stimulusSets{1} = 1:2; % all stimuli
		targets.fixationChoice = 1; % default, will be overridden

		%% ============================ custom stimuli setup
		setup(r.fix, sM); % our init trial touch marker
		setup(targets, sM);
		hide(targets); % hide all stimuli at start

		% Ensure training parameters are initialized as cltasks expect them
		in.doNegation = true;

		% Validate stage once before trials to avoid repeated warnings each trial
		validTaskTypes = {'sd','sr','cd','cr','ids','idr','eds','edr'};
		in.taskType = lower(string(in.taskType));
		if ~ismember(in.taskType, validTaskTypes)
			warning('Unknown task type %s. Defaulting to SD.', in.taskType);
			in.taskType = 'sd';
		end

		%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		while r.keepRunning

			%% ============================== initialise trial variables
			r = clutil.initTrialVariables(r);
			txt = '';
			fail = false; hld = false;

			% Randomize position (Left vs Right) for the two stimulus variants 
			% idx(1) is position for Variant A, idx(2) is position for Variant B
			idx = randperm(2); 

			% Configure Stimulus variants based on the active stage in.taskType
			r.stage = lower(in.taskType);
			r.store.stage = r.stage;
			switch r.stage
				case 'sd' % Simple Discrimination: Shapes only, shape 1 is correct
					shapeA = s1_shape1; colorA = neutralColor;
					shapeB = s1_shape2; colorB = neutralColor;
					correctVariant = 'A';
				case 'sr' % Simple Reversal: Shapes only, shape 2 is correct
					shapeA = s1_shape1; colorA = neutralColor;
					shapeB = s1_shape2; colorB = neutralColor;
					correctVariant = 'B';
				case 'cd' % Compound Discrimination: Shapes + Colors, shape 1 is correct regardless of color
					% Randomly pair the two colors with the two shapes on each trial
					cIdx = randperm(2);
					cols = {s1_color1, s1_color2};
					shapeA = s1_shape1; colorA = cols{cIdx(1)};
					shapeB = s1_shape2; colorB = cols{cIdx(2)};
					correctVariant = 'A';
				case 'cr' % Compound Reversal: Shapes + Colors, shape 2 is correct regardless of color
					cIdx = randperm(2);
					cols = {s1_color1, s1_color2};
					shapeA = s1_shape1; colorA = cols{cIdx(1)};
					shapeB = s1_shape2; colorB = cols{cIdx(2)};
					correctVariant = 'B';
				case 'ids' % Intradimensional Shift: New Shapes + New Colors, Shape is still relevant, shape 3 is correct
					cIdx = randperm(2);
					cols = {s2_color1, s2_color2};
					shapeA = s2_shape1; colorA = cols{cIdx(1)};
					shapeB = s2_shape2; colorB = cols{cIdx(2)};
					correctVariant = 'A';
				case 'idr' % Intradimensional Reversal: Shape 4 is correct
					cIdx = randperm(2);
					cols = {s2_color1, s2_color2};
					shapeA = s2_shape1; colorA = cols{cIdx(1)};
					shapeB = s2_shape2; colorB = cols{cIdx(2)};
					correctVariant = 'B';
				case 'eds' % Extradimensional Shift: New Shapes + New Colors, Color is now relevant, color 5 is correct
					% Shape is now the irrelevant dimension, randomize its pairing
					sIdx = randperm(2);
					shps = {s3_shape1, s3_shape2};
					colorA = s3_color1; shapeA = shps{sIdx(1)};
					colorB = s3_color2; shapeB = shps{sIdx(2)};
					correctVariant = 'A';
				case 'edr' % Extradimensional Reversal: Color 6 is correct
					sIdx = randperm(2);
					shps = {s3_shape1, s3_shape2};
					colorA = s3_color1; shapeA = shps{sIdx(1)};
					colorB = s3_color2; shapeB = shps{sIdx(2)};
					correctVariant = 'B';
				otherwise
					warning('Unknown task type %s. Defaulting to SD.', r.stage);
					shapeA = s1_shape1; colorA = neutralColor;
					shapeB = s1_shape2; colorB = neutralColor;
					correctVariant = 'A';
			end

			% Apply the configured variants to the targets based on the randomized position
			% Variant A goes to idx(1), Variant B goes to idx(2)
			targets{idx(1)}.filePath  = shapeA;
			targets{idx(1)}.colourOut = colorA;
			targets{idx(2)}.filePath  = shapeB;
			targets{idx(2)}.colourOut = colorB;

			% Set the fixation choice
			if strcmp(correctVariant, 'A')
				targets.fixationChoice = idx(1);
			else
				targets.fixationChoice = idx(2);
			end

			% Record trial info
			r.sampleNames = [string(targets{1}.currentFile) string(targets{2}.currentFile)];
			r.summary = sprintf("Stage: %s | Correct Pos: %i", upper(r.stage), targets.fixationChoice);

			showSet(targets, 1); % Show both stimuli
			update(targets);

			%% ============================== Wait for release
			r = clutil.ensureTouchRelease(r, tM, sM, false);

			%% ============================== Initiate a trial with a touch target
			% [r, dt, vblInit] = initTouchTrial(r, in, tM, sM, dt)
			[r, dt, r.vblInitT] = clutil.initTouchTrial(r, in, tM, sM, dt);

			%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			% ============================== start the actual stimulus presentation
			if matches(string(r.touchInit), "yes")
				
				% update trial number as we enter actal trial
				r.trialN = r.trialN + 1;
				r.touchResponse = '';

				%% ================================== update the touch windows for correct targets
				[x, y] = targets.getFixationPositions;
				% updateWindow(me,X,Y,radius,doNegation,negationBuffer,strict,init,hold,release)
				tM.updateWindow(x, y, repmat(in.objectSize/1.9, 1, length(x)),...
				repmat(in.doNegation, 1, length(x)), ones(1, length(x)), true(1, length(x)),...
				repmat(in.trialTime, 1, length(x)), ...
				repmat(in.targetHoldTime, 1, length(x)), ones(1, length(x)));
				
				%% Get our start time
				if ~isempty(r.sbg); draw(r.sbg); end
				vbl = flip(sM);
				r.stimOnsetTime = vbl;
				r.vblInit = vbl + r.sv.ifi; %start is actually next flip
				syncTime(tM, r.vblInit);

				%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				while isempty(r.touchResponse) && vbl <= (r.vblInit + in.trialTime)
					if ~isempty(r.sbg); draw(r.sbg); end
					draw(targets);
					if in.debug && ~isempty(tM.x) && ~isempty(tM.y)
						drawText(sM, txt);
						[xy] = sM.toPixels([tM.x tM.y]);
						Screen('glPoint', sM.win, [1 0 0], xy(1), xy(2), 10);
					end
					vbl = flip(sM);
					[r.touchResponse, hld, r.hldtime, rel, reli, se, fail, tch, negation] = testHold(tM, 'yes', 'no');
					if tch || negation
						r.reactionTime = vbl - r.vblInit;
						r.anyTouch = true;
					end
					if in.debug; txt = sprintf('Response=%i x=%.2f y=%.2f h:%i ht:%i r:%i rs:%i s:%i fail:%i tch:%i WR: %.1f WInit: %.2f WHold: %.2f WRel: %.2f WX: %.2f WY: %.2f',...
						r.touchResponse, tM.x, tM.y, hld, r.hldtime, rel, reli, ...
						se, fail, tch, tM.window.radius, tM.window.init, ...
						tM.window.hold, tM.window.release, tM.window.X, ...
						tM.window.Y); 
					end
					[~,~,c] = KbCheck();
					if c(r.quitKey); r.keepRunning = false; break; end
					if c(r.shotKey); sM.captureScreen; end
				end
				%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			end
			%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			
			r.vblFinal = GetSecs;
			r.value = hld;
			
			%% ============================== check logic of task result
			if matches(r.touchInit, 'no')
				r.result = -5;
			elseif fail || hld == -100 || matches(r.touchResponse, 'no')
				r.result = 0;
			elseif matches(r.touchResponse, 'yes')
				r.result = 1;
			else
				r.result = -1;
			end

			%% ============================== Wait for release
			r = clutil.ensureTouchRelease(r, tM, sM, true);

			%% ============================== update this trials reults
			% [dt, r] = updateTrialResult(in, dt, r, sM, tM, rM, aM)
			[dt, r] = clutil.updateTrialResult(in, dt, r, sM, tM, rM, aM);

		end % while keepRunning
		
		%% ================================ Shut down session
		% shutDownTask(dt, in, r, sM, tM, rM, aM)
		clutil.shutDownTask(dt, in, r, sM, tM, rM, aM);

	catch ME
		getReport(ME)
		try writelines(sprintf("Error IED: " + ME.Message), "~/cagelab-start.txt", WriteMode="append"); end
		try if in.remote; r.status.updateStatusToStopped();end;end
		try clutil.broadcastTrial(in, r, dt, false); end
		try if IsLinux; system('xset s 300 dpms 600 0 0'); end; end
		try reset(targets); end %#ok<*TRYNC>
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

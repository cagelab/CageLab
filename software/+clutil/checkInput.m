function in = checkInput(in)
	if ~exist('in', 'var') || isempty(in)
		in = struct();
	elseif ~isstruct(in)
		error('checkInput:InvalidInput', 'Input must be a struct.');
	end

	pth = fileparts(fileparts(mfilename('fullpath')));

	defaults = struct();
	defaults.density = 70;
	defaults.distance = 30;
	defaults.timeOut = 1;

	defaults.fg = [1 1 0.75];
	defaults.bg = [0.5 0.5 0.5];

	defaults.IP = '127.0.0.1';
	defaults.port = 9012;

	defaults.remote = false;
	defaults.folder = [pth filesep 'resources'];
	defaults.debug = true;
	defaults.dummy = true;
	defaults.reward = false;

	defaults.audio = true;
	defaults.audioDevice = [];
	defaults.audioVolume = 0.2;

	defaults.phase = 1;
	defaults.stimulusType = 'Picture';
	defaults.task = 'generic';
	defaults.taskType = 'normal';

	defaults.name = 'simulcra';
	defaults.rewardmode = 1;
	defaults.volume = 250;
	defaults.random = 1;
	defaults.screen = 0;
	defaults.smartBackground = true;

	defaults.correctBeep = 3000;
	defaults.incorrectBeep = 400;

	defaults.rewardPort = '/dev/ttyACM0';
	defaults.rewardTime = 200;

	defaults.randomReward = 0;
	defaults.randomProbability = 0.25;

	defaults.nTrialsSample = 10;
	defaults.stepForward = 10;
	defaults.stepPercent = 80;
	defaults.stepBack = 10;

	defaults.doNegation = true;
	defaults.negationBuffer = 2;
	defaults.exclusionZone = [];
	defaults.drainEvents = true;
	defaults.strictMode = true;
	defaults.negateTouch = true;
	defaults.touchDevice = 1;
	defaults.touchDeviceName = 'ILITEK-TP';

	defaults.stimulus = 1;
	defaults.objectSize = 8;
	defaults.objectSep = 12;
	defaults.maxSize = 50;
	defaults.minSize = 4;
	defaults.initPosition = [0 4];
	defaults.initSize = 4;
	defaults.target1Pos = [-5 -5];
	defaults.target2Pos = [5 -5];
	defaults.targetSize = 10;
	defaults.startY = -10;
	defaults.sampleY = -1;
	defaults.distractorY = -1;
	defaults.trialTime = 5;
	defaults.initHoldTime = 0.005;
	defaults.targetHoldTime = 0.005;

	defaults.zmq = [];
	defaults.useAlyx = false;
	defaults.useBlending = true;
	defaults.disableSync = true;
	defaults.useVulkan = false;
	defaults.command = '';
	defaults.trackID = false;
	defaults.session = struct('researcherName', 'admin', 'labName', 'CogPlatform', 'projectName', 'TestTraining', 'subjectName', 'TestSubject');
	defaults.lab = 'CogPlatform';
	defaults.sessionURL = '';
	defaults.totalRewards = 100;

	fields = fieldnames(defaults);
	for i = 1:numel(fields)
		f = fields{i};
		if ~isfield(in, f) || isempty(in.(f))
			in.(f) = defaults.(f);
		end
	end

end

function [session, success] = initAlyxSession(alyx, session, runStruct)
%INITALYXSESSION Initialize an Alyx session for the current experiment.
%   [session, success] = INITALYXSESSION(alyx, session) registers or updates
%   a session record in the Alyx database using the manager stored in 'alyx	'.
%
%   Inputs:
%       alyx    - alyxManager object for interacting with the Alyx database.
%       session - Struct containing session metadata (subject, lab, etc.).
%
%   Outputs:
%       session - Updated session struct with initialization status and URL.
%       success - Logical flag indicating if the session was successfully created.
	arguments (Input)
		alyx alyxManager
		session struct = []
		runStruct struct = []
	end
	arguments (Output)
		session struct
		success logical
	end

	if isempty(alyx) || ~isa(alyx, 'alyxManager')
		alyx = alyxManager;
		setSecrets(alyx);
	end

	alyx.logout;
	alyx.login;
	
	% create new session folder and name if necessary
	if ~exist(alyx.paths.ALFPath,'dir')
		alyx.getALF(session.subjectName, session.labName, true);
	end
	
	url = alyx.createSession(alyx.paths.ALFPath, alyx.paths.sessionID, session);
	
	if ~isempty(url)
		success = true;
		session.initialised = true;
		session.sessionURL = url;
		id = split(url, '/');
		session.sessionID = id{end};
		t = sprintf('≣≣≣≣⊱ Alyx File Path: %s -- Alyx URL: %s...', alyx.paths.ALFPath, session.sessionURL);
		if ~isempty(runStruct) && isfield(runStruct,'tL') && isa(runStruct.tL,'timeLogger')
			try addMessage(runStruct.tL, runStruct.loopN, GetSecs, [], t, "getsecs", "Metadata"); end
		end
		disp(t);
	else
		session.sessionURL = '';
		session.initialised = false;
		success = false;
		t = sprintf('≣≣≣≣⊱ Failed to initialize Alyx session %s for subject %s in lab %s', alyx.paths.ALFPath, session.subjectName, session.labName);
		if ~isempty(runStruct) && isfield(runStruct,'tL') && isa(runStruct.tL,'timeLogger')
			try addMessage(runStruct.tL, runStruct.loopN, GetSecs, [], t, "getsecs", "Metadata"); end
		end
		warning(t);
	end
	
end
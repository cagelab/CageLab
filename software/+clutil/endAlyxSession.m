function [session, error] = endAlyxSession(alyx, session, result, nTrials, nCorrect, json)
	%ENDALYXSESSION End an Alyx session for the current experiment.
	%   [session, error] = ENDALYXSESSION(r, session, result) finalizes
	%   an Alyx session and uploads registered files to the MINIO server.
	%
	%   Inputs:
	%       alyx    - alyxManager.
	%       session - Struct containing session metadata (subject, lab, etc.).
	%       result  - String indicating the result of the experiment (e.g., "PASS", "FAIL").
	%       nTrials - Number of trials conducted in the session.
	%       nCorrect - Number of correct trials in the session.
	%       json    - JSON string containing additional session data.
	%
	%   Outputs:
	%       session - Updated session struct with finalization status and URL.
	%       error   - String containing any error messages.
	arguments (Input)
		alyx alyxManager
		session struct
		result string = "FAIL"
		nTrials double = NaN
		nCorrect double = NaN
		json string = ""
	end

	arguments (Output)
		session struct
		error string
	end

	if ~session.useAlyx; return; end

	error = '';

	%% close the session
	fprintf('≣≣≣≣⊱ Closing ALYX Session: %s\n', alyx.sessionURL);
	finalisedSession = alyx.closeSession('', result, nTrials, nCorrect, json);
	if isempty(finalisedSession)
		error = 'Failed to finalise ALYX session!';
		return;
	end

	%% upload the data
	try
		%% register the files to ALYX
		[datasets, filenames] = alyx.registerALFFiles(alyx.paths, session);

		if numel(filenames)>0 && isempty(datasets)
			error = "registerALFFiles FAILED!!!!!!!";
			return
		end

		fprintf('≣≣≣≣⊱ Added Files to ALYX Session: %s\n', alyx.sessionURL);
		try arrayfun(@(ss)disp([ss.name ' - bytes: ' num2str(ss.file_size)]),datasets); end

		%% get the ALYX dataset UUID for each file registered
		uuids = cell(1, numel(filenames)); setQC = false;
		if length(datasets) == length(filenames)
			for ii = 1:length(filenames)
				if contains(filenames{ii},datasets(ii).name)
					uuids{ii} = datasets(ii).id;
				else
					uuids{ii} = '';
				end
			end
		end

		%% upload the files to MINIO server
		secrets = alyx.getSecrets;
		if ~isempty(secrets.AWS_ID)
			store = minioManager(secrets.AWS_ID, secrets.AWS_KEY, session.dataURL);
			bucket = lower(session.labName);
			store.checkBucket(bucket);
			for ii = 1:length(filenames)
				[~,f,e] = fileparts(filenames{ii});
				if ~isempty(uuids) && ~isempty(uuids{ii})
					% append the uuid to the filename, seems to
					% be required by ONE protocol
					key = [alyx.paths.ALFKeyShort filesep f '.' uuids{ii} e];
				else
					key = [alyx.paths.ALFKeyShort filesep f e];
				end
				try
					store.copyFiles(filenames{ii}, bucket, key);
					setQC = true;
				catch
					setQC = false;
					warning('Failed to upload file to MINIO server, check connection and credentials!!!');
				end
			end
		else
			warning('To upload Alyx files you need to set setSecrets: AWS_ID and AWS_KEY!!!');
			warning('YOU MUST UPLOAD MANUALLY NOW!!!');
			error = sprintf('Could not upload files to Server!!!!!!\n');
		end

		%% if the upload was successful, set the dataset QC to PASS in ALYX
		if setQC
			qc = struct("qc", "PASS");
			%% set the dataset QC to PASS if upload successful
			for ii = 1:length(uuids)
				if ~isempty(uuids{ii})
					alyx.postData("datasets/"+string(uuids{ii}), qc, 'PATCH');
				end
			end
			fprintf('≣≣≣≣⊱ Set ALYX QC to PASS for session: %s\n', alyx.sessionURL);
		end

	catch ME
		getReport(ME)
		error = sprintf('Could not register datasets for session: %s with error %s\n', alyx.sessionURL, ME.message);
		datasets = [];
		return;
	end
	if ~isempty(error)
		warning(error);
	end

end
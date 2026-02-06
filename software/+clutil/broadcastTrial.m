function broadcastTrial(in, r, dt, isRunning)
	% BROADCASTTRIAL Sends trial and session telemetry to the broadcast server.
	%   BROADCASTTRIAL(IN, R, DT, ISRUNNING) packages trial performance metrics,
	%   timing information, and session metadata into a structure and transmits
	%   it using the broadcast interface stored in R.
	arguments (Input)
		in struct
		r struct
		dt touchData
		isRunning logical = false
	end

	tdata = [];
	sid = split(r.alyxPath, filesep);
	if length(sid) >= 3
		sid = string(join(sid(end-2:end),filesep));
	else
		sid = r.alyxPath;
	end

	try
		tdata = struct('task',in.task,'name',in.name,'is_running',isRunning,...
		'loop_id',r.loopN,'trial_id',r.trialN,...
		'rewards',dt.data.rewards, ...
		'correct_rate_last10', r.correctRateRecent, 'correct_rate', r.correctRate,...
		'result', r.result, 'reaction_time', r.reactionTime, 'phase', r.phase,...
		'random_rewards', dt.data.random,...
		'now', string(datetime('now')),...
		'session_id', sid,...
		'hostname', r.hostname, 'version', r.version,...
		'comment', r.comments(end),...
		'session', in.session.sessionURL);
		if ~isempty(tdata)
			r.broadcast.send(tdata); 
		end
	catch ME
		% Log the error message if an exception occurs
		disp(['Error in broadcastTrial: ', ME.message]);
	end

end
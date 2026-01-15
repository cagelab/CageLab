#!/usr/bin/env zsh
# a script to start all cagelab services gracefully

systemctl --user daemon-reload
sl=(toggleInput.service cogmoteGO.service theConductor.service mediamtx.service obs.service)
for s in $sl; do
	echo "Restarting $s"
	systemctl --user restart $s &
	sleep 0.25s
done

echo "All cagelab services restarting..."
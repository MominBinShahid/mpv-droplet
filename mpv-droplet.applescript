-- mpv-droplet: opens files from Finder in Homebrew mpv (settings come from ~/.config/mpv/mpv.conf).
-- How it works and how to build it into an app: see README.md in this folder.

-- Apps launched from Finder don't get your shell's PATH, so add Homebrew's
-- locations: /opt/homebrew (Apple Silicon) and /usr/local (Intel).
property pathPrefix : "PATH=/opt/homebrew/bin:/usr/local/bin:$PATH"
property mpvCmd : "PATH=/opt/homebrew/bin:/usr/local/bin:$PATH mpv --player-operation-mode=pseudo-gui"

-- mpv's output goes to /dev/null, so without this check a missing mpv fails silently.
on mpvInstalled()
	try
		do shell script pathPrefix & " command -v mpv"
		return true
	on error
		display alert "mpv not found" message "mpv not found. Install it with: brew install mpv" as critical
		return false
	end try
end mpvInstalled

on open theFiles
	if not my mpvInstalled() then return
	set args to ""
	repeat with f in theFiles
		set args to args & " " & quoted form of POSIX path of f
	end repeat
	do shell script mpvCmd & " --" & args & " >/dev/null 2>&1 &"
end open

on run
	if not my mpvInstalled() then return
	do shell script mpvCmd & " >/dev/null 2>&1 &"
end run

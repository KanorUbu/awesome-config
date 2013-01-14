-- Control de mpd
function mpd_control (action)
    if action == "next" then
        io.popen("mpc next")
    elseif action == "previous" then
        io.popen("mpc prev")
    elseif action == "stop" then
        io.popen("mpc stop")
    elseif action == "play_pause" then
        io.popen("mpc toggle")
    end
end

--[[wicked.register(mpdwidget, wicked.widgets.mpd,
	function (widget, args)
		   if args[1]:find("volume:") == nil then
		      return ' <span color="white">En cours de lecture :</span> '..args[1]
		   else
                      return ''
                   end
		end)]]

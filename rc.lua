-- Standard awesome library
require("awful")
require("awful.autofocus")
require("awful.rules")
-- Theme handling library
require("beautiful")
-- Notification library
require("naughty")

-- Load Debian menu entries
--require("debian.menu")
require("revelation")
require("vicious")
-- applications menu
require('freedesktop.utils')

require('freedesktop.menu')

-- Sound Control
cardid  = 0
channel = "Master"
function volume (mode, widget)
    if mode == "update" then
             local fd = io.popen("amixer -c " .. cardid .. " -- sget " .. channel)
             local status = fd:read("*all")
             fd:close()

        local volume = string.match(status, "(%d?%d?%d)%%")
        volume = string.format("% 3d", volume)

        status = string.match(status, "%[(o[^%]]*)%]")

        if string.find(status, "on", 1, true) then
            volume = "| Vol:<span color='green'>" .. volume .. "</span>% "
        else
            volume = "| Vol:<span color='red'>" .. volume .. "</span>M "
        end
        widget.text = volume
    elseif mode == "up" then
        io.popen("amixer -q -c " .. cardid .. " sset " .. channel .. " 5%+"):read("*all")
        volume("update", widget)
    elseif mode == "down" then
        io.popen("amixer -q -c " .. cardid .. " sset " .. channel .. " 5%-"):read("*all")
        volume("update", widget)
    else
        io.popen("amixer -c " .. cardid .. " sset " .. channel .. " toggle"):read("*all")
        volume("update", widget)
    end
end

-- Enable mocp
function moc_control (action)
    local moc_info,moc_state

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



-- Battery status Widget

-- get the full capacity of the battery
for line in io.lines("/proc/acpi/battery/BAT0/info") do
    bat_stat = string.match(line, "last full capacity:\ +(%d+)")

    if bat_stat then
        -- define stat_tot for reuse later for battery status
        stat_tot = bat_stat
    end
end

function activebat()
    local stat_actu, res

    for line in io.lines("/proc/acpi/battery/BAT0/state") do
        local present = string.match(line, "present:\ +(%a+)")
        if (present == "no") then
            return '<span color="red">not present</span>'
        end
        local status  =  string.match(line, "remaining capacity:\ +(%d+)")
        local state = string.match(line, "charging state:\ +(%a+)")
        if status then
            stat_actu = status
        end
        if state then
            stat_bat = state
        end
    end

    res = string.format("%.2f", (stat_actu/stat_tot) * 100);

    if ((stat_actu/stat_tot) * 100)  < 10 then
        res = '<span color="red">' .. res .. '</span>'
    elseif  ((stat_actu/stat_tot) * 100) < 20 then
        res = '<span color="orange">' .. res .. '</span>'
    elseif  ((stat_actu/stat_tot) * 100)  < 30 then
        res = '<span color="yellow">' .. res .. '</span>'
    elseif ((stat_actu/stat_tot) * 100) >= 100 then
        return '<span color="green">fully charged</span>'
    else
        res = '<span color="green">' .. res .. '</span>'
    end

    if (stat_bat == 'discharging') then
        stat_bat = '<span color="red">discharging</span>'
    elseif (stat_bat == 'charging') then
        stat_bat = '<span color = "green">charging</span>'
    end

    res = res .. '% ' .. stat_bat


    return res
end

batinfo = widget({ type = "textbox" , name = "batinfo" })

-- Assign a hook to update info
-- awful.hooks.timer.register(1, function() batinfo.text = "BAT: " .. activebat() .. " |" end)
activebat_timer = timer({timeout = 1})
activebat_timer:add_signal("timeout", function() batinfo.text = "BAT: " .. activebat() .. " |" end)
activebat_timer:start()

-- {{{ Variable definitions
-- Themes define colours, icons, and wallpapers
--beautiful.init("/usr/share/awesome/themes/default/theme.lua")
beautiful.init(awful.util.getdir("config") .. "/theme_actuel/theme.lua")

-- This is used later as the default terminal and editor to run.
--terminal = "x-terminal-emulator"
terminal = "urxvtc"
editor = os.getenv("EDITOR") or "editor"
editor_cmd = terminal .. " -e " .. editor

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
layouts =
{
    awful.layout.suit.floating,
    awful.layout.suit.tile,
    awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.tile.top,
    awful.layout.suit.fair,
    awful.layout.suit.fair.horizontal,
    awful.layout.suit.spiral,
    awful.layout.suit.spiral.dwindle,
    awful.layout.suit.max,
    awful.layout.suit.max.fullscreen,
    awful.layout.suit.magnifier
}
-- }}}

-- {{{ Tags
-- Define a tag table which hold all screen tags.
tags = {}
for s = 1, screen.count() do
    -- Each screen has its own tag table.
    tags[s] = awful.tag({ 1, 2, 3, 4, 5, 6, 7, 8, 9 }, s, layouts[1])
end
-- }}}

-- {{{ Menu
-- Create a laucher widget and a main menu
myawesomemenu = {
   { "manual", terminal .. " -e man awesome" },
   { "edit config", editor_cmd .. " " .. awful.util.getdir("config") .. "/rc.lua" },
   { "restart", awesome.restart },
   { "quit", awesome.quit }
}

mymainmenu = awful.menu({ items = { { "awesome", myawesomemenu, beautiful.awesome_icon },
                                    --{ "Debian", debian.menu.Debian_menu.Debian },
                                    { "open terminal", terminal }
                                  }
                        })

mylauncher = awful.widget.launcher({ image = image(beautiful.awesome_icon),
                                     menu = mymainmenu })
freedesktop.utils.terminal = terminal -- default: "xterm"
freedesktop.utils.icon_theme = 'gnome' -- look inside /usr/share/icons/, default: nil (don't use icon theme)
menu_items = freedesktop.menu.new()
myfreedesktop = awful.menu.new({ items = menu_items, width = 150 })

myfreelauncher = awful.widget.launcher({ image = beautiful.awesome_icon,
                                     menu = myfreedesktop })


  -- desktop icons
  require('freedesktop.desktop')
  for s = 1, screen.count() do
        freedesktop.desktop.add_applications_icons({screen = s, showlabels = true})
        freedesktop.desktop.add_dirs_and_files_icons({screen = s, showlabels = true})
  end
-- }}}

-- {{{ Wibox
-- Create a textclock widget
mytextclock = awful.widget.textclock({ align = "right" })

-- Create a systray
mysystray = widget({ type = "systray" })

-- Create a wibox for each screen and add it
mywibox = {}
mypromptbox = {}
mylayoutbox = {}
mytaglist = {}
mytaglist.buttons = awful.util.table.join(
                    awful.button({ }, 1, awful.tag.viewonly),
                    awful.button({ modkey }, 1, awful.client.movetotag),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, awful.client.toggletag),
                    awful.button({ }, 4, awful.tag.viewnext),
                    awful.button({ }, 5, awful.tag.viewprev)
                    )


mytasklist = {}
mytasklist.buttons = awful.util.table.join(
                     awful.button({ }, 1, function (c)
                                              if not c:isvisible() then
                                                  awful.tag.viewonly(c:tags()[1])
                                              end
                                              client.focus = c
                                              c:raise()
                                          end),
                     awful.button({ }, 3, function ()
                                              if instance then
                                                  instance:hide()
                                                  instance = nil
                                              else
                                                  instance = awful.menu.clients({ width=250 })
                                              end
                                          end),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                              if client.focus then client.focus:raise() end
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                              if client.focus then client.focus:raise() end
                                          end))



for s = 1, screen.count() do
    -- Create a promptbox for each screen
    mypromptbox[s] = awful.widget.prompt({ layout = awful.widget.layout.horizontal.leftright })
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    mylayoutbox[s] = awful.widget.layoutbox(s)
    mylayoutbox[s]:buttons(awful.util.table.join(
                           awful.button({ }, 1, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(layouts, -1) end),
                           awful.button({ }, 4, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(layouts, -1) end)))
    -- Create a taglist widget
    mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.label.all, mytaglist.buttons)

    -- Create a tasklist widget
    mytasklist[s] = awful.widget.tasklist(function(c)
                                              return awful.widget.tasklist.label.currenttags(c, s)
                                          end, mytasklist.buttons)


    -- Mem Widget
    -- Initialize widget
    memwidget = awful.widget.progressbar()
    -- Progressbar properties
    memwidget:set_width(20)
    memwidget:set_height(20)
    memwidget:set_vertical(true)
    memwidget:set_background_color("#494B4F")
    memwidget:set_border_color(nil)
    memwidget:set_color("#AECF96")
    memwidget:set_gradient_colors({ "#AECF96", "#88A175", "#FF5656" })
    -- Register widget
    vicious.register(memwidget, vicious.widgets.mem, "$1", 13)

    myspacer         = widget({ type = "textbox", name = "myspacer" })
    myseparator      = widget({ type = "textbox", name = "myseparator" })

    myspacer.text    = " "
    myseparator.text = "|"
    -- Create Volume Control Widget
     tb_volume = widget({ type = "textbox", name = "tb_volume", align = "right" })
     tb_volume:buttons(awful.util.table.join(
        awful.button({ }, 4, function () volume("up", tb_volume) end),
        awful.button({ }, 5, function () volume("down", tb_volume) end),
        awful.button({ }, 1, function () volume("mute", tb_volume) end)
     ))
     volume("update", tb_volume)

    -- refresh the Volume Control Widget
    tb_volume_timer = timer({ timeout = 10 })
    tb_volume_timer:add_signal("timeout", function () volume("update", tb_volume) end)
    tb_volume_timer:start()

    -- Moc Widget
    tb_moc = widget({ type = "textbox", align = "right" })

    function hook_moc()
           moc_info = io.popen("mocp -i"):read("*all")
           moc_state = string.gsub(string.match(moc_info, "State: %a*"),"State: ","")
           if moc_state == "PLAY" or moc_state == "PAUSE" then
               moc_artist = string.gsub(string.match(moc_info, "Artist: %C*"), "Artist: ","")
               moc_title = string.gsub(string.match(moc_info, "SongTitle: %C*"), "SongTitle: ","")
               moc_curtime = string.gsub(string.match(moc_info, "CurrentTime: %d*:%d*"), "CurrentTime: ","")
               moc_totaltime = string.gsub(string.match(moc_info, "TotalTime: %d*:%d*"), "TotalTime: ","")
               if moc_artist == "" then
                   moc_artist = "unknown artist"
               end
               if moc_title == "" then
                   moc_title = "unknown title"
               end
           -- moc_title = string.format("%.5c", moc_title)
               moc_string = moc_artist .. " - " .. moc_title .. "(" .. moc_curtime .. "/" .. moc_totaltime .. ")"
               if moc_state == "PAUSE" then
                   moc_string = "PAUSE - " .. moc_string .. ""
               end
           else
               moc_string = "-- not playing --"
           end
           return moc_string
    end

    -- refresh Moc widget
    moc_timer = timer({timeout = 1})
    moc_timer:add_signal("timeout", function() tb_moc.text = '| ' .. hook_moc() .. ' ' end)
    moc_timer:start()


    -- Create the wibox
    mywibox[s] = awful.wibox({ position = "top", screen = s })
    -- Add widgets to the wibox - order matters
    mywibox[s].widgets = {
        {
            mylauncher,
            myfreelauncher,
            mytaglist[s],
            mypromptbox[s],
            layout = awful.widget.layout.horizontal.leftright
        },
        myspace, myspacer,
        memwidget,
        myspace, myspacer,
        tb_volume,
        batinfo,
        mylayoutbox[s],
        mytextclock,
        tb_moc,
        s == 1 and mysystray or nil,
        mytasklist[s],
        layout = awful.widget.layout.horizontal.rightleft
    }
end
-- }}}


-- {{{ Mouse bindings
root.buttons(awful.util.table.join(
    awful.button({ }, 3, function () mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
globalkeys = awful.util.table.join(
    awful.key({ modkey,           }, "Left",   awful.tag.viewprev       ),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext       ),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore),

    awful.key({ modkey,           }, "j",
        function ()
            awful.client.focus.byidx( 1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "k",
        function ()
            awful.client.focus.byidx(-1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "w", function () mymainmenu:show({keygrabber=true}) end),

    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end),
    awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end),
    awful.key({ modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end),
    awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto),
    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end),

    -- Standard program
    awful.key({ modkey,           }, "Return", function () awful.util.spawn(terminal) end),
    awful.key({ modkey, "Control" }, "r", awesome.restart),
    awful.key({ modkey, "Shift"   }, "q", awesome.quit),

    awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)    end),
    awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)    end),
    awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1)      end),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1)      end),
    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1)         end),
    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1)         end),
    awful.key({ modkey,           }, "space", function () awful.layout.inc(layouts,  1) end),
    awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(layouts, -1) end),

    -- Prompt
    awful.key({ modkey },            "r",     function () mypromptbox[mouse.screen]:run() end),

    awful.key({ modkey }, "x",
              function ()
                  awful.prompt.run({ prompt = "Run Lua code: " },
                  mypromptbox[mouse.screen].widget,
                  awful.util.eval, nil,
                  awful.util.getdir("cache") .. "/history_eval")
              end),
    --Perso
    awful.key({ modkey }, "Down", revelation.revelation),
    awful.key({ }, "XF86AudioRaiseVolume", function () volume("up", tb_volume) end),
    awful.key({ }, "XF86AudioLowerVolume", function () volume("down", tb_volume) end),
    awful.key({ }, "XF86AudioMute", function () volume("mute", tb_volume) end),
    awful.key({ }, "XF86AudioNext", function () moc_control("next") end),
    awful.key({ }, "XF86AudioPrev", function () moc_control("previous") end),
    awful.key({ }, "XF86AudioStop", function () moc_control("stop") end),
    awful.key({ }, "XF86AudioPlay", function () moc_control("play_pause") end)
)

clientkeys = awful.util.table.join(
    awful.key({ modkey,           }, "f",      function (c) c.fullscreen = not c.fullscreen  end),
    awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end),
    awful.key({ modkey,           }, "o",      awful.client.movetoscreen                        ),
    awful.key({ modkey, "Shift"   }, "r",      function (c) c:redraw()                       end),
    awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end),
    awful.key({ modkey,           }, "n",      function (c) c.minimized = not c.minimized    end),
    awful.key({ modkey,           }, "m",
        function (c)
            c.maximized_horizontal = not c.maximized_horizontal
            c.maximized_vertical   = not c.maximized_vertical
        end)
)

-- Compute the maximum number of digit we need, limited to 9
keynumber = 0
for s = 1, screen.count() do
   keynumber = math.min(9, math.max(#tags[s], keynumber));
end

tagkeys = { '#10', '#11', '#12', '#13', '#14', '#15', '#16', '#17', '#18', '#19', '#20' }
for i = 1, keynumber do
    globalkeys = awful.util.table.join(globalkeys,
        awful.key({ modkey }, tagkeys[i],
                   function ()
                       local screen = mouse.screen
                       if tags[screen][i] then
                           awful.tag.viewonly(tags[screen][i])
                       end
                   end),
        awful.key({ modkey, "Control" }, tagkeys[i],
                   function ()
                       local screen = mouse.screen
                       if tags[screen][i] then
                           tags[screen][i].selected = not tags[screen][i].selected
                       end
                   end),
        awful.key({ modkey, "Shift" }, tagkeys[i],
                   function ()
                       if client.focus then
                           if tags[client.focus.screen][i] then
                               awful.client.movetotag(tags[client.focus.screen][i])
                           end
                       end
                   end),
        awful.key({ modkey, "Control", "Shift" }, tagkeys[i] ,
                   function ()
                       if client.focus then
                           if tags[client.focus.screen][i] then
                               awful.client.toggletag(tags[client.focus.screen][i])
                           end
                       end
                   end))
end

clientbuttons = awful.util.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize))

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = true,
                     keys = clientkeys,
                     buttons = clientbuttons } },
    { rule = { class = "MPlayer" },
      properties = { floating = true } },
    { rule = { class = "pinentry" },
      properties = { floating = true } },
    { rule = { class = "gimp" },
      properties = { floating = true } },
    -- Set Firefox to always map on tags number 2 of screen 1.
    -- { rule = { class = "Firefox" },
    --   properties = { tag = tags[1][2] } },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.add_signal("manage", function (c, startup)
    -- Add a titlebar
    -- awful.titlebar.add(c, { modkey = modkey })

    -- Enable sloppy focus
    c:add_signal("mouse::enter", function(c)
        if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
            and awful.client.focus.filter(c) then
            client.focus = c
        end
    end)

    if not startup then
        -- Set the windows at the slave,
        -- i.e. put it at the end of others instead of setting it master.
        -- awful.client.setslave(c)

        -- Put windows in a smart way, only if they does not set an initial position.
        if not c.size_hints.user_position and not c.size_hints.program_position then
            awful.placement.no_overlap(c)
            awful.placement.no_offscreen(c)
        end
    end
end)

client.add_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.add_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}
--
--{{{ Start programm
awful.util.spawn('nm-applet &')
awful.util.spawn('padevchooser &')
awful.util.spawn("xmodmap -e 'keycode 49 = x'")
awful.util.spawn("urxvtd -q -f -o &")
--}}}

function love.load()
	math.randomseed(os.time())
	highscores = {}
	love.graphics.setDefaultFilter("linear", "nearest")
	-- require "load.rpc"
	require "load.graphics"
	require "load.fonts"
	require "load.sounds"
	require "load.bgm"
	require "load.save"
	require "load.bigint"
	require "load.version"
	loadSave()
	require "funcs"
	require "scene"
	
	--config["side_next"] = false
	--config["reverse_rotate"] = true
	--config["das_last_key"] = false
	--config["fullscreen"] = false

	love.window.setMode(love.graphics.getWidth(), love.graphics.getHeight(), {resizable = true});
		
	-- used for screenshots
	GLOBAL_CANVAS = love.graphics.newCanvas()

	-- init config
	initConfig()

	-- love.window.setFullscreen(config["fullscreen"])
	-- if config.secret then playSE("welcome") end
	playSE("welcome") -- trololo

	-- import custom modules
	initModules()

	touchButtons = {
		{260, 60, 60, 60, 0, 1, 0, "ENTER", "return", "return"},
		{260, 120, 60, 60, 1, 0, 0, "ESC", "escape", "escape"},
		{260, 180, 60, 60, 1, 1, 0, "TAB", "tab", "tab"},

		{0, 180, 60, 60, 0, .25, 1, "<", "left", "left"},
		{60, 120, 60, 60, 0, .25, 1, "/\\", "up", "up"},
		{60, 180, 60, 60, 0, .25, 1, "\\/", "down", "down"},
		{120, 180, 60, 60, 0, .25, 1, ">", "right", "right"}
	}
end



function initModules()
	-- replays are not loaded here, but they are cleared
	replays = {}
	game_modes = {}
	mode_list = love.filesystem.getDirectoryItems("tetris/modes")
	for i=1,#mode_list do
		if(mode_list[i] ~= "gamemode.lua" and string.sub(mode_list[i], -4) == ".lua") then
			game_modes[#game_modes+1] = require ("tetris.modes."..string.sub(mode_list[i],1,-5))
		end
	end
	rulesets = {}
	rule_list = love.filesystem.getDirectoryItems("tetris/rulesets")
	for i=1,#rule_list do
		if(rule_list[i] ~= "ruleset.lua" and string.sub(rule_list[i], -4) == ".lua") then
			rulesets[#rulesets+1] = require ("tetris.rulesets."..string.sub(rule_list[i],1,-5))
		end
	end
	--sort mode/rule lists
	local function padnum(d) return ("%03d%s"):format(#d, d) end
	table.sort(game_modes, function(a,b)
	return tostring(a.name):gsub("%d+",padnum) < tostring(b.name):gsub("%d+",padnum) end)
	table.sort(rulesets, function(a,b)
	return tostring(a.name):gsub("%d+",padnum) < tostring(b.name):gsub("%d+",padnum) end)
end

function love.draw(screen)
	if screen == "bottom" then
		if scene.title ~= "Game" then
			love.graphics.setCanvas()
			love.graphics.setFont(font_3x5)
			-- love.graphics.setColor(1, 1, 1, 1)
			-- love.graphics.printf("< > /\\ \\/", 0, 0, 635, "left")

			for _, b in ipairs(touchButtons) do
				love.graphics.setColor(b[5], b[6], b[7])
				love.graphics.setLineWidth(2)
				love.graphics.rectangle("line", b[1], b[2], b[3], b[4])
				love.graphics.printf(b[8], b[1]+6, b[2], b[3], "left")
			end
		end
		
		love.graphics.setColor(1, 1, 1, 1)

	else
		love.graphics.setCanvas(GLOBAL_CANVAS)
		love.graphics.clear()

		love.graphics.push()

		-- get offset matrix
		local width = love.graphics.getWidth()
		local height = love.graphics.getHeight()
		local scale_factor = math.min(width / 640, height / 480)
		love.graphics.translate(
			(width - scale_factor * 640) / 2,
			(height - scale_factor * 480) / 2
		)
		love.graphics.scale(scale_factor)
			
		scene:render()

		if config.gamesettings.display_gamemode == 1 or scene.title == "Title" then
			love.graphics.setFont(font_3x5_2)
			love.graphics.setColor(1, 1, 1, 1)
			love.graphics.printf(
				string.format("%.2f", 1.0 / love.timer.getAverageDelta()) ..
				"fps - " .. version, 0, 460, 635, "right"
			)
		end
		
		love.graphics.pop()
			
		love.graphics.setCanvas()
		love.graphics.setColor(1,1,1,1)
		love.graphics.draw(GLOBAL_CANVAS)
	end
end

function love.keypressed(key, scancode)
	-- global hotkeys
	if scancode == "f11" then
		config["fullscreen"] = not config["fullscreen"]
		saveConfig()
		love.window.setFullscreen(config["fullscreen"])
	elseif scancode == "f2" and scene.title ~= "Input Config" and scene.title ~= "Game" then
		scene = InputConfigScene()
		switchBGM(nil)
		loadSave()
	-- secret sound playing :eyes:
	elseif scancode == "f8" and scene.title == "Title" then
		config.secret = not config.secret
		saveConfig()
		scene.restart_message = true
		if config.secret then playSE("mode_decide")
		else playSE("erase") end
		-- f12 is reserved for saving screenshots
	elseif scancode == "f12" then
		local ss_name = os.date("ss/%Y-%m-%d_%H-%M-%S.png")
		local info = love.filesystem.getInfo("ss", "directory")
		if not info then
			love.filesystem.remove("ss")
			love.filesystem.createDirectory("ss")
		end
		print("Saving screenshot as "..love.filesystem.getSaveDirectory().."/"..ss_name)
		GLOBAL_CANVAS:newImageData():encode("png", ss_name)
	-- function keys are reserved
	elseif string.match(scancode, "^f[1-9]$") or string.match(scancode, "^f[1-9][0-9]+$") then
		return	
	-- escape is reserved for menu_back
	elseif scancode == "escape" then
		scene:onInputPress({input="menu_back", type="key", key=key, scancode=scancode})
	-- pass any other key to the scene, with its configured mapping
	else
		local input_pressed = nil
		if config.input and config.input.keys then
			input_pressed = config.input.keys[scancode]
		end
		scene:onInputPress({input=input_pressed, type="key", key=key, scancode=scancode})
	end
end

function love.keyreleased(key, scancode)
	-- escape is reserved for menu_back
	if scancode == "escape" then
		scene:onInputRelease({input="menu_back", type="key", key=key, scancode=scancode})
	-- function keys are reserved
	elseif string.match(scancode, "^f[1-9]$") or string.match(scancode, "^f[1-9][0-9]+$") then
		return	
	-- handle all other keys; tab is reserved, but the input config scene keeps it from getting configured as a game input, so pass tab to the scene here
	else
		local input_released = nil
		if config.input and config.input.keys then
			input_released = config.input.keys[scancode]
		end
		scene:onInputRelease({input=input_released, type="key", key=key, scancode=scancode})
	end
end

function love.gamepadpressed(joystick, button)
	local input_pressed = nil
	if
		config.input and
		config.input.joysticks and
		config.input.joysticks[joystick:getName()] and
		config.input.joysticks[joystick:getName()].buttons
	then
		input_pressed = config.input.joysticks[joystick:getName()].buttons[button]
	end
	scene:onInputPress({input=input_pressed, type="joybutton", name=joystick:getName(), button=button})
end

function love.gamepadreleased(joystick, button)
	local input_released = nil
	if
		config.input and
		config.input.joysticks and
		config.input.joysticks[joystick:getName()] and
		config.input.joysticks[joystick:getName()].buttons
	then
		input_released = config.input.joysticks[joystick:getName()].buttons[button]
	end
	scene:onInputRelease({input=input_released, type="joybutton", name=joystick:getName(), button=button})
end

function love.gamepadaxis(joystick, axis, value)
	local input_pressed = nil
	local positive_released = nil
	local negative_released = nil
	if
		config.input and
		config.input.joysticks and
		config.input.joysticks[joystick:getName()] and
		config.input.joysticks[joystick:getName()].axes and
		config.input.joysticks[joystick:getName()].axes[axis] 
	then
		if math.abs(value) >= 1 then
			input_pressed = config.input.joysticks[joystick:getName()].axes[axis][value >= 1 and "positive" or "negative"]
		end
		positive_released = config.input.joysticks[joystick:getName()].axes[axis].positive
		negative_released = config.input.joysticks[joystick:getName()].axes[axis].negative
	end
	if math.abs(value) >= 1 then
		scene:onInputPress({input=input_pressed, type="joyaxis", name=joystick:getName(), axis=axis, value=value})
	else
		scene:onInputRelease({input=positive_released, type="joyaxis", name=joystick:getName(), axis=axis, value=value})
		scene:onInputRelease({input=negative_released, type="joyaxis", name=joystick:getName(), axis=axis, value=value})
	end
end

local last_hat_direction = ""
local directions = {
	["u"] = "up",
	["d"] = "down",
	["l"] = "left",
	["r"] = "right",
}

function love.wheelmoved(x, y)
	scene:onInputPress({input=nil, type="wheel", x=x, y=y})
end

function love.touchpressed(id, x, y, dx, dy, pressure)
	if scene.title == "Game" then
		love.keypressed("escape", "escape")
		love.keyreleased("escape", "escape")

	else
		for _, b in ipairs(touchButtons) do
			if x >= b[1] and y >= b[2] and x <= b[1]+b[3] and y <= b[2]+b[4] then
				-- local scancode = b[10]
				-- local key = b[9]

				-- local input_pressed = nil
				-- if config.input and config.input.keys then
				-- 	input_pressed = config.input.keys[scancode]
				-- end
				-- scene:onInputPress({input=input_pressed, type="key", key=key, scancode=scancode})

				love.keypressed(b[9], b[10])
				break
			end
		end

	end
end

function love.touchreleased(id, x, y, dx, dy, pressure)
	-- local scancode = "tab"
	-- local key = "tab"

	-- local input_released = nil
	-- if config.input and config.input.keys then
	-- 	input_released = config.input.keys[scancode]
	-- end
	-- scene:onInputRelease({input=input_released, type="key", key=key, scancode=scancode})

	for _, b in ipairs(touchButtons) do
		if x >= b[1] and y >= b[2] and x <= b[1]+b[3] and y <= b[2]+b[4] then
			love.keyreleased(b[9], b[10])
			break
		end
	end
end

function love.focus(f)
	if f then
		resumeBGM(true)
	else
		pauseBGM(true)
	end
end

function love.resize(w, h)
		GLOBAL_CANVAS:release()
		GLOBAL_CANVAS = love.graphics.newCanvas(w, h)
end

local TARGET_FPS = 60
local FRAME_DURATION = 1.0 / TARGET_FPS

function love.run()
	if love.load then love.load(love.arg.parseGameArguments(arg), arg) end

	-- if love.timer then love.timer.step() end

	local dt = 0

	if love.timer then
		dt = love.timer.step()
	end

	-- 3DS STUFF
	local normalScreens = love.graphics.getScreens()
	local plainScreens
	if love._console_name == "3DS" then
		plainScreens = {"top", "bottom"}
	end
	--

	local last_time = love.timer.getTime()
	local time_accumulator = 0.0
	return function()
		if love.event then
			love.event.pump()
			for name, a,b,c,d,e,f in love.event.poll() do
				if name == "quit" then
					if not love.quit or not love.quit() then
						return a or 0
					end
				end
				love.handlers[name](a,b,c,d,e,f)
			end
		end

		if love.timer then
			processBGMFadeout(love.timer.step())
		end
		
		if scene and scene.update and love.timer then
			scene:update()

			if time_accumulator < FRAME_DURATION then
				if love.graphics and love.graphics.isActive() and love.draw then
					-- love.graphics.origin()
					-- love.graphics.clear(love.graphics.getBackgroundColor())
					-- love.draw()
					-- love.graphics.present()

					local screens = love.graphics.get3D() and normalScreens or plainScreens

					for _, screen in ipairs(screens) do
						love.graphics.origin()

						love.graphics.setActiveScreen(screen)
						love.graphics.clear(love.graphics.getBackgroundColor())

						if love.draw then
							love.draw(screen)
						end
					end

					love.graphics.present()
				end

				-- request 1ms delays first but stop short of overshooting, then do "0ms" delays without overshooting (0ms requests generally do a delay of some nonzero amount of time, but maybe less than 1ms)
				for milliseconds=0.001,0.000,-0.001 do
					local max_delay = 0.0
					while max_delay < FRAME_DURATION do
						local delay_start_time = love.timer.getTime()
						if delay_start_time - last_time < FRAME_DURATION - max_delay then
							love.timer.sleep(milliseconds)
							local last_delay = love.timer.getTime() - delay_start_time
							if last_delay > max_delay then
								max_delay = last_delay
							end
						else
							break
						end
					end
				end
				while love.timer.getTime() - last_time < FRAME_DURATION do
					-- busy loop, do nothing here until delay is finished; delays above stop short of finishing, so this part can finish it off precisely
				end
			end

			local finish_delay_time = love.timer.getTime()
			local real_frame_duration = finish_delay_time - last_time
			time_accumulator = time_accumulator + real_frame_duration - FRAME_DURATION
			last_time = finish_delay_time
		end
	end
end

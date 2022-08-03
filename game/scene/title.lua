local TitleScene = Scene:extend()

TitleScene.title = "Title"
TitleScene.restart_message = false

local main_menu_screens = {
	ModeSelectScene,
	ReplaySelectScene,
	SettingsScene,
	CreditsScene,
	ExitScene,
}

local mainmenuidle = {
	"Idle",
	"On title screen",
	"On main menu screen",
	"Twiddling their thumbs",
	"Admiring the main menu's BG",
	"Waiting for spring to come",
	"Actually not playing",
	"Contemplating collecting stars",
	"Preparing to put the block!!",
	"Having a nap",
	"In menus",
	"Bottom text",
	"Trying to see all the funny rpc messages (maybe)",
	"Not not not playing",
	"AFK",
	"Preparing for their next game",
	"Who are those people on that boat?",
	"Welcome to Cambridge!",
	"who even reads these",
	"Made with love in LOVE!",
	"This is probably the longest RPC string out of every possible RPC string that can be displayed."
}

function TitleScene:new()
	self.main_menu_state = 1
	self.frames = 0
	self.snow_bg_opacity = 0
	self.y_offset = 0
	self.text = ""
	self.text_flag = false
	-- DiscordRPC:update({
	-- 	details = "In menus",
	-- 	state = mainmenuidle[love.math.random(#mainmenuidle)],
	-- 	largeImageKey = "icon2",
	-- 	largeImageText = version
	-- })
end

function TitleScene:update()
	if self.text_flag then
		self.frames = self.frames + 1
		self.snow_bg_opacity = self.snow_bg_opacity + 0.01
	end
	if self.frames < 125 then self.y_offset = self.frames
	elseif self.frames < 185 then self.y_offset = 125
	else self.y_offset = 310 - self.frames end
end

local block_offsets = {
	{color = "M", x = 0, y = 0},
	{color = "G", x = 32, y = 0},
	{color = "Y", x = 64, y = 0},
	{color = "B", x = 0, y = 32},
	{color = "O", x = 0, y = 64},
	{color = "C", x = 32, y = 64},
	{color = "R", x = 64, y = 64}
}

function TitleScene:render()
	love.graphics.setFont(font_3x5_4)
	love.graphics.setColor(1, 1, 1, 1 - self.snow_bg_opacity)

	love.graphics.draw(
		backgrounds["title_no_icon"],
		-80, 0, 0,
		2, 2
	)

	-- 490, 192
	for _, b in ipairs(block_offsets) do
		love.graphics.draw(
			blocks["2tie"][b.color],
			490 + b.x, 192 + b.y, 0,
			2, 2
		)
	end

	--[[
	love.graphics.draw(
		misc_graphics["icon"],
		490, 192, 0,
		2, 2
	)
	]]
	--love.graphics.printf("Thanks for 1 year!", 430, 280, 160, "center")

	love.graphics.setFont(font_3x5_3)
	-- love.graphics.setColor(1, 1, 1, self.snow_bg_opacity)
	-- love.graphics.draw(
	-- 	backgrounds["snow"],
	-- 	0, 0, 0,
	-- 	0.5, 0.5
	-- )

	-- love.graphics.draw(
	-- 	misc_graphics["santa"],
	-- 	400, -205 + self.y_offset,
	-- 	0, 0.5, 0.5
	-- )
	-- love.graphics.print("Happy Holidays!", 320, -100 + self.y_offset)

	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.print(self.restart_message and "Restart Cambridge..." or "", 0, 0)

	love.graphics.setColor(0, 0, 0, 0.75)
	love.graphics.rectangle("fill", 20, 278 + 32 * self.main_menu_state, 160, 34)

	love.graphics.setColor(1, 1, 1, 1)
	for i, screen in pairs(main_menu_screens) do
		love.graphics.printf(screen.title, 40, 280 + 32 * i, 120, "left")
	end
end

function TitleScene:changeOption(rel)
	local len = table.getn(main_menu_screens)
	self.main_menu_state = (self.main_menu_state + len + rel - 1) % len + 1
end

function TitleScene:onInputPress(e)
	if e.input == "menu_decide" or e.scancode == "return" then
		playSE("main_decide")
		scene = main_menu_screens[self.main_menu_state]()
	elseif e.input == "up" or e.scancode == "up" then
		self:changeOption(-1)
		playSE("cursor")
	elseif e.input == "down" or e.scancode == "down" then
		self:changeOption(1)
		playSE("cursor")
	elseif e.input == "menu_back" or e.scancode == "backspace" or e.scancode == "delete" then
		love.event.quit()
	else
		self.text = self.text .. (e.scancode or "")
		if self.text == "ffffff" then
			self.text_flag = true
			-- DiscordRPC:update({
			-- 	largeImageKey = "snow"
			-- })
		end
	end
end

return TitleScene

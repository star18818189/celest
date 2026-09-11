-- CelestialTab module.
local CelestialTab = {}

---@module GUI.ThemeManager
local ThemeManager = require("GUI/ThemeManager")

---@module GUI.SaveManager
local SaveManager = require("GUI/SaveManager")

---@module GUI.Library
local Library = require("GUI/Library")

---@module Utility.Logger
local Logger = require("Utility/Logger")

local BACKGROUND_FOLDER = "Celestial v1.03-Backgrounds"
local IMAGE_EXTENSIONS = {
	png = true,
	jpg = true,
	jpeg = true,
	bmp = true,
	webp = true,
}

local function trim(value)
	return tostring(value or ""):match("^%s*(.-)%s*$")
end

local function ensureBackgroundFolder()
	if type(isfolder) ~= "function" or type(makefolder) ~= "function" then
		return false
	end

	if not isfolder(BACKGROUND_FOLDER) then
		local success = pcall(makefolder, BACKGROUND_FOLDER)
		if not success then
			return false
		end
	end

	return true
end

local function getBackgroundFiles()
	if type(listfiles) ~= "function" or not ensureBackgroundFolder() then
		return {}
	end

	local success, files = pcall(listfiles, BACKGROUND_FOLDER)
	if not success or type(files) ~= "table" then
		return {}
	end

	local images = {}
	for _, path in next, files do
		local extension = tostring(path):lower():match("%.([%w]+)$")
		if extension and IMAGE_EXTENSIONS[extension] then
			table.insert(images, path)
		end
	end

	table.sort(images)
	return images
end

local function getAssetLoader()
	if type(getcustomasset) == "function" then
		return getcustomasset
	end

	if type(getsynasset) == "function" then
		return getsynasset
	end

	if type(syn) == "table" and type(syn.getcustomasset) == "function" then
		return syn.getcustomasset
	end

	return nil
end

local function hashSource(source)
	local hash = 5381
	for index = 1, #source do
		hash = (hash * 33 + string.byte(source, index)) % 2147483647
	end
	return tostring(hash)
end

local function downloadBackground(url)
	if type(writefile) ~= "function" or type(isfile) ~= "function" or not ensureBackgroundFolder() then
		return nil, "Your executor does not support downloading background files."
	end

	local cleanUrl = url:match("^[^%?#]+") or url
	local extension = cleanUrl:lower():match("%.([%w]+)$")
	if not extension or not IMAGE_EXTENSIONS[extension] then
		extension = "png"
	elseif extension == "jpeg" then
		extension = "jpg"
	end

	local path = string.format("%s/url_%s.%s", BACKGROUND_FOLDER, hashSource(url), extension)
	if isfile(path) then
		return path
	end

	local body
	local requestFunction = request or http_request
	if type(requestFunction) ~= "function" and type(syn) == "table" then
		requestFunction = syn.request
	end

	if type(requestFunction) == "function" then
		local success, response = pcall(requestFunction, {
			Url = url,
			Method = "GET",
		})

		if success and type(response) == "table" then
			local statusCode = tonumber(response.StatusCode or response.Status)
			if response.Success ~= false and (not statusCode or statusCode < 400) then
				body = response.Body or response.body
			end
		end
	end

	if type(body) ~= "string" then
		local success, responseBody = pcall(function()
			return game:HttpGet(url)
		end)
		if success then
			body = responseBody
		end
	end

	if type(body) ~= "string" or body == "" then
		return nil, "The image URL could not be downloaded."
	end

	local success = pcall(writefile, path, body)
	if not success then
		return nil, "The downloaded image could not be saved."
	end

	return path
end

local function resolveBackgroundSource(value)
	local source = trim(value)
	if source == "" then
		return ""
	end

	if source:match("^rbxassetid://%d+$") or source:match("^rbxasset://") then
		return source
	end

	if source:match("^%d+$") then
		return "rbxassetid://" .. source
	end

	if source:lower():find("roblox.com", 1, true) then
		local assetId = source:match("[?&]id=(%d+)") or source:match("/asset/(%d+)")
		if assetId then
			return "rbxassetid://" .. assetId
		end
	end

	local path = source
	if source:match("^https?://") then
		local errorMessage
		path, errorMessage = downloadBackground(source)
		if not path then
			return nil, errorMessage
		end
	elseif type(isfile) ~= "function" then
		return nil, "Your executor does not support local background files."
	elseif not isfile(path) then
		local folderPath = BACKGROUND_FOLDER .. "/" .. source
		if isfile(folderPath) then
			path = folderPath
		else
			return nil, "The selected background file does not exist."
		end
	end

	local assetLoader = getAssetLoader()
	if not assetLoader then
		return nil, "Your executor does not expose getcustomasset or getsynasset."
	end

	local success, asset = pcall(assetLoader, path)
	if not success or type(asset) ~= "string" or asset == "" then
		return nil, "The selected file could not be converted to a Roblox asset."
	end

	return asset
end

---Initialize Cheat Settings section.
---@param groupbox table
function CelestialTab.initCheatSettingsSection(groupbox)
	groupbox:AddButton("Toggle Silent Mode", function()
		if not isfile or not delfile or not writefile then
			return
		end

		shared.Celestial.silent = not shared.Celestial.silent

		if not shared.Celestial.silent then
			Logger.notify("Silent mode was disabled.")
		end

		if isfile("smarker.txt") then
			delfile("smarker.txt")
		else
			writefile(
				"smarker.txt",
				"Hello, if you're reading this, that means you have Celestial v1.03 (Deepwoken) silent mode turned on. Deleting this file will turn it off."
			)
		end
	end)

	groupbox:AddButton("Toggle Player Scanning", function()
		if not isfile or not delfile or not writefile then
			return
		end

		shared.Celestial.dpscanning = not shared.Celestial.dpscanning

		if shared.Celestial.dpscanning then
			Logger.notify("Player scanning was disabled.")
		else
			Logger.notify("Player scanning was enabled.")
		end

		if isfile("dpscanning.txt") then
			delfile("dpscanning.txt")
		else
			writefile(
				"dpscanning.txt",
				"Hello, if you're reading this, that means you have Celestial v1.03 (Deepwoken) player scanning turned off. Deleting this file will turn it on."
			)
		end
	end)

	groupbox:AddButton("Toggle Bloxstrap RPC", function()
		if not isfile or not delfile or not writefile then
			return
		end

		shared.Celestial.norpc = not shared.Celestial.norpc

		if not shared.Celestial.norpc then
			Logger.notify("Bloxstrap RPC was enabled.")
		else
			Logger.notify("Bloxstrap RPC was disabled.")
		end

		if isfile("norpc.txt") then
			delfile("norpc.txt")
		else
			writefile(
				"norpc.txt",
				"Hello, if you're reading this, that means you have Celestial v1.03 (Deepwoken) Bloxstrap RPC turned off. Deleting this file will turn it on."
			)
		end
	end)

	groupbox:AddButton("Unload Cheat", function()
		shared.Celestial.detach()
	end)
end

---Initialize UI Settings section.
---@param groupbox table
function CelestialTab.initUISettingsSection(groupbox)
	groupbox:AddSlider("NotificationScale", {
		Text = "Notification Scale",
		Min = 50,
		Max = 300,
		Default = 100,
		Rounding = 0,
		Suffix = "%",
	})

	groupbox:AddSlider("QuickNotificationSpeed", {
		Text = "Quick Notification Speed",
		Min = 0.1,
		Max = 2.0,
		Default = 0.5,
		Rounding = 2,
		Suffix = "s",
	})

	local menuBindLabel = groupbox:AddLabel("Menu Bind")

	menuBindLabel:AddKeyPicker("MenuKeybind", { Default = "LeftAlt", NoUI = true, Text = "Menu Keybind" })

	local keybindFrameLabel = groupbox:AddLabel("Keybind List Bind")

	keybindFrameLabel:AddKeyPicker("KeybindList", {
		Default = "N/A",
		Mode = "Off",
		NoUI = true,
		Text = "Keybind List",
		Callback = function(Value)
			Library.KeybindFrame.Visible = Value
		end,
	})

	local watermarkFrameLabel = groupbox:AddLabel("Watermark Bind")

	watermarkFrameLabel:AddKeyPicker("Watermark", {
		Default = "N/A",
		Mode = "Off",
		NoUI = true,
		Text = "Watermark",
		Callback = function(Value)
			Library:SetWatermarkVisibility(Value)
		end,
	})
end

---Initialize personalization settings section.
---@param groupbox table
---@param window table
---@param settings table
function CelestialTab.initPersonalizationSection(groupbox, window, settings)
	local defaultDisplayName = settings.DefaultDisplayName or "Celestial v1.03"
	local setDisplayName = settings.SetDisplayName or function() end

	groupbox:AddInput("CustomMenuName", {
		Text = "Display Name",
		Default = defaultDisplayName,
		MaxLength = 48,
		Callback = function(Value)
			local name = trim(Value):gsub("[%c]", "")
			setDisplayName(name ~= "" and name or defaultDisplayName)
		end,
	})

	groupbox:AddButton("Reset Display Name", function()
		Options.CustomMenuName:SetValue(defaultDisplayName)
	end)

	groupbox:AddDivider()
	groupbox:AddLabel("Use a Roblox asset ID, direct image URL, or local image path.", true)

	local function applyBackground(Value)
		local asset, errorMessage = resolveBackgroundSource(Value)
		if not asset then
			return Library:Notify(errorMessage, 4)
		end

		window:SetBackgroundImage(asset)
	end

	groupbox:AddInput("MenuBackgroundSource", {
		Text = "Background Source",
		Placeholder = "Asset ID, https://...jpg, or file path",
		Finished = true,
		Callback = applyBackground,
	})

	groupbox:AddSlider("MenuBackgroundOpacity", {
		Text = "Background Opacity",
		Min = 0,
		Max = 100,
		Default = 55,
		Rounding = 0,
		Suffix = "%",
		Callback = function(Value)
			window:SetBackgroundOpacity(Value / 100)
		end,
	})

	local backgroundFiles = groupbox:AddDropdown("MenuBackgroundFileList", {
		Text = "Background Files",
		Values = getBackgroundFiles(),
		AllowNull = true,
	})

	groupbox
		:AddButton("Use Selected File", function()
			if not backgroundFiles.Value then
				return Library:Notify("Select a background file first.", 3)
			end

			Options.MenuBackgroundSource:SetValue(backgroundFiles.Value)
		end)
		:AddButton("Refresh Files", function()
			backgroundFiles:SetValues(getBackgroundFiles())
			backgroundFiles:SetValue(nil)
		end)

	groupbox
		:AddButton("Apply Background", function()
			applyBackground(Options.MenuBackgroundSource.Value)
		end)
		:AddButton("Clear Background", function()
			Options.MenuBackgroundSource:SetValue("")
			window:ClearBackgroundImage()
		end)

	window:SetBackgroundOpacity(0.55)
end

---Initialize tab.
---@param settings table
function CelestialTab.init(window, settings)
	settings = settings or {}

	-- Create tab.
	local tab = window:AddTab("Settings") -- dont change the name, it's more confusing if its named that way

	-- Initialize sections.
	CelestialTab.initCheatSettingsSection(tab:AddLeftGroupbox("Cheat Settings"))
	CelestialTab.initUISettingsSection(tab:AddRightGroupbox("UI Settings"))
	CelestialTab.initPersonalizationSection(tab:AddLeftGroupbox("Personalization"), window, settings)

	-- Configure SaveManager & ThemeManager.
	ThemeManager:ApplyToTab(tab)
	SaveManager:BuildConfigSection(tab)
end

-- Return CelestialTab module.
return CelestialTab

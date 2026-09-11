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

---Initialize tab.
function CelestialTab.init(window)
	-- Create tab.
	local tab = window:AddTab("Settings") -- dont change the name, it's more confusing if its named that way

	-- Initialize sections.
	CelestialTab.initCheatSettingsSection(tab:AddLeftGroupbox("Cheat Settings"))
	CelestialTab.initUISettingsSection(tab:AddRightGroupbox("UI Settings"))

	-- Configure SaveManager & ThemeManager.
	ThemeManager:ApplyToTab(tab)
	SaveManager:BuildConfigSection(tab)
end

-- Return CelestialTab module.
return CelestialTab

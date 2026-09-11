-- Check for table that is shared between executions.
if not shared then
	return warn("No shared, no script.")
end

-- Initialize Luraph globals if they do not exist.
loadstring("getfenv().LPH_NO_VIRTUALIZE = function(...) return ... end")()

getfenv().PP_SCRAMBLE_NUM = function(...)
	return ...
end

getfenv().PP_SCRAMBLE_STR = function(...)
	return ...
end

getfenv().PP_SCRAMBLE_RE_NUM = function(...)
	return ...
end

---@module Utility.Profiler
local Profiler = require("Utility/Profiler")

-- Keep the standalone build complete even though this utility currently has no callers.
require("Utility/Buffer")

---@module Celestial
local Celestial = require("Celestial")

---Find existing instances and initialize the script.
local function initializeScript()
	-- Check if there's already another instance.
	if shared.Celestial then
		-- Detach previous instance.
		shared.Celestial.detach()

		-- Share the previous state.
		Celestial.queued = shared.Celestial.queued
	end

	-- Re-initialize under the new state.
	shared.Celestial = Celestial
	shared.Celestial.init()
end

---This is called when the initalization errors.
---@param error string
local function onInitializeError(error)
	-- Warn that an error happened while initializing.
	warn("Failed to initialize.")
	warn(error)

	-- Warn traceback.
	warn(debug.traceback())

	-- Detach the current instance.
	Celestial.detach()
end

-- Safely profile and initialize the script aswell as handle errors.
Profiler.run("Main_InitializeScript", function(...)
	return xpcall(initializeScript, onInitializeError, ...)
end)

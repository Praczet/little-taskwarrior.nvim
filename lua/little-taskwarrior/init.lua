local M = {}
local utils = require("little-taskwarrior.utils")
local dashboard = require("little-taskwarrior.dashboard")
local tasks = require("little-taskwarrior.tasks")

--- Default configuration
M.config = {
	--- configuration for the Dashboard
	dashboard = {
		--- task limit
		limit = 5,
		--- max number of columns
		max_width = 50,
		--- if > 0 then  additional task (besides current project ones) will be added
		non_project_limit = 5,
		--- not used yet
		use_colors = true,
		--- List of columns to be displayed
		columns = {
			"id",
			"project",
			"description",
			"due",
			"urgency",
		},
		--- List of replacements when getting lines for dashboard
		project_replacements = {
			["work."] = "w.",
			["personal."] = "p.",
		},
	},
	--- toggle the loggin
	debug = true,
	--- where information about taskwarrior poject can be found
	project_info = ".little-taskwarrior.json",
	--- not uset yet (the idea is to mark task about this)
	urgency_threshold = 9,
}

---Gets list of lines with tasks
---@return table Tasks list
function M.get_dashboard_tasks()
	return dashboard.get_lines()
end

---Setting utlis, tasks and dashboard
---@param user_config any
function M.setup(user_config)
	utils.debug = M.config.debug
	utils.log_message("init.M.setup", "Setting up Little Taskwarrior") -- Debug print
	M.config = vim.tbl_deep_extend("force", M.config, user_config or {})
	tasks.setup(M.config)
	dashboard.setup(M.config)
	M.initialize()
end

---Just adding log, if active for now this does nothing
function M.initialize()
	utils.log_message("init.M.initialize", "Initializing Little Taskwarrior") -- Debug print
end

return M

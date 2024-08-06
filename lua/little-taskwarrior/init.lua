local M = {}
local utils = require("little-taskwarrior.utils")
local dashboard = require("little-taskwarrior.dashboard")
local tasks = require("little-taskwarrior.tasks")

-- Default configuration
M.config = {
	dashboard = {
		limit = 5,
		max_width = 50,
		non_project_limit = 5,
		use_colors = true,
	},
	debug = true,
	project_info = ".little-taskwarrior.json",
	urgency_threshold = 9,
}

function M.get_dashboard_tasks()
	return dashboard.get_lines()
end

function M.setup(user_config)
	utils.debug = M.config.debug
	utils.log_message("init.M.setup", "Setting up Little Taskwarrior") -- Debug print
	M.config = vim.tbl_deep_extend("force", M.config, user_config or {})
	tasks.setup(M.config)
	dashboard.setup(M.config)
	M.initialize()
end

function M.initialize()
	utils.log_message("init.M.initialize", "Initializing Little Taskwarrior") -- Debug print
end

return M

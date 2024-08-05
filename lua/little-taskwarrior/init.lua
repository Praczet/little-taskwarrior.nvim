local M = {}
-- local utils = require("little-taskwarrior.utils")

-- Default configuration
M.config = {
	dashboard_limit = 5,
	notes_folder = nil,
	debug = true,
}

function M.setup(user_config)
	-- utils.debug = M.config.debug
	-- utils.log_message("init.M.setup", "Setting up Little Taskwarrior") -- Debug print
	M.config = vim.tbl_deep_extend("force", M.config, user_config or {})
	M.initialize()
end

function M.initialize()
	-- utils.log_message("init.M.initialize", "Initializing Little Taskwarrior") -- Debug print
end

local function get_urgnet(limit)
	local handle = io.popen("task status:pending and project:Me export ls limit:5")
	local result = handle:read("*a")
	handle:close()
	return vim.fn.json_decode(result)
end

function M.tasks_get_urgent(limit)
	if limit == nil then
		limit = M.config.dashboard_limit
	end
	if limit <= 0 then
		limit = 5
	end
	print(limit)
	-- return get_urgnet(limit)
end

return M

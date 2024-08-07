local M = {}
local utils = require("little-taskwarrior.utils")
M.config = {}

local function get_urgnet(limit, project, exlude)
	local prj_string = ""
	if project ~= nil then
		if exlude ~= nil and exlude == true then
			prj_string = "and project.not:" .. project
		else
			prj_string = "and project:" .. project
		end
	end
	local cmd = string.format("task status:pending %s export ls ", prj_string)
	local handle = io.popen(cmd)
	if handle == nil then
		return {}
	end
	local result = handle:read("*a")
	handle:close()
	if result == nil then
		return {}
	end
	local tasks = vim.fn.json_decode(result)
	utils.sort_by_column(tasks, "urgency")
	return utils.slice(tasks, 1, limit)
end

function M.tasks_get_urgent(limit, project, exclude)
	local l_limit = M.config.dashboard.limit
	if limit ~= nil and limit > 0 then
		limit = l_limit
	end
	return get_urgnet(limit, project, exclude)
end

function M.setup(user_config)
	utils.log_message("tasks.M.setup", "Setting up Tassks")
	M.config = vim.tbl_deep_extend("force", M.config, user_config or {})
end

return M

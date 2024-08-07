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

function M.display_tasks()
	-- Create a new buffer for the output
	local output_buf = vim.api.nvim_create_buf(false, true)

	-- Get the formatted output as a string
	local formatted_output = { "" }

	-- Set the contents of the output buffer
	vim.api.nvim_buf_set_lines(output_buf, 0, -1, false, formatted_output)
	--
	local lines_displayed = vim.api.nvim_win_get_height(0)
	local row = math.floor(lines_displayed * 0.1) + 1
	local col = math.floor(vim.o.columns * 0.1)

	-- Set the options for the new window
	local opts = {
		relative = "editor",
		row = row,
		col = col,
		width = math.floor(vim.o.columns * 0.8),
		height = math.floor(lines_displayed * 0.8),
		style = "minimal",
		border = "rounded",
		title = "Tasks",
		title_pos = "center",
	}

	-- Open a new floating window with the output buffer
	vim.api.nvim_open_win(output_buf, true, opts)

	-- Set the terminal buffer to use the 'task' command
	vim.fn.termopen("task")

	-- Start insert mode in the terminal
	vim.cmd("startinsert")
	-- Switch back to the original buffer
	-- vim.api.nvim_set_current_buf(current_buf)
end

return M

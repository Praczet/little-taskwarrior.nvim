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

local function setup_commands()
	-- vim.api.nvim_create_user_command("Task", function(opts)
	-- 	require("little-taskwarrior.tasks").display_tasks(unpack(opts.fargs))
	-- end, { nargs = "*", complete = "custom,v:lua.complete_task_args" })
	-- _G.complete_task_args = function(arglead, cmdline, cursorpos)
	-- 	-- Provide a list of taskwarrior arguments for completion
	-- 	return { "project:work", "status:pending", "priority:H", "due.before:today", "tag:home" }
	-- end
	vim.api.nvim_create_user_command("Task", function(opts)
		require("little-taskwarrior.tasks").display_tasks(unpack(opts.fargs))
	end, { nargs = "*" })
end

function M.setup(user_config)
	utils.log_message("tasks.M.setup", "Setting up Tassks")
	M.config = vim.tbl_deep_extend("force", M.config, user_config or {})
	setup_commands()
end

function M.display_tasks(...)
	local args = { ... }
	local cmd = "task"
	for _, arg in ipairs(args) do
		cmd = cmd .. " " .. arg
	end
	-- Create a new buffer for the output
	local output_buf = vim.api.nvim_create_buf(false, true)

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
	local win_id = vim.api.nvim_open_win(output_buf, true, opts)

	-- Set the terminal buffer to use the 'task' command
	vim.fn.termopen(cmd .. " & read", {
		on_exit = function(_, _, _)
			utils.log_message("tasks.M.display_tasks", "on_exit")
			vim.api.nvim_win_close(win_id, true)
			vim.api.nvim_buf_delete(output_buf, { force = true })
		end,
	})
	-- Start insert mode in the terminal
	vim.cmd("startinsert")
end

return M

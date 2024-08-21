local M = {}
local utils = require("little-taskwarrior.utils")
M.config = {}
local todo = {}

local function get_urgnet(limit, project, exclude)
	local prj_string = ""
	if project ~= nil then
		if exclude ~= nil and exclude == true then
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
	if limit > 0 then
		return utils.slice(tasks, 1, limit)
	end
	return tasks
end

function M.tasks_get_urgent(limit, project, exclude)
	limit = limit or M.config.dashboard.limit
	return get_urgnet(limit, project, exclude)
end

local function build_task_dict(tasks)
	local task_dict = {}
	for _, task in ipairs(tasks) do
		task_dict[task.uuid] = task
	end
	return task_dict
end

local function find_root_tasks_depends(tasks)
	-- local root_tasks = {}
	-- for _, task in ipairs(tasks) do
	-- 	if not task.depends or #task.depends == 0 then
	-- 		table.insert(root_tasks, task)
	-- 	end
	-- end
	-- return root_tasks
	local is_dependent = {}

	-- Mark all tasks that are dependencies
	for _, task in ipairs(tasks) do
		if task.depends then
			for _, dep_id in ipairs(task.depends) do
				is_dependent[dep_id] = true
			end
		end
	end

	-- Root tasks are those that are not marked as dependencies
	local root_tasks = {}
	for _, task in ipairs(tasks) do
		if not is_dependent[task.uuid] then
			table.insert(root_tasks, task)
		end
	end

	return root_tasks
end

-- Recursive function to print tasks hierarchically
local function add_todo(task, task_dict, indent)
	indent = indent or 0
	table.insert(todo, { indent = indent, task = task })
	if task.depends then
		for _, dep_id in ipairs(task.depends) do
			if task_dict[dep_id] then
				add_todo(task_dict[dep_id], task_dict, indent + 1)
			end
		end
	end
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
			if utils.is_dashboard_open() then
				-- refresh dashboard
				utils.refresh_dashboard()
			else
			end
		end,
	})
	-- Start insert mode in the terminal
	vim.cmd("startinsert")
end

local function get_todo_depends(tasks)
	local task_dict = build_task_dict(tasks)
	local root_tasks = find_root_tasks_depends(tasks) or {}
	todo = {}
	for _, root_task in ipairs(root_tasks) do
		add_todo(root_task, task_dict)
	end
	return todo
end

function M.get_todo(project, group_by, limit)
	limit = limit or -1
	group_by = group_by or "depends"
	local tasks = M.tasks_get_urgent(limit, project)
	if group_by == "depends" then
		return get_todo_depends(tasks)
	else
		return {}
	end
end

function M.test()
	local tasks_todo = M.get_todo("personal")
	print(vim.inspect(tasks_todo))
end
function M.setup(user_config)
	utils.log_message("tasks.M.setup", "Setting up Tassks")
	M.config = vim.tbl_deep_extend("force", M.config, user_config or {})
	setup_commands()
end

return M

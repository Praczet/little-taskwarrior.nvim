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
		sec_sep = ".", -- Define your section separator here
		shorten_sections = true, -- Enable or disable section shortening
	},
	--- function to reload dashboard config
	get_dashboard_config = nil,
	--- toggle the loggin
	debug = true,
	--- where information about taskwarrior poject can be found
	project_info = ".little-taskwarrior.json",
	--- not uset yet (the idea is to mark task about this)
	urgency_threshold = 8,
	highlight_groups = {
		urgent = nil,
		not_urgent = nil,
	},
}

local function setup_commands()
	vim.api.nvim_create_user_command("Task2ToDo", function(opts)
		require("little-taskwarrior").render_markdown_todos(unpack(opts.fargs))
	end, { nargs = "*" })
end

---Gets list of lines with tasks
---@return table Tasks list
function M.get_dashboard_tasks(maxwidth)
	return dashboard.get_lines(maxwidth)
end

function M.get_markdown_todos(project, group_by, limit)
	local todos = tasks.get_todo(project, group_by, limit) or {}
	local todos_lines = {}
	for _, todo in ipairs(todos) do
		table.insert(todos_lines, string.rep(" ", todo.indent * 2) .. "- [ ] " .. todo.task.description)
	end
	return todos_lines
end

function M.render_markdown_todos(project, group_by, limit)
	local todos_lines = M.get_markdown_todos(project, group_by, limit)
	local row, col = unpack(vim.api.nvim_win_get_cursor(0))
	vim.api.nvim_buf_set_lines(0, row, row, true, todos_lines)
	vim.api.nvim_win_set_cursor(0, { row + #todos_lines, col })
end

function M.test()
	print(table.concat(M.get_markdown_todos("personal", "depends"), "\n"))
end

function M.get_dashboard_config()
	if M.config and M.config.get_dashboard_config then
		return M.config.get_dashboard_config()
	end
	return nil
end

---Setting utlis, tasks and dashboard
---@param user_config any
function M.setup(user_config)
	M.config = vim.tbl_deep_extend("force", M.config, user_config or {})
	utils.debug = M.config.debug
	utils.log_message("init.M.setup", "------------------------------------")
	utils.log_message("init.M.setup", "Setting up Little Taskwarrior") -- Debug print
	utils.get_dashboard_config = M.config.get_dashboard_config
	tasks.setup(M.config)
	dashboard.setup(M.config)
	M.initialize()
end

---Just adding log, if active for now this does nothing
function M.initialize()
	utils.log_message("init.M.initialize", "Initializing Little Taskwarrior") -- Debug print
	setup_commands()
end

return M

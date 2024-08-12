local M = {}
local utils = require("little-taskwarrior.utils")
local tasks = require("little-taskwarrior.tasks")
local urgent_lines = {}
local not_urgent_lines = {}

M.config = {
	dashboard = {
		limit = 5,
		max_width = 30,
		non_project_limit = 5,
		columns = {
			"id",
			"project",
			"description",
			"due",
			"urgency",
		},
		projects_replacements = {
			["work."] = "w.",
			["personal."] = "p.",
		},
	},
	urgency_threshold = 8,
	highlight_groups = {
		urgent = nil,
		not_urgent = nil,
	},
}

M.project = nil

---Check if the current buffor directroy contains a project.json, if so,
---it return project name
---@return nil
local function get_project()
	local content = utils.read_file(M.config.project_info)
	if content == nil then
		return nil
	end
	local json = vim.fn.json_decode(content)
	if json == nil or json.project == nil or json.project == "" then
		return nil
	end
	return json.project
end

---Clips text to given width and if the text is longer than given width it will add "..."
---@param text string text to clip
---@param width number max width that text can have
---@return string text Clipped text
local function clip_text(text, width)
	if #text > width then
		text = text:sub(1, width - 3) .. "..."
	end
	return text
end

local function parse_line(task, columnsWidth)
	local line = {}
	for _, column in ipairs(M.config.dashboard.columns) do
		local sl = " "
		if _ == 1 then
			sl = ""
		end
		local width = columnsWidth[column]
		local value = tostring(task[column] or "")
		if column == "project" and value ~= "" then
			value = "[" .. value .. "]"
		end
		value = clip_text(value, width)
		if column == "urgency" then
			table.insert(line, string.format(sl .. "%" .. width .. "s", value))
		else
			table.insert(line, string.format(sl .. "%-" .. width .. "s", value))
		end
	end
	return table.concat(line, "")
end

local function sanitize_task(task)
	for k, v in pairs(task) do
		if v ~= nil then
			if k == "urgency" then
				task[k] = string.format("%.2f", v)
			elseif k == "due" then
				utils.log_message("dashboard.sanitize_task", "[" .. task["id"] .. "]" .. "due (v): " .. v)
				local current_year = os.date("%Y")
				local pattern = "^" .. current_year .. "%-(.*)"
				local date_string = tostring(utils.get_os_date(v, "%Y-%m-%d"))
				local new_date_string = date_string:match(pattern)
				task[k] = new_date_string or date_string
			elseif k == "project" then
				task[k] = utils.replace_project_name(v, M.config.dashboard)
			end
		else
			task[k] = ""
		end
	end
	return task
end

local function sanitize_tasks(task_list)
	for _, task in ipairs(task_list) do
		task = sanitize_task(task)
	end
end

local function get_columns_width(task_list, other_tasks)
	utils.log_message("dashboard.get_columns_width", "Getting columns width")
	local columnsWidth = {}
	local max_width = M.config.dashboard.max_width
	local needed_for_padding = #M.config.dashboard.columns
	local total_width = 0
	sanitize_tasks(task_list)
	sanitize_tasks(other_tasks)
	for _, column in ipairs(M.config.dashboard.columns) do
		columnsWidth[column] = 0
		for _, task in ipairs(task_list) do
			if task[column] ~= nil then
				-- task = sanitize_task(task)
				columnsWidth[column] = math.max(columnsWidth[column], #tostring(task[column]))
			end
		end
		for _, task in ipairs(other_tasks) do
			if task[column] ~= nil then
				-- task = sanitize_task(task)
				columnsWidth[column] = math.max(columnsWidth[column], #tostring(task[column]))
			end
		end
		total_width = total_width + columnsWidth[column]
	end
	if columnsWidth["project"] ~= nil then
		columnsWidth["project"] = columnsWidth["project"] + 2
	end
	if columnsWidth["description"] ~= nil then
		local delta = (max_width - total_width) - needed_for_padding
		columnsWidth["description"] = columnsWidth["description"] + delta
	end
	return columnsWidth
end

function M.get_tasks()
	local main_tasts = tasks.tasks_get_urgent(M.config.dashboard.limit, M.project)
	local other_tasks = {}
	if
		M.project ~= nil
		and M.config.dashboard.non_project_limit ~= nil
		and M.config.dashboard.non_project_limit > 0
	then
		other_tasks = tasks.tasks_get_urgent(M.config.dashboard.non_project_limit, M.project, true)
	end
	return main_tasts, other_tasks
end

function M.get_lines()
	utils.log_message("dashboard.M.get_lines", "Getting lines")
	local lines = {}
	local task_list, other_tasks = M.get_tasks()
	local columnsWidth = get_columns_width(task_list, other_tasks)

	for _, task in ipairs(task_list) do
		local line = parse_line(task, columnsWidth)
		utils.log_message("dashboard.M.get_lines", "task.urgency: " .. tonumber(task.urgency))
		if
			task.urgency ~= nil
			and M.config.urgency_threshold ~= nil
			and tonumber(task.urgency) >= M.config.urgency_threshold
		then
			utils.log_message("dashboard.M.get_lines", "Adding urgent line")
			table.insert(urgent_lines, line)
		else
			utils.log_message("dashboard.M.get_lines", "Adding not urgent line")
			table.insert(not_urgent_lines, line)
		end
		table.insert(lines, line)
	end

	if #other_tasks > 0 and M.project and #task_list > 0 then
		table.insert(lines, "--+--")
	end

	for _, task in ipairs(other_tasks) do
		local line = parse_line(task, columnsWidth)
		utils.log_message("dashboard.M.get_lines", "task.urgency: " .. tonumber(task.urgency))
		if
			task.urgency ~= nil
			and M.config.urgency_threshold ~= nil
			and tonumber(task.urgency) >= M.config.urgency_threshold
		then
			utils.log_message("dashboard.M.get_lines", "Adding urgent line")
			table.insert(urgent_lines, line)
		else
			utils.log_message("dashboard.M.get_lines", "Adding not urgent line")
			table.insert(not_urgent_lines, line)
		end
		table.insert(lines, line)
	end
	return lines
end

--- Gets default highlight groups
--- @param which string (urgent|not_urgent) group name
--- @return table hl Highlight definition
local function get_default_hl_group(which)
	if which == "urgent" then
		local hl = vim.api.nvim_get_hl(0, { name = "@keyword" })
		return {
			bg = hl.bg,
			fg = hl.fg,
			cterm = hl.cterm,
			bold = hl.bold,
			italic = hl.italic,
			reverse = hl.reverse,
		}
	elseif which == "not_urgent" then
		local hl = vim.api.nvim_get_hl(0, { name = "Comment" })
		return {
			bg = hl.bg,
			fg = hl.fg,
			cterm = hl.cterm,
			bold = hl.bold,
			italic = hl.italic,
			reverse = hl.reverse,
		}
	else
		return {
			italic = true,
		}
	end
end

local function setup_hl_groups()
	local hl_urgent = nil
	if M.config.highlight_groups and M.config.highlight_groups.urgent then
		hl_urgent = M.config.highlight_groups.urgent
	else
		hl_urgent = get_default_hl_group("urgent")
	end
	if hl_urgent then
		vim.api.nvim_set_hl(0, "LTWDashboardHeaderUrgent", hl_urgent)
	end
	local hl_not_urgent = nil

	if M.config.highlight_groups and M.config.highlight_groups.not_urgent then
		hl_not_urgent = M.config.highlight_groups.not_urgent
	else
		hl_not_urgent = get_default_hl_group("not_urgent")
	end
	if hl_not_urgent then
		vim.api.nvim_set_hl(0, "LTWDashboardHeader", hl_not_urgent)
	end
end

local function hl_tasks()
	setup_hl_groups()
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	utils.log_message("dashboard.hl_tasks", "Lines: " .. vim.inspect(urgent_lines))
	for i, line in ipairs(lines) do
		if utils.in_table(urgent_lines, line) then
			vim.api.nvim_buf_add_highlight(0, -1, "LTWDashboardHeaderUrgent", i - 1, 0, -1)
		elseif utils.in_table(not_urgent_lines, line) then
			vim.api.nvim_buf_add_highlight(0, -1, "LTWDashboardHeader", i - 1, 0, -1)
		end
	end
end

function M.setup(user_config)
	utils.log_message("dashboard.M.setup", "Setting up Dashboard")
	M.config = vim.tbl_deep_extend("force", M.config, user_config or {})
	M.project = get_project()
	vim.api.nvim_create_autocmd("User", {
		pattern = "DashboardLoaded",
		callback = hl_tasks,
	})
	-- vim.api.nvim_create_autocmd({ "BufWipeout" }, {
	-- 	buffer = 0, -- Use 0 to apply to the current buffer
	-- 	callback = function()
	-- 		if vim.api.nvim_get_current_buf() == dashboard_bffnr then
	-- 			clear_dashboard_highlight()
	-- 		end
	-- 	end,
	-- })
end

return M

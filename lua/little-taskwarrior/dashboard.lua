local M = {}
local utils = require("little-taskwarrior.utils")
local tasks = require("little-taskwarrior.tasks")
M.config = {
	dashboard = {
		limit = 5,
		max_width = 30,
		non_project_limit = 5,
		use_colors = true,
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
	urgency_threshold = 9,
}
M.project = nil
M.hl = {
	urgency = {
		name = "LittleTaskWarriorUrgency",
		color = "#ff0000",
	},
}

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
				local current_year = os.date("%Y")
				local pattern = "^" .. current_year .. "%-(.*)"
				local date_string = tostring(utils.get_os_date(v, "%Y-%m-%d"))
				local new_date_string = date_string:match(pattern)
				task[k] = new_date_string or date_string
			elseif k == "project" then
				task[k] = utils.replace_project_name(v, M.config.dashboard.projects_replacements)
			end
		else
			task[k] = ""
		end
	end
	return task
end

local function get_columns_width(task_list, other_tasks)
	local columnsWidth = {}
	local max_width = M.config.dashboard.max_width
	local needed_for_padding = #M.config.dashboard.columns
	local total_width = 0
	for _, column in ipairs(M.config.dashboard.columns) do
		columnsWidth[column] = 0
		for _, task in ipairs(task_list) do
			if task[column] ~= nil then
				task = sanitize_task(task)
				columnsWidth[column] = math.max(columnsWidth[column], #tostring(task[column]))
			end
		end
		for _, task in ipairs(other_tasks) do
			if task[column] ~= nil then
				task = sanitize_task(task)
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
	local lines = {}
	local task_list, other_tasks = M.get_tasks()
	utils.sort_by_column(task_list, "urgency")
	utils.sort_by_column(other_tasks, "urgency")
	local columnsWidth = get_columns_width(task_list, other_tasks)

	for _, task in ipairs(task_list) do
		table.insert(lines, parse_line(task, columnsWidth))
	end

	if #other_tasks > 0 and M.project and #task_list > 0 then
		table.insert(lines, "--+--")
	end

	for _, task in ipairs(other_tasks) do
		table.insert(lines, parse_line(task, columnsWidth))
	end
	return lines
end

function M.setup(user_config)
	utils.log_message("dashboard.M.setup", "Setting up Dashboard")
	M.config = vim.tbl_deep_extend("force", M.config, user_config or {})
	M.project = get_project()
end

return M

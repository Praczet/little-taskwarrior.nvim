local M = {}
M.debug = true
M.get_dashboard_config = nil
--
-- Function to read file contents
function M.read_file(path)
	local file = io.open(path, "r")
	if not file then
		return nil
	end
	local content = file:read("*a")
	file:close()
	return content
end

-- Function to check if the Dashboard buffer is open
function M.is_dashboard_open()
	-- Get the current buffer name
	local bufname = vim.api.nvim_buf_get_name(0)

	-- Get the current buffer filetype
	local buftype = vim.bo.filetype

	-- Check if the buffer name contains 'dashboard' or filetype is 'dashboard'
	if string.match(bufname, "dashboard") or buftype == "dashboard" then
		return true
	end

	return false
end

function M.refresh_dashboard()
	if M.is_dashboard_open() and M.get_dashboard_config and type(M.get_dashboard_config) == "function" then
		local bufnr = vim.api.nvim_get_current_buf()
		vim.api.nvim_buf_delete(bufnr, { force = true })
		local _dashboard = require("dashboard")
		_dashboard.setup(M.get_dashboard_config())
		_dashboard:instance()
	end
end

function M.merge_arrays(a, b)
	local result = {}
	table.move(a, 1, #a, 1, result)
	table.move(b, 1, #b, #a + 1, result)
	return result
end

function M.log_message(module_name, message)
	if not M.debug then
		return
	end
	local log_file = vim.fn.expand("~/.config/nvim/nvim-little-taskwarrior.log")
	local log_entry = os.date("%Y-%m-%d %H:%M:%S") .. "\t" .. module_name .. "\t" .. message .. "\n"
	local file = io.open(log_file, "a")
	if file then
		file:write(log_entry)
		file:close()
	end
end

--- Escapes special characters in a pattern
local function escape_pattern(text)
	return text:gsub("([^%w])", "%%%1")
end

function M.replace_project_name(project_name, config)
	if config and config.project_replacements then
		for pattern, replacement in pairs(config.project_replacements) do
			project_name = project_name:gsub(pattern, replacement)
		end
	end

	if config and config.shorten_sections then
		local sep = config.sec_sep
		local escaped_sep = escape_pattern(sep)
		local pattern = "[^" .. escaped_sep .. "]+"
		local parts = {}
		for part in project_name:gmatch(pattern) do
			table.insert(parts, part)
		end
		for i = 1, #parts - 1 do
			parts[i] = parts[i]:sub(1, 1)
		end
		project_name = table.concat(parts, sep)
	end
	return project_name
end

function M.utf8len(str)
	local len = 0
	for _ in string.gmatch(str, "[%z\1-\127\194-\244][\128-\191]*") do
		len = len + 1
	end
	return len
end

--- Slices a table from start index to end index
---@param tbl table The input table
---@param start_index number The starting index
---@param end_index number The ending index
---@return table result The sliced portion of the table
function M.slice(tbl, start_index, end_index)
	local result = {}
	for i = start_index, end_index do
		table.insert(result, tbl[i])
	end
	return result
end
local function trim(s)
	return (s:gsub("^%s*(.-)%s*$", "%1"))
end
function M.in_table(lines_table, target_line)
	target_line = trim(target_line)
	for _, line in ipairs(lines_table) do
		if line == target_line then
			return true
		end
	end
	return false
end
function M.parse_datetime(datetime_str)
	-- Extract components using pattern matching
	local year, month, day, hour, min, sec = datetime_str:match("(%d%d%d%d)(%d%d)(%d%d)T(%d%d)(%d%d)(%d%d)Z")
	if not year then
		return nil, "Invalid date-time format"
	end

	-- Create a table with the extracted components
	local datetime_table = {
		year = tonumber(year),
		month = tonumber(month),
		day = tonumber(day),
		hour = tonumber(hour),
		min = tonumber(min),
		sec = tonumber(sec),
	}

	-- Convert the table to a timestamp
	local timestamp = os.time(datetime_table)
	return timestamp
end

function M.align_right(text, max_length)
	local text_length = M.utf8len(text)
	if text_length < max_length then
		return string.rep(" ", max_length - text_length) .. text
	else
		return text
	end
end

function M.align_left(text, max_length)
	local text_length = M.utf8len(text)
	if text_length < max_length then
		return text .. string.rep(" ", max_length - text_length)
	else
		return text
	end
end

function M.align_center(text, width)
	local text_length = M.utf8len(text)
	if text_length >= width then
		return text
	end
	local padding = (width - text_length) / 2
	local left_padding = math.floor(padding)
	local right_padding = math.ceil(padding)
	return string.rep(" ", left_padding) .. text .. string.rep(" ", right_padding)
end

function M.get_os_date(datetime_str, format_str)
	M.log_message("utils.M.get_os_date", "datetime_str: " .. datetime_str)
	if not format_str then
		format_str = "%Y-%m-%d %H:%M:%S"
	end
	M.log_message("utils.M.get_os_date", "format_str: " .. format_str)
	return os.date(format_str, M.parse_datetime(datetime_str))
end

function M.sort_by_column(tasks, column, order)
	order = order or "desc"
	table.sort(tasks, function(a, b)
		if order == "desc" then
			return a[column] > b[column]
		else
			return a[column] < b[column]
		end
	end)
end

return M

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

function M.replace_project_name(project_name, project_replacements)
	for pattern, replacement in pairs(project_replacements) do
		project_name = project_name:gsub(pattern, replacement)
	end
	return project_name
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

function M.get_os_date(datetime_str, format_str)
	if not format_str then
		format_str = "%Y-%m-%d %H:%M:%S"
	end
	return os.date(format_str, M.parse_datetime(datetime_str))
end

function M.sort_by_column(tasks, column, order)
	if order == nil then
		order = "desc"
	end
	table.sort(tasks, function(a, b)
		if order == "desc" then
			return a[column] > b[column]
		else
			return a[column] < b[column]
		end
	end)
end

return M

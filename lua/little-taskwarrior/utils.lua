local M = {}
M.debug = true

function M.log_message(module_name, message)
	if not M.debug then
		return
	end
	local log_file = vim.fn.expand("~/.config/nvim/little-taskwarrior.log")
	local log_entry = os.date("%Y-%m-%d %H:%M:%S") .. "\t" .. module_name .. "\t" .. message .. "\n"
	local file = io.open(log_file, "a")
	if file then
		file:write(log_entry)
		file:close()
	end
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

return M

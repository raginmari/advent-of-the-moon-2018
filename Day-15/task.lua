package.path = "?.lua;../?.lua"
local input = require "input"
local utils = require "utils"

local BYTE_ELF = 69
local BYTE_GOBLIN = 71
local BYTE_WALL = 35
local WALL = -1
local CLEAR = 0
local ELF = "elf"
local GOBLIN = "goblin"

function visualize(board, units)
	local str = ""
	for i, v in ipairs(board.grid) do
		if v == CLEAR then
			str = str .. "."
		elseif v == WALL then
			str = str .. "#"
		else
			local find_with_id = function(a) return a.id == v end
			local unit = utils.array_first_where(units, find_with_id)
			if unit.kind == GOBLIN then
				str = str .. "G"
			else
				str = str .. "E"
			end
		end

		if str:len() % board.width == 0 then 
			print(str)
			str = "" -- Next line
		end
	end
end

function append_goblin(units, x, y)
	local id = 1 + #units
	local unit = { id = id, kind = GOBLIN, x = x, y = y, killed = false, hp = 200 }
	units[#units + 1] = unit
end

function append_elf(units, x, y)
	local id = 1 + #units
	local unit = { id = id, kind = ELF, x = x, y = y, killed = false, hp = 200 }
	units[#units + 1] = unit
end

function index(x, y, width)
	return 1 + x + y * width
end

function xy(index, width)
	local index = index - 1
	local y = math.floor(index / width)
	local x = index - y * width
	return x, y
end

function parse_line(line, y, board, units)
	for i = 1, line:len() do
		local x = i - 1
		local index = index(x, y, board.width)

		local byt = line:byte(i)
		if byt == BYTE_GOBLIN then
			append_goblin(units, x, y)
			board.grid[index] = units[#units].id
		elseif byt == BYTE_ELF then
			append_elf(units, x, y)
			board.grid[index] = units[#units].id
		elseif byt == BYTE_WALL then
			board.grid[index] = WALL
		else
			board.grid[index] = CLEAR
		end
	end
end

function parse(lines)
	local w = lines[1]:len()
	local h = #lines
	local board = { grid = {}, width = w, height = h }
	local units = {}
	for i = 1, #lines do
		local y = i - 1
		parse_line(lines[i], y, board, units)
	end
	return board, units
end

function tick(board, units)
	
end

function solve(input)

	local t0 = os.clock()

	local trim = function(a) return utils.string_trim(a) end
	local lines = utils.array_map(input, trim)

	local board, units = parse(lines)
	visualize(board, units)

	local time = os.clock() - t0
	print(string.format("Elapsed time: %.4f", time))

	return result
end

local filename = arg[1] or "input.txt"
local input = input.read_file(filename)
print("Solution: " .. (solve(input) or "not found"))

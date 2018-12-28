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

local abs = math.abs

-- up, left, right, down = reading order
local deltas = { 0, -1, -1, 0, 1, 0, 0, 1 }

-- down, right, left, up = inverse reading order
local deltas_inv = { 0, 1, 1, 0, -1, 0, 0, -1 }

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

function index(x, y, width)
	return 1 + x + y * width
end

function xy(index, width)
	local index = index - 1
	local y = math.floor(index / width)
	local x = index - y * width
	return x, y
end

function make_goblin(x, y)
	return { id = nil, kind = GOBLIN, x = x, y = y, killed = false, hp = 200 }
end

function make_elf(x, y)
	return { id = nil, kind = ELF, x = x, y = y, killed = false, hp = 200 }
end

function next_unit_id(units)
	return "" .. #units
end

function add_unit(unit, units)
	local unit_id = next_unit_id(units)
	unit.id = unit_id
	units[#units + 1] = unit
	units[unit_id] = unit
	return unit_id
end

function parse_line(line, y, board, units)
	for i = 1, line:len() do
		local x = i - 1
		local index = index(x, y, board.width)

		local byt = line:byte(i)
		if byt == BYTE_GOBLIN then
			local unit = make_goblin(x, y)
			board.grid[index] = add_unit(unit, units)
		elseif byt == BYTE_ELF then
			local unit = make_elf(x, y)
			board.grid[index] = add_unit(unit, units)
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

function sort_by_reading_order(a, b)
	if a.y < b.y then return true end
	if a.y == b.y then return a.x < b.x end
end

function find_targets_of(unit, units)
	local kind
	if unit.kind == GOBLIN then kind = ELF else kind = GOBLIN end
	return utils.array_filter(units, function(a) return a.kind == kind end)
end

function find_squares_next_to(positions, board)
	local squares = {}
	local deltas = deltas
	for _, target in ipairs(positions) do
		for i = 1, #deltas, 2 do
			local index = index(target.x + deltas[i], target.y + deltas[i + 1], board.width)
			if board.grid[index] == CLEAR then squares[#squares + 1] = index end
		end
	end
	return squares
end

function attack(x, y, targets, board)
	for _, target in ipairs(targets) do
		for i = 1, #deltas_inv, 2 do
			if target.x == x + deltas_inv[i] and target.y == y + deltas_inv[i + 1] then
				target.hp = target.hp - 3
				if target.hp <= 0 then target.killed = true end
				return true
			end
		end
	end
end

function make_path_node(index, ancestor, depth)
	return { index = index, ancestor = ancestor, depth = depth }
end

function path(src_index, dst_index, board)
	-- Invert source and destination to avoid reversing of path array below
	local src, dst = dst_index, src_index
	print(string.format("computing path from %d to %d", dst, src))

	local queue = { make_path_node(src, nil, 0) }
	-- Algorithm increments head index instead of removing elements at the head of the array
	local queue_head_index = 1
	local visited = { src = 1 }

	while queue_head_index <= #queue do
		local node = queue[queue_head_index]
		queue_head_index = queue_head_index + 1
		
		if node.index == dst then 
			local path = {}
			local n = node
			while n ~= nil do
				path[#path + 1] = n.index
				n = n.ancestor
			end
			utils.array_print(path)
			return path
		end
		
		local x, y = xy(node.index, board.width)

		for i = 1, #deltas, 2 do
			local neighbor_index = index(x + deltas[i], y + deltas[i + 1], board.width)
			if visited[neighbor_index] == nil and (board.grid[neighbor_index] == CLEAR or neighbor_index == dst) then
				queue[#queue + 1] = make_path_node(neighbor_index, node, node.depth + 1)
				visited[neighbor_index] = 1
			end
		end
	end

	print("unreachable!")
end

function move(x, y, dst_indexes, board, units)
	local current_index = index(x, y, board.width)
	local shortest_paths = {}
	for _, dst_index in ipairs(dst_indexes) do
		local path = path(current_index, dst_index, board)
		if path then
			if #shortest_paths == 0 or #path == #shortest_paths[1] then 
				shortest_paths[#shortest_paths + 1] = path
			elseif #path < #shortest_paths[1] then
				shortest_paths = { path }
			end
		end
	end

	if #shortest_paths == 0 then return end -- No target is reachable

	if #shortest_paths > 1 then
		-- Sort shortest paths in reading order
		table.sort(shortest_paths, function(a, b) return a[#a] < b[#b] end)
	end

	local path = shortest_paths[1]
	local next_index = path[2]

	-- Update board
	local unit_id = board.grid[current_index]
	board.grid[current_index], board.grid[next_index] = CLEAR, unit_id

	-- Update unit
	local unit = units[unit_id]
	unit.x, unit.y = xy(next_index, board.width)
end

function tick(board, units)
	table.sort(units, sort_by_reading_order)
	for _, unit in ipairs(units) do
		local targets = find_targets_of(unit, units)
		if #targets == 0 then return true end -- End of combat!

		local x, y = unit.x, unit.y
		if not attack(x, y, targets, board, units) then
			local target_squares = find_squares_next_to(targets, board)
			if #target_squares > 0 then
				move(x, y, target_squares, board, units)
				attack(x, y, targets, board, units)
			end
		end

		for _, target in ipairs(targets) do
			if target.killed then
				print(string.format("%s %s died", target.kind, target.id))
				utils.array_remove_where(units, function(a) return a.id == target.id end)
				board.grid[index(target.x, target.y, board.width)] = CLEAR
			end
		end
	end
end

function solve(input)

	local t0 = os.clock()

	local trim = function(a) return utils.string_trim(a) end
	local lines = utils.array_map(input, trim)

	local board, units = parse(lines)
	visualize(board, units)

	local rounds = 0
	while true do
		if tick(board, units) then break end
		visualize(board, units)
		rounds = rounds + 1
	end

	local sum = 0
	for _, unit in ipairs(units) do sum = sum + unit.hp end
	local result = (rounds - 1) * sum

	local time = os.clock() - t0
	print(string.format("Elapsed time: %.4f", time))

	return result
end

local filename = arg[1] or "input.txt"
local input = input.read_file(filename)
print("Solution: " .. (solve(input) or "not found"))

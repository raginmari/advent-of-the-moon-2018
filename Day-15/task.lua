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

function initial(kind)
	if kind == ELF then return "E" else return "G" end
end

function enemy_initial(kind)
	if kind == ELF then return "G" else return "E" end
end

function visualize(board, units, headline)
	print(headline)
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

	-- for _, unit in ipairs(units) do
	-- 	if not unit.dead then
	-- 		print(string.format("%s at %d,%d is %d", initial(unit.kind), unit.x, unit.y, unit.hp))
	-- 	end
	-- end	

	print()
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
	-- "dead"		the unit is dead.
	-- "killed"		the unit has been killed this turn. At the end of the tick, the flag is reset to false and "dead" is set true.
	return { id = nil, kind = GOBLIN, x = x, y = y, killed = false, dead = false, hp = 200 }
end

function make_elf(x, y)
	return { id = nil, kind = ELF, x = x, y = y, killed = false, dead = false, hp = 200 }
end

function next_unit_id(units)
	return "" .. #units
end

function add_unit(unit, units)
	local unit_id = next_unit_id(units)
	unit.id = unit_id
	units[#units + 1] = unit
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
	return utils.array_filter(units, function(a) return not a.dead and a.kind == kind end)
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

function filter_adjacent_to(x, y)
	return function(a)
		local abs_x = abs(x - a.x)
		local abs_y = abs(y - a.y)
		return abs_x == 1 and abs_y == 0 or abs_x == 0 and abs_y == 1 
	end
end

function attack(x, y, targets, board)

	local filter = filter_adjacent_to(x, y)
	local adjacent_targets = utils.array_filter(targets, filter)
	
	if #adjacent_targets == 0 then return end -- No target in range

	local weakest_targets = {}
	for _, t in ipairs(adjacent_targets) do
		if #weakest_targets == 0 or t.hp == weakest_targets[1].hp then
			weakest_targets[#weakest_targets + 1] = t
		elseif t.hp < weakest_targets[1].hp then
			weakest_targets = { t }
		end
	end

	table.sort(weakest_targets, sort_by_reading_order)

	local target = weakest_targets[1]
	-- print(string.format("%s at %d,%d attacks %s at %d,%d", enemy_initial(target.kind), x, y, initial(target.kind), target.x, target.y))
	target.hp = target.hp - 3
	if target.hp <= 0 then 
		target.killed = true 
	end

	return true
end

function make_path_node(index, ancestor, depth)
	return { index = index, ancestor = ancestor }
end

function path(src_index, dst_index, board)
	-- Invert source and destination to avoid reversing of path array below
	local src_index, dst_index = dst_index, src_index
	
	local queue = { make_path_node(src_index, nil) }
	-- Algorithm increments head index instead of removing elements at the head of the array
	local queue_head_index = 1
	local visited = { src_index = 1 }

	while queue_head_index <= #queue do
		local node = queue[queue_head_index]
		queue_head_index = queue_head_index + 1
		
		if node.index == dst_index then 
			local path = {}
			local n = node
			while n ~= nil do -- Walks back along the path
				path[#path + 1] = n.index
				n = n.ancestor
			end
			return path
		end
		
		local x, y = xy(node.index, board.width)

		for i = 1, #deltas, 2 do
			local neighbor_index = index(x + deltas[i], y + deltas[i + 1], board.width)
			if visited[neighbor_index] == nil and (board.grid[neighbor_index] == CLEAR or neighbor_index == dst_index) then
				queue[#queue + 1] = make_path_node(neighbor_index, node)
				visited[neighbor_index] = 1
			end
		end
	end
end

function move(x, y, targets, board, units)
	
	local dst_indexes = find_squares_next_to(targets, board)

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

	if #shortest_paths == 0 then 
		-- No target is reachable
		return
	elseif #shortest_paths > 1 then
		-- Sort shortest paths in reading order
		table.sort(shortest_paths, function(a, b) return a[#a] < b[#b] end)
	end

	local path = shortest_paths[1]
	local next_index = path[2]

	-- Update board
	local unit_id = board.grid[current_index]
	board.grid[current_index], board.grid[next_index] = CLEAR, unit_id

	-- Update unit
	local unit = utils.array_first_where(units, function(a) return a.id == unit_id end)
	unit.x, unit.y = xy(next_index, board.width)
end

function tick(board, units)
	table.sort(units, sort_by_reading_order)
	local units = utils.array_filter(units, function(a) return not a.dead end)

	for _, unit in ipairs(units) do
		if not unit.dead then
			local targets = find_targets_of(unit, units)
			if #targets == 0 then return true end -- End of combat!

			if not attack(unit.x, unit.y, targets, board, units) then
				move(unit.x, unit.y, targets, board, units)
				attack(unit.x, unit.y, targets, board, units)
			end

			for _, target in ipairs(targets) do
				if target.killed then
					target.dead = true
					target.killed = false
					-- print(string.format("%s at %d,%d died", initial(target.kind), target.x, target.y))
					board.grid[index(target.x, target.y, board.width)] = CLEAR
				end
			end
		end
	end
end

function solve(input)

	local t0 = os.clock()

	local trim = function(a) return utils.string_trim(a) end
	local lines = utils.array_map(input, trim)

	local board, units = parse(lines)
	visualize(board, units, "Initial state")

	local rounds = 0
	while true do
		if tick(board, units) then 
			visualize(board, units, string.format("End of combat in round %d", rounds + 1))
			break
		end
		rounds = rounds + 1
		visualize(board, units, string.format("After round %d", rounds))
	end

	local sum = 0
	for _, unit in ipairs(units) do 
		if not unit.dead then
			sum = sum + unit.hp
		end
	end
	local result = rounds * sum
	print("full rounds: " .. rounds .. ", total remaining hp: " .. sum)

	local time = os.clock() - t0
	print(string.format("Elapsed time: %.4f", time))

	return result
end

local filename = arg[1] or "input.txt"
local input = input.read_file(filename)
print("Solution: " .. (solve(input) or "not found"))

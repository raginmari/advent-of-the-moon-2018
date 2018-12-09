package.path = "?.lua;../?.lua"
local input = require "input"
local utils = require "utils"

function parse(str)
	local t = {}
	for i in string.gmatch(str, "%S+") do utils.array_append(t, i) end
	return t
end

function marble_make(value)
	return { value = value, cw = nil, ccw = nil }
end

function marble_set_next(m, marble)
	m.cw = marble
end

function marble_set_prev(m, marble)
	m.ccw = marble
end

function insert_marble_between(marble, prev_marble, next_marble)
	marble_set_next(prev_marble, marble)
	marble_set_prev(marble, prev_marble)
	marble_set_next(marble, next_marble)
	marble_set_prev(next_marble, marble)
end

function remove_marble(marble)
	marble_set_prev(marble.cw, marble.ccw)
	marble_set_next(marble.ccw, marble.cw)
	marble_set_next(marble, nil)
	marble_set_prev(marble, nil)
end

function add_score(scores, player, points)
	scores[player] = (scores[player] or 0) + points
end

function solve(num_players, num_marbles)

	local t0 = os.clock()

	local marble = marble_make(0)
	marble_set_next(marble, marble)
	marble_set_prev(marble, marble)
	local current_marble = marble
	local current_player = 1
	local scores = {}

	for i = 1, num_marbles - 1 do
		if i % 23 == 0 then
			-- The marble seven marbles counter clockwise of the current is removed
			local removed_marble = current_marble
			for i = 1, 7 do removed_marble = removed_marble.ccw end
			current_marble = removed_marble.cw
			remove_marble(removed_marble)
			-- Add points
			add_score(scores, current_player, i + removed_marble.value)
		else
			local marble = marble_make(i)
			local one_cw = current_marble.cw
			insert_marble_between(marble, one_cw, one_cw.cw)
			current_marble = marble
		end

		current_player = (current_player + 1) % num_players
	end

	local max = 0
	for _, score in pairs(scores) do
		if score > max then max = score end
	end

	local time = os.clock() - t0
	print(string.format("Elapsed time: %.4f", time))

	return max
end

-- print("Solution: " .. (solve(9, 26) or "not found"))
print("Solution: " .. (solve(446, 71522) or "not found"))
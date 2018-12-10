package.path = "?.lua;../?.lua"
local input = require "input"
local utils = require "utils"

function parse(str)
	local x, y, dx, dy = str:match("position=<%s?(-?%d+),%s*(-?%d+)> velocity=<%s?(-?%d+),%s*(-?%d+)>")
	x, y, dx, dy = tonumber(x), tonumber(y), tonumber(dx), tonumber(dy)
	return { x = x, y = y, dx = dx, dy = dy }
end

function advance_one_second(stars, by)
	local by = by or 1
	for _, star in ipairs(stars) do
		star.x = star.x + star.dx * by
		star.y = star.y + star.dy * by
	end
end

function bounding_box(stars)
	local min_x = nil
	local max_x = nil
	local min_y = nil
	local max_y = nil
	for _, star in ipairs(stars) do
		if not max_x or star.x > max_x then max_x = star.x end
		if not max_y or star.y > max_y then max_y = star.y end
		if not min_x or star.x < min_x then min_x = star.x end
		if not min_y or star.y < min_y then min_y = star.y end
	end
	return { x = min_x, y = min_y, w = max_x - min_x, h = max_y - min_y }
end

function star_index(star, bb)
	return star.y * bb.w + star.x
end

function print_stars(stars, bb)
	local x0 = bb.x
	local y0 = bb.y
	table.sort(stars, function(a, b) return star_index(a, bb) < star_index(b, bb) end)
	local line
	for y = y0, y0 + bb.h do
		line = ""
		local line_stars = utils.array_filter(stars, function(a) return a.y == y end)
		if #line_stars > 0 then
			local cursor_x = x0
			for _, s in ipairs(line_stars) do
				if s.x >= cursor_x then
					local dots = s.x - cursor_x
					for i = 1, dots do line = line .. "." end
					line = line .. "#"
					cursor_x = s.x + 1
				end
			end
		end
		print(line)
	end
end

function solve(input)

	local t0 = os.clock()

	local stars = {}
	for _, str in ipairs(input) do
		stars[#stars + 1] = parse(str)
	end

	local last_bb = { x = 0, y = 0, w = 1000000, h = 1000000 }
	while true do
		local bb = bounding_box(stars)
		if bb.w * bb.h > last_bb.w * last_bb.h then 
			advance_one_second(stars, -1)
			print_stars(stars, last_bb)
			break
		end
		last_bb = bb
		advance_one_second(stars)
	end

	local time = os.clock() - t0
	print(string.format("Elapsed time: %.4f", time))

	return nil
end

local input = input.read_file("input.txt")
print("Solution: " .. (solve(input) or "not found"))

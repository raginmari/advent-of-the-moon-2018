package.path = "?.lua;../?.lua"
local input = require "input"

function parse_claim(str)
	-- Example: #1 @ 1,3: 4x4
	local a, b, c, d, e = str:match('#(%d+) @ (%d+),(%d+): (%d+)x(%d+)')
	return { id = tonumber(a), x = tonumber(b), y = tonumber(c), width = tonumber(d), height = tonumber(e) }
end

function claims_intersect(a, b)
	if a.x >= b.x + b.width then return end
	if b.x >= a.x + a.width then return end
	if a.y >= b.y + b.height then return end
	if b.y >= a.y + a.height then return end
	return true
end

function solve(input)
	-- Parse the claims
	local claims = {}
	for i = 1, #input do 
		claims[#claims + 1] = parse_claim(input[i])
	end

	-- #1 @ 1,3: 4x4
	-- #2 @ 3,1: 4x4
	-- #3 @ 5,5: 2x2
	-- claims = { {id = 1, x = 1, y = 3, width = 4, height = 4}, {id = 2, x = 3, y = 1, width = 4, height = 4}, {id = 3, x = 5, y = 5, width = 2, height = 2} }

	local t0 = os.clock()

	for i = 1, #claims do
		for j = 1, #claims do
			if i ~= j and claims_intersect(claims[i], claims[j]) then
				claims[i].intersects = true
				claims[j].intersects = true
				break
			end
		end
	end

	local time = os.clock() - t0
	print(string.format("elapsed time: %.4f", time))

	for i = 1, #claims do
		if not claims[i].intersects then return claims[i].id end
	end
end

local input = input.read_file("input.txt")
print("Solution: " .. (solve(input) or "not found"))
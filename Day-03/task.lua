package.path = "?.lua;../?.lua"
local input = require "input"

function parse_claim(str)
	-- Example: #1 @ 1,3: 4x4
	local a, b, c, d, e = str:match('#(%d+) @ (%d+),(%d+): (%d+)x(%d+)')
	return { id = a, x = b, y = c, width = d, height = e }
end

function add_coverage(claim, coverage)
	local count = 0
	-- Compute index of top left corner of the claim
	local ix = claim.x + claim.y * 1000

	for j = 0, claim.height - 1 do
		for i = 0, claim.width - 1 do
			-- Increment coverage by 1
			local incremented = (coverage[ix] or 0) + 1
			coverage[ix] = incremented
			-- Count coverage that exceeds 1
			if incremented == 2 then count = count + 1 end
			ix = ix + 1
		end
		-- Next line and "carriage return"
		ix = ix + 1000 - claim.width
	end

	return count
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
	-- claims = { {x = 1, y = 3, width = 4, height = 4}, {x = 3, y = 1, width = 4, height = 4}, {x = 5, y = 5, width = 2, height = 2} }

	local t0 = os.clock()

	local count = 0
	local coverage = {}
	for i = 1, #claims do
		local claim = claims[i]
		count = count + add_coverage(claim, coverage)
	end

	local time = os.clock() - t0
	print(string.format("elapsed time: %.4f", time))

	return count
end

local input = input.read_file("input.txt")
print("Solution: " .. (solve(input) or "not found"))
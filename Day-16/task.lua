package.path = "?.lua;../?.lua"
local input = require "input"
local utils = require "utils"

function registers(a, b, c, d)
	return { a, b, c, d }
end

function instruction(num, in1, in2, out)
	return { number = num, inputs = { in1, in2 }, output = out }
end

function sample(instruction, before, after)
	return { instruction = instruction, before = before, after = after }
end

function parse_registers(line)
	local a, b, c, d = line:match("(%d+)[^%d]*(%d+)[^%d]*(%d+)[^%d]*(%d+)")
	if not a or not b or not c or not d then return nil end
	return registers(tonumber(a), tonumber(b), tonumber(c), tonumber(d))
end

function parse_instruction(line)
	local a, b, c, d = line:match("(%d+) (%d+) (%d+) (%d+)")
	if not a or not b or not c or not d then return nil end
	return instruction(tonumber(a), tonumber(b), tonumber(c), tonumber(d))
end

function parse_samples(lines)
	local samples = {}
	local state = 0
	local before, instruction
	for _, line in ipairs(lines) do
		if state == 0 then
			before = parse_registers(line)
			if not before then break end
			state = 1
		elseif state == 1 then
			instruction = parse_instruction(line)
			if not instruction then os.exit() end
			state = 2
		elseif state == 2 then
			local after = parse_registers(line)
			if not after then os.exit() end
			
			samples[#samples + 1] = sample(instruction, before, after)
			before, instruction = nil, nil

			state = 0
		end
	end
end

function solve(input)

	local t0 = os.clock()

	local lines = utils.array_filter(input, function(a) return a:len() > 0 end)
	local samples = parse_samples(lines)

	local time = os.clock() - t0
	print(string.format("Elapsed time: %.4f", time))

	return result
end

local filename = arg[1] or "input.txt"
local input = input.read_file(filename)
print("Solution: " .. (solve(input) or "not found"))

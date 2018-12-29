package.path = "?.lua;../?.lua"
local input = require "input"
local utils = require "utils"

function registers(a, b, c, d)
	return { a, b, c, d }
end

function instruction(num, in1, in2, out)
	return { number = num, inputA = in1, inputAr = in1 + 1, inputB = in2, inputBr = in2 + 1, output = out + 1 }
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

	return samples
end

function addr(registers, instruction)
	registers[instruction.output] = registers[instruction.inputAr] + registers[instruction.inputBr]
end

function addi(registers, instruction)
	registers[instruction.output] = registers[instruction.inputAr] + instruction.inputB
end

function mulr(registers, instruction)
	registers[instruction.output] = registers[instruction.inputAr] * registers[instruction.inputBr]
end

function muli(registers, instruction)
	registers[instruction.output] = registers[instruction.inputAr] * instruction.inputB
end

function banr(registers, instruction)
	registers[instruction.output] = bit32.band(registers[instruction.inputAr], registers[instruction.inputBr])
end

function bani(registers, instruction)
	registers[instruction.output] = bit32.band(registers[instruction.inputAr], instruction.inputB)
end

function borr(registers, instruction)
	registers[instruction.output] = bit32.bor(registers[instruction.inputAr], registers[instruction.inputBr])
end

function bori(registers, instruction)
	registers[instruction.output] = bit32.bor(registers[instruction.inputAr], instruction.inputB)
end

function setr(registers, instruction)
	registers[instruction.output] = registers[instruction.inputAr]
end

function seti(registers, instruction)
	registers[instruction.output] = instruction.inputA
end

function gtir(registers, instruction)
	if instruction.inputA > registers[instruction.inputBr] then
		registers[instruction.output] = 1
	else 
		registers[instruction.output] = 0
	end
end

function gtri(registers, instruction)
	if registers[instruction.inputAr] > instruction.inputB then
		registers[instruction.output] = 1
	else 
		registers[instruction.output] = 0
	end
end

function gtrr(registers, instruction)
	if registers[instruction.inputAr] > registers[instruction.inputBr] then
		registers[instruction.output] = 1
	else 
		registers[instruction.output] = 0
	end
end

function eqir(registers, instruction)
	if instruction.inputA == registers[instruction.inputBr] then
		registers[instruction.output] = 1
	else 
		registers[instruction.output] = 0
	end
end

function eqri(registers, instruction)
	if registers[instruction.inputAr] == instruction.inputB then
		registers[instruction.output] = 1
	else 
		registers[instruction.output] = 0
	end
end

function eqrr(registers, instruction)
	if registers[instruction.inputAr] == registers[instruction.inputBr] then
		registers[instruction.output] = 1
	else 
		registers[instruction.output] = 0
	end
end

function is_equal(registers1, registers2)
	for i = 1, #registers1 do
		if registers1[i] ~= registers2[i] then return false end
	end
	return true
end

function solve(input)

	local t0 = os.clock()

	local lines = utils.array_filter(input, function(a) return a:len() > 0 end)
	local samples = parse_samples(lines)
	print(string.format("Parsed %d samples", #samples))

	local functions = { addr, addi, mulr, muli, banr, bani, borr, bori, setr, seti, gtir, gtri, gtrr, eqir, eqri, eqrr }
	local registers = { 0, 0, 0, 0 }
	local result = 0
	for _, sample in ipairs(samples) do
		local n = 0
		for _, f in ipairs(functions) do
			utils.array_copy(sample.before, registers)
			f(registers, sample.instruction)
			if is_equal(registers, sample.after) then n = n + 1 end
		end
		if n >= 3 then 
			result = result + 1 
		end
	end
	
	local time = os.clock() - t0
	print(string.format("Elapsed time: %.4f", time))

	return result
end

local filename = arg[1] or "input-samples.txt"
local input = input.read_file(filename)
print("Solution: " .. (solve(input) or "not found"))

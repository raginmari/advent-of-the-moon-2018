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
	local a, b, c, d = line:match("(%d+), (%d+), (%d+), (%d+)")
	if not a or not b or not c or not d then return nil end
	return registers(tonumber(a), tonumber(b), tonumber(c), tonumber(d))
end

function parse_instruction(line)
	local a, b, c, d = line:match("(%d+) (%d+) (%d+) (%d+)")
	if not a or not b or not c or not d then return nil end
	return instruction(tonumber(a), tonumber(b), tonumber(c), tonumber(d))
end

function parse_input(lines)
	local samples = {}
	local program = {}
	local state = 0
	local before, instruction
	local consecutive_empty_lines = 0
	for _, line in ipairs(lines) do
		if state == 0 then
			if line:len() == 0 then
				consecutive_empty_lines = consecutive_empty_lines + 1
				if consecutive_empty_lines == 3 then state = 4 end -- Samples and instructions are separated by 3 empty lines
			else
				consecutive_empty_lines = 0
				before = parse_registers(line)	
				state = 1
			end
		elseif state == 1 then
			consecutive_empty_lines = 0
			instruction = parse_instruction(line)
			state = 2
		elseif state == 2 then
			consecutive_empty_lines = 0
			local after = parse_registers(line)
			state = 0

			-- Append next sample
			samples[#samples + 1] = sample(instruction, before, after)
			before, instruction = nil, nil

		elseif state == 4 then
			consecutive_empty_lines = 0
			local instruction = parse_instruction(line)

			-- Append next program instruction
			program[#program + 1] = instruction
		end
	end

	return samples, program
end

function parse_program(iter)
	local program = {}
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

function intersection(a, b)
	local t = {}
	local i = 1
	local j = 1
	while i <= #a and j <= #b do
		if a[i] < b[j] then 
			i = i + 1 
		elseif b[j] < a[i] then
			j = j + 1
		else
			t[#t + 1] = a[i]
			i = i + 1
		end
	end
	return t
end

function find_candidates(samples, functions)
	local registers = { 0, 0, 0, 0 }
	local candidates = {}
	
	for _, sample in ipairs(samples) do
		local function_indexes = {}
		for i, f in ipairs(functions) do
			utils.array_copy(sample.before, registers)
			f(registers, sample.instruction)
			if is_equal(registers, sample.after) then 
				function_indexes[#function_indexes + 1] = i
			end
		end

		local opcode = sample.instruction.number
		if #function_indexes == 1 or not candidates[opcode] then
			candidates[opcode] = utils.array_copy(function_indexes)
		else
			candidates[opcode] = intersection(candidates[opcode], function_indexes)
		end
	end

	return candidates
end

function resolve_opcodes(samples, functions)
	
	local candidates = find_candidates(samples, functions)

	local unresolved = {}
	for opcode, candidates in pairs(candidates) do
		unresolved[#unresolved + 1] = { opcode = opcode, candidates = candidates }
	end

	local opcodes = {}
	while #unresolved > 0 do
		-- Sort by number of candidates in descending order
		table.sort(unresolved, function(a, b) return #a.candidates > #b.candidates end)
		
		-- Take the opcode with the fewest candidates
		local nxt = unresolved[#unresolved] 
		unresolved[#unresolved] = nil

		if #nxt.candidates > 1 then os.exit() end -- There must always be one with only 1 candidate

		local function_index = nxt.candidates[1]
		opcodes[nxt.opcode] = functions[function_index]

		for _, t in ipairs(unresolved) do
			utils.array_remove_where(t.candidates, function(a) return a == function_index end)
		end
	end

	return opcodes
end

function solve(input)

	local t0 = os.clock()

	local samples, program = parse_input(input)
	print(string.format("Parsed %d samples", #samples))
	print(string.format("Parsed %d program instructions", #program))

	local functions = { addr, addi, mulr, muli, banr, bani, borr, bori, setr, seti, gtir, gtri, gtrr, eqir, eqri, eqrr }
	local opcodes = resolve_opcodes(samples, functions)

	local registers = { 0, 0, 0, 0 }
	for _, instruction in ipairs(program) do
		local f = opcodes[instruction.number]
		f(registers, instruction)
	end

	local result = registers[1]

	local time = os.clock() - t0
	print(string.format("Elapsed time: %.4f", time))

	return result
end

local filename = arg[1] or "input.txt"
local input = input.read_file(filename)
print("Solution: " .. (solve(input) or "not found"))

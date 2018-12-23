package.path = "?.lua;../?.lua"
local input = require "input"
local utils = require "utils"

local U = "U"
local R = "R"
local D = "D"
local L = "L"
local SY = { U = {U}, D = {D} } -- straight y
local SX = { L = {L}, R = {R} }
local TL = { U = {L}, R = {D}, D = {R}, L = {U} } -- '\' turn left
local TR = { U = {R}, L = {D}, R = {U}, D = {L} } -- '/' turn right
local IS = { R = {U, R, D}, L = {D, L, U}, U = {L, U, R}, D = {R, D, L} } -- '+' intersection, ordered clockwise!

-- ASCII bytes:
local CART_UP = 94
local CART_DOWN = 118
local CART_LEFT = 60
local CART_RIGHT = 62
local TRACK_HORIZONTAL = 45
local TRACK_VERTICAL = 124
local TRACK_TURN_LEFT = 92 -- '\'
local TRACK_TURN_RIGHT = 47
local TRACK_INTERSECTION = 43

function address(x, y)
	return x .. "/" .. y
end

function parse(input)
	local carts = {}
	local tracks = {}

	for i = 1, #input do
		local line = input[i]
		local y = i - 1
		for j = 1, line:len() do
			local c = line:byte(j)
			local x = j - 1
			local xy = address(x, y)
			if c == CART_LEFT then
				carts[#carts + 1] = { id = #carts, x = x, y = y, dir = L, next_turn = 1 } -- next_turn: index in the possible directions at an intersection, in {1,2,3}
				tracks[xy] = SX
			elseif c == CART_RIGHT then
				carts[#carts + 1] = { id = #carts, x = x, y = y, dir = R, next_turn = 1 }
				tracks[xy] = SX
			elseif c == CART_UP then
				carts[#carts + 1] = { id = #carts, x = x, y = y, dir = U, next_turn = 1 }
				tracks[xy] = SY
			elseif c == CART_DOWN then
				carts[#carts + 1] = { id = #carts, x = x, y = y, dir = D, next_turn = 1 }
				tracks[xy] = SY
			elseif c == TRACK_HORIZONTAL then
				tracks[xy] = SX
			elseif c == TRACK_VERTICAL then
				tracks[xy] = SY
			elseif c == TRACK_TURN_LEFT then
				tracks[xy] = TL
			elseif c == TRACK_TURN_RIGHT then
				tracks[xy] = TR
			elseif c == TRACK_INTERSECTION then
				tracks[xy] = IS
			elseif c ~= 32 then
				print("found unknown character " .. string.char(c))
			end
		end
	end

	return carts, tracks
end

function dx(dir)
	if dir == R then return 1 end
	if dir == L then return -1 end
	return 0
end

function dy(dir)
	if dir == U then return -1 end
	if dir == D then return 1 end
	return 0
end

function move_cart(cart, tracks)
	local dir = cart.dir
	cart.x = cart.x + dx(dir)
	cart.y = cart.y + dy(dir)
	-- print(string.format("cart %s moves %s to %d,%d", cart.id, cart.dir, cart.x, cart.y))
	local xy = address(cart.x, cart.y)
	local directions = tracks[xy][cart.dir]
	if #directions == 1 then
		-- There is no choice of direction
		cart.dir = directions[1]
	else
		-- Choose the direction according to the rule: turn left, go straight, turn right, turn left etc.
		cart.dir = directions[cart.next_turn]
		cart.next_turn = 1 + cart.next_turn % 3 -- 1,2,3,1,2,3,1...
		-- print(string.format("cart %s turns %s", cart.id, cart.dir))
	end
end

function sort_carts(a, b)
	-- Sorts by increasing y and then by increasing x
	if a.y < b.y then return true end
	if a.y == b.y then return a.x < b.x end
	return false
end

local temp = {}
function has_collision(carts)
	for _, cart in ipairs(carts) do
		local xy = address(cart.x, cart.y)
		temp[xy] = (temp[xy] or 0) + 1
	end

	local collides = false
	for k, v in pairs(temp) do
		if v > 1 then collides = true end
		temp[k] = nil -- The table must be cleared after use
	end

	return collides
end

function tick(carts, tracks)
	table.sort(carts, sort_carts)
	for _, cart in ipairs(carts) do
		move_cart(cart, tracks)
		if has_collision(carts) then
			return { cart.x, cart.y }
		end
	end
end

function solve(input)

	local t0 = os.clock()

	local carts, tracks = parse(input)
	
	local first_crash
	while not first_crash do
		first_crash = tick(carts, tracks)
	end

	local result = table.concat(first_crash or { "not found" }, ",")

	local time = os.clock() - t0
	print(string.format("Elapsed time: %.4f", time))

	return result
end

local input = input.read_file("input.txt")
print("Solution: " .. (solve(input) or "not found"))

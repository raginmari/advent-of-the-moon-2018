package.path = "?.lua;../?.lua"
local input = require "input"

-- Event types
local START = 1; local SLEEP = 2; local WAKE = 3

function parse_event(str)
	local day, hour, minute = str:match("(%d+-%d+) (%d+):(%d+)")
	local event = { day = day, hour = hour, minute = minute }
	local id = str:match("#(%d+)")
	
	if id then 
		event.id = id
		event.type = START
	elseif string.match(str, "asleep") then
		event.type = SLEEP
	elseif string.match(str, "wakes") then
		event.type = WAKE
	end

	return event
end

function sortByTime(a, b)
	if a.day < b.day then return true end
	if a.day > b.day then return false end
	if a.hour < b.hour then return true end
	if a.hour > b.hour then return false end
	return a.minute < b.minute
end

function build_sleep_record(events)
	local sleep_record = {}
	local guard_id, start_minute
	for _, e in ipairs(events) do
		if e.type == START then 
			guard_id = e.id
		elseif e.type == SLEEP then 
			start_minute = e.minute
		elseif e.type == WAKE then
			local minutes_asleep = e.minute - start_minute
			local records = sleep_record[guard_id] or {}
			records[#records + 1] = { start = start_minute, duration = minutes_asleep }
			sleep_record[guard_id] = records
		end
	end

	return sleep_record
end

function find_sleepiest_guard(sleep_record)
	local max = 0
	local max_guard_id = nil
	for guard_id, records in pairs(sleep_record) do
		local total_minutes = 0
		for _, record in ipairs(records) do 
			total_minutes = total_minutes + record.duration 
		end

		if total_minutes > max then
			max_guard_id = guard_id
			max = total_minutes
		end
	end

	return max_guard_id
end

function build_timeline(guard_record)
	local timeline = {}
	for _, record in ipairs(guard_record) do
		local limit = record.start + record.duration - 1
		for i = record.start, limit do 
			timeline[i] = (timeline[i] or 0) + 1 
		end
	end

	return timeline
end

function find_sleepiest_minute(timeline)
	local current_best = nil
	local max = 0
	for i, minutes in ipairs(timeline) do
		if minutes > max then 
			max = minutes
			current_best = i 
		end
	end

	return current_best
end

function solve(input)
	local events = {}

	for _, v in ipairs(input) do events[#events + 1] = parse_event(v) end
	table.sort(events, sortByTime)

	-- Record when and for how long the guards were asleep
	local sleep_record = build_sleep_record(events)	

	-- Find the guard who slept the most
	local sleepiest_guard_id = find_sleepiest_guard(sleep_record)
	
	-- Find the minute that the guard was asleep the most
	local guard_record = sleep_record[sleepiest_guard_id]
	local sleepiest_minute = find_sleepiest_minute(build_timeline(guard_record))
	
	return sleepiest_guard_id * sleepiest_minute
end

local input = input.read_file("input.txt")
print("Solution: " .. (solve(input) or "not found"))
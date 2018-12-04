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
	-- A sleep record tracks for each guard when and for how long he was asleep
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

function build_timeline(guard_record)
	-- A timeline tracks how often a guard has been asleep at any given minute
	local timeline = {}
	for _, record in ipairs(guard_record) do
		local limit = record.start + record.duration - 1
		for i = record.start, limit do 
			timeline[i] = (timeline[i] or 0) + 1 
		end
	end

	return timeline
end

function solve(input)
	local events = {}

	-- Build sorted array of guard events
	for _, v in ipairs(input) do events[#events + 1] = parse_event(v) end
	table.sort(events, sortByTime)

	-- Record when and for how long the guards were asleep
	local sleep_record = build_sleep_record(events)	

	local max = 0
	local max_minute = nil
	local max_guard_id = nil
	for guard_id, record in pairs(sleep_record) do
		local timeline = build_timeline(record)
		for minute, times_asleep in pairs(timeline) do
			if times_asleep > max then
				max = times_asleep
				max_minute = minute
				max_guard_id = guard_id
			end
		end
	end

	return max_minute * max_guard_id
end

local input = input.read_file("input.txt")
print("Solution: " .. (solve(input) or "not found"))
local
ipairs, next, print, string, table, tostring, type =
ipairs, next, print, string, table, tostring, type
local gsub = string.gsub
local table_concat = table.concat

local escape_transform_table = {
	[string.char(00)] = "", -- https://www.ietf.org/rfc/rfc4627.txt
	[string.char(01)] = "",
	[string.char(02)] = "",
	[string.char(03)] = "",
	[string.char(04)] = "",
	[string.char(05)] = "",
	[string.char(06)] = "",
	[string.char(07)] = "",
	[string.char(08)] = "",
	[string.char(09)] = "",
	[string.char(10)] = "",
	[string.char(11)] = "",
	[string.char(12)] = "",
	[string.char(13)] = "",
	[string.char(14)] = "",
	[string.char(15)] = "",
	[string.char(16)] = "",
	[string.char(17)] = "",
	[string.char(18)] = "",
	[string.char(19)] = "",
	[string.char(20)] = "",
	[string.char(21)] = "",
	[string.char(22)] = "",
	[string.char(23)] = "",
	[string.char(24)] = "",
	[string.char(25)] = "",
	[string.char(26)] = "",
	[string.char(27)] = "",
	[string.char(28)] = "",
	[string.char(29)] = "",
	[string.char(30)] = "",
	[string.char(31)] = "",
	['\\'] = '\\\\',
	['"'] = '\\"',
}

-- escaping takes 2/3 of the time, but we can't avoid it...
local function escape(str)
	return gsub(str, ".", escape_transform_table)
end

local function encode_table_key(obj, buffer)
	local _type = type(obj)
	if _type == "string" then
		buffer[#buffer + 1] = escape(obj)
	elseif _type == "number" then
		buffer[#buffer + 1] = obj
	elseif _type == "boolean" then
		buffer[#buffer + 1] = tostring(obj)
	else
		buffer[#buffer + 1] = '???' .. _type .. '???'
	end
end

local function encode_any_value(obj, buffer)
	local _type = type(obj)
	if _type == "table" then
		buffer[#buffer + 1] = '{'
		buffer[#buffer + 1] = '"' -- needs to be separate for empty tables {}
		for key, value in next, obj, nil do
			encode_table_key(key, buffer)
			buffer[#buffer + 1] = '":'
			encode_any_value(value, buffer)
			buffer[#buffer + 1] = ',"'
		end
		buffer[#buffer] = '}' -- note the overwrite
	elseif _type == "string" then
		buffer[#buffer + 1] = '"' .. escape(obj) .. '"'
	elseif _type == "boolean" or _type == "number" then
		buffer[#buffer + 1] = tostring(obj)
	elseif _type == "userdata" then
		buffer[#buffer + 1] = '"' .. escape(tostring(obj)) .. '"'
	else
		buffer[#buffer + 1] = '"???' .. _type .. '???"'
	end
end

local function encode_as_json(obj)
	if obj == nil then return "null" else
		local buffer = {}
		encode_any_value(obj, buffer, 1)
		return table_concat(buffer)
	end
end

_G.encode_as_json = encode_as_json

function print_as_json(...)
	local result = {}
	for n, v in ipairs({ ... }) do
		result[n] = encode_as_json(v)
	end
	print(table_concat(result, "\t"))
end

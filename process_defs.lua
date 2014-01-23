require 'lpeg'

local P = lpeg.P
local C = lpeg.C
local Ct = lpeg.Ct
local V = lpeg.V
local S = lpeg.S
local R = lpeg.R
local element = "\t%s\t=\t%s,"
local section = "-- %s --"
local D_element = "\t%s\t=\t%s, -- Line: %d"
local D_section = "-- %s -- Line: %d"

local DEBUG = false

local comment = (function()
--[[
/* ---------------------------------- GLU ---------------------------------- */
]]--
	local _space = S" \t"
	local space0 = _space^0
	local space1 = _space^1
	local digit = R'09'
	local letter =  R'AZ'
	local name = (P'_' + letter + digit)^1
	local minus = P'-'
	local side = space1 * minus^1 * space1

	local def = space0 * P'/*' * side * C(name) * side * P'*/'
	return def
end)()

local gramatics = (function()
--[[
#define GL_ONE 1
#define GL_CLIENT_PIXEL_STORE_BIT 0x00000001
]]--
	local _space = S" \t"
	local space0 = _space^0
	local space1 = _space^1
	local digit = R'09'
	local name = P'_' + R'AZ' + digit
	local hex_digit = R'09' + R'AF' + R'af'

	local def_name = P'GL_' * name^1
	local def_val = ((P'0x')^(-1) * hex_digit^1)
	local def = Ct(space0 * P'#define' * space1 * C(def_name) * space1 * C(def_val))
	return def
end)()

local n = 1
local function processLine(line)
	local t = gramatics:match(line)
	if t then
		if DEBUG then
			print(D_element:format(t[1], t[2], n))
		else
			print(element:format(t[1], t[2]))
		end
	else
		t = comment:match(line)
		if t then
			if DEBUG then
				print(D_section:format(t, n))
			else
				print(section:format(t))
			end
		end
	end
	n = n + 1
end

if #arg>0 then
	print([[gl_enum = {]])
	for line in assert(io.open(tostring(arg[1]))):lines() do
		processLine(line)
	end
	print([[}]])
else
	print(string.format("lua %s [glew.h]", arg[0]))
end

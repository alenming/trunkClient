FilterSensitive = {}
require("game.comm.Filter")

local repLen = {}
for i=1, 20 do
	repLen[i] = string.rep("*", i)
end

function FilterSensitive.FilterStr(str)
	if type(str) == "string" then
		for _, filterWord in ipairs(Filter) do
			str = string.gsub(str, filterWord, repLen[string.utf8len(filterWord)] or "********************")
		end
	end
	return str
end

return FilterSensitive
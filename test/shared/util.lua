-- Shamelessly ripped off from https://stackoverflow.com/a/7925115
function GetKeyForValue(table, value)
	for k,v in pairs(table) do
	  if v==value then return k end
	end
	return nil
end

-- *Unreal* that this isn't built-in.
function TableSize(table)
	local count = 0
	for _ in pairs(table) do
		count = count + 1
	end
	return count
end

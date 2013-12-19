-- Utility is defined in sharedUtility.lua.

-- Cubic Interpolation (Hermite)
Utility.Cuberp = function(v0 , v1 , v2 , v3 , x)
	if v0 == nil then v0 = v1 end
	if v3 == nil then v3 = v2 end
	
	local a0 = -0.5*v0 + 1.5*v1 - 1.5*v2 + 0.5*v3
	local a1 = v0 - 2.5*v1 + 2*v2 - 0.5*v3
	local a2 = -0.5*v0 + 0.5*v2
	local a3 = v1
	
	return a0*x^3 + a1*x^2 + a2*x + a3
end

Utility.VectorCuberp = function(v0 , v1 , v2 , v3 , x)
	-- todo: make distances between points less wonky at the ends.
	if v0 == nil then v0 = v1 end
	if v3 == nil then v3 = v2 end
	
	return Vector3(
		Utility.Cuberp(v0.x , v1.x , v2.x , v3.x , x) ,
		Utility.Cuberp(v0.y , v1.y , v2.y , v3.y , x) ,
		Utility.Cuberp(v0.z , v1.z , v2.z , v3.z , x)
	)
end

Utility.CastFromString = function(string , type)
	if type == "string" then
		return string
	elseif type == "number" then
		return tonumber(string)
	elseif type == "boolean" then
		string = string:lower()
		if string == "true" then
			return true
		elseif string == "false" then
			return false
		end
	end
	
	return nil
end

-- name Awesome Course Name # What an awesome Course name!
-- 				|
-- 				v
-- "name Awesome Course Name"
Utility.TrimCommentsFromLine = function(line)
	-- Holy balls, patterns are awesome.
	line = string.gsub(line , "%s*#.*" , "")
	
	-- *nix compatability.
	line = string.gsub(line, "\r", "")
	line = string.gsub(line, "\n", "")
	
	return line
end

function TableToString(o, q)
	q = q or '"'
	if type(o) == 'table' then
		local s = '{ '
		
		local first = true
		
		for k,v in pairs(o) do
			if type(k) ~= 'number' then
				k = q .. k.. q
			end
			
			if not first then
				s = s .. ', '
			end
			
			s = s .. '[' .. k .. '] = ' .. TableToString(v, q)
			first = false
		end
		
		return s .. ' }'
	else
		if type(o) ~= 'number' then
			return q .. tostring(o) .. q
		else
			return tostring(o)
		end
	end
end

function TableToMultiLineString(o, q, indent)
	q = q or '"'
	indent = indent or 0

	if type(o) == 'table' then
		local s = '{\n'
		
		local first = true
		
		for k,v in pairs(o) do
			if not first then
				s = s .. ',\n'
			end
		
			if type(k) ~= 'number' then
				k = q .. k .. q
			end
			
			for i=1,indent+1,1 do
				s = s .. '    '
			end
			
			s = s .. '[' .. k .. '] = ' .. TableToMultiLineString(v, q, indent + 1)
			first = false
		end
		
		s = s .. '\n'
		
		for i=1,indent,1 do
			s = s .. '    '
		end
		
		return s .. '}'
	else
		if type(o) ~= 'number' then
			return q .. tostring(o) .. q
		else
			return tostring(o)
		end
	end
end

function first(...)
	return arg[1]
end

function second(...)
	return arg[2]
end

function pack(...)
	return arg
end

function pick(n, ...)
	return arg[n]
end

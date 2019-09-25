local oop = {
};

function oop.make(c)
	setmetatable(c, {
		__call = oop.new;
	});
end

function oop.inherit(c, base)
	setmetatable(c, {
		__index = base;
		__call = oop.new;
	});
end

function oop:new(...)
	local out = {};
	setmetatable(out, {
		__index = self;
	});
	
	if out.construct then
		out:construct(...);
	end
	
	return out;
end

function oop.instantiate(template, ...)
	return oop.new(template, ...);
end

return oop;
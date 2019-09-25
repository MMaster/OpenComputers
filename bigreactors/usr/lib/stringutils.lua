local stringutils = {}

local units = {
	{1e-9, "n"},
	{1e-6, "µ"},
	{1e-3, "m"},
	{1e0, ""},
	{1e3, "Ki"},
	{1e6, "Me"},
	{1e9, "Gi"},
	{1e12, "Te"},
	{1e15, "Pe"},
	{1e18, "Ex"}
}

function stringutils.formatNumber(number, unit, padding, precision)
	local last_div = 1
	local last_prefix = ""
	for _, v in pairs(units) do
		if math.abs(number) < v[1] then
			break
		end
		last_div = v[1]
		last_prefix = v[2]
	end

	local number_div = number / last_div
	local spacing = 0
	if padding == true then
		spacing = 2 + string.len(unit) - string.len(last_prefix)
	end

	if number_div < 10 then
		return string.format("%" .. tostring(spacing) .. ".0" .. tostring(precision) .. "f %s%s", number_div, last_prefix, unit)
	elseif number_div < 100 then
		return string.format("%" .. tostring(spacing) .. ".0" .. tostring(precision-1) .. "f %s%s", number_div, last_prefix, unit)
	else
		return string.format("%" .. tostring(spacing) .. "d %s%s", math.floor(number_div + 0.5), last_prefix, unit)
	end
end

function stringutils.formatRFt(RFt, padding, precision)
	return stringutils.formatNumber(RFt, "RF/t", padding, math.max(2, precision or 2))
end

function stringutils.formatBt(Bt, padding, precision)
	return stringutils.formatNumber(Bt, "B/t", padding, math.max(2, precision or 2))
end


return stringutils

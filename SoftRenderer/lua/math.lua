-- 求a b c中的最大最小值
function min_max(a, b, c)
	local minv = math.min(math.min(a, b), c)
	local maxv = math.max(math.max(a, b), c)
	return minv, maxv
end

-- 求x在[a, b]中的值
function clamp(x, a, b)
	return math.min(math.max(x, a), b)
end

-- 求x在[0, 1]中的值
function saturate(x)
	return clamp(x, 0, 1)
end

dofile'vector.lua'
dofile'matrix.lua'
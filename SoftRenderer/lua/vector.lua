-- 4维向量，3维向量的齐次向量
-- xyzw也可以表示Color的rgba
vector = {x = 0, y = 0, z = 0, w = 1}

function vector:new(x, y, z, w)
	return setmetatable({x = x, y = y, z = z, w = w}, {__index = self })
end

function vector:clone()
	return vector:new(self.x, self.y, self.z, self.w)
end

-- 使|v| = 1
function vector:normalize()
	local m = self:magnitude()
	if m == 0 then return end
	self.x = self.x / m
	self.y = self.y / m
	self.z = self.z / m
	return self
end

-- 点乘
function vector:dot(v)
	return self.x * v.x + self.y * v.y + self.z * v.z
end

-- 求|v|
function vector:magnitude()
	return math.sqrt(self.x * self.x + self.y * self.y + self.z * self.z)
end

-- 分量乘法，表示缩放
function vector:mul(a, w)
	if type(a) == 'table' then
		self.x = self.x * a.x
		self.y = self.y * a.y
		self.z = self.z * a.z
		self.w = self.w * a.w
	else
		self.x = self.x * a
		self.y = self.y * a
		self.z = self.z * a
		if w then self.w = self.w * a end
	end
	return self
end

-- 向量加法
function vector:add(v)
	self.x = self.x + v.x
	self.y = self.y + v.y
	self.z = self.z + v.z
	return self
end

-- 表示Color时把rgba转成一个32位uint
-- 如 w |x |y |z 	每个分量分别乘255
--  0xFF|11|22|33 -> 0xFF112233
function vector:tocolor()
	return  math.floor(saturate(self.w) * 255) * 0x1000000 +
			math.floor(saturate(self.x) * 255) * 0x10000 + 
			math.floor(saturate(self.y) * 255) * 0x100 + 
			math.floor(saturate(self.z) * 255)
end

-- 打印值，调试用
function vector:dump(name)
	if not _G.DEBUG then return end
	print('-----------', name, '-------------')
	print(string.format('%2.3f', self.x), string.format('%2.3f', self.y), string.format('%2.3f', self.z), string.format('%2.3f', self.w))
end


-- 以下是操作向量的全局数学方法

-- v1 + v2
function vec_add(v1, v2)
	local v = vector:new()
	v.x = v1.x + v2.x
	v.y = v1.y + v2.y
	v.z = v1.z + v2.z
	v.w = 1.0
	return v
end

-- v1 - v2
function vec_sub(v1, v2)
	local v = vector:new()
	v.x = v1.x - v2.x
	v.y = v1.y - v2.y
	v.z = v1.z - v2.z
	v.w = 1.0
	return v
end

-- v * a
function vec_mul(v, a)
	local v1 = vector:new()
	if type(a) == 'table' then
		v1.x = v.x * a.x
		v1.y = v.y * a.y
		v1.z = v.z * a.z
		v1.w = v.w * a.w
	else
		v1.x = v.x * a
		v1.y = v.y * a
		v1.z = v.z * a
	end
	return v1
end

-- v1 · v2
function vec_dot(v1, v2)
	return v1.x * v2.x + v1.y * v2.y + v1.z * v2.z
end

-- v1 × v2
function vec_cross(v1, v2)
	local v = vector:new()
	v.x = v1.y * v2.z - v1.z * v2.y
	v.y = v1.z * v2.x - v1.x * v2.z
	v.z = v1.x * v2.y - v1.y * v2.x
	v.w = 1.0
	return v
end

-- v1 + ( v2 - v1 ) * d
function vec_lerp(v1, v2, d)
	return vec_add(vec_mul(v1, 1.0 - d), vec_mul(v2, d))
end

function vec_reflect(v, n)
	return vec_sub(v, vec_mul(n, vec_dot(n, v) * 2))
end

function vec_saturate(v)
	local v1 = vector:new()
	v1.x = saturate(v.x)
	v1.y = saturate(v.y)
	v1.z = saturate(v.z)
	v.w = 1.0
	return v
end
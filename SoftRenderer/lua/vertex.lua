-- 顶点 包含位置 法线 颜色 等信息
-- 描述3D数据的基本单位

vertex = {
	pos			= vector:new(),
	normal		= vector:new(),
	color		= vector:new(),
	
	new = function(self)
		return setmetatable({}, { __index = self })
	end,
}
-- VS_CONST
vertex_const = {
	wvp	= matrix:new(),
	w	= matrix:new(),
	
	new = function(self)
		return setmetatable({}, { __index = self })
	end,
}

-- VS_INPUT
vertex_input = {
	position	= vector:new(),
	normal		= vector:new(),
	color		= vector:new(),
	
	new = function(self, v)
		local vi = {}
		setmetatable(vi, { __index = self })
		if v then
			vi.position = v.pos
			vi.normal = v.normal
			vi.color = v.color
		end
		
		return vi
	end,
}

-- VS_OUTPUT
vertex_output = {
	position	= vector:new(),
	normal		= vector:new(),
	color		= vector:new(),
	worldpos	= vector:new(),
	
	new = function(self)
		return setmetatable({}, { __index = self })
	end,
}

-- VERTEX_SHADER
vertex_shader = function(sc, vi)
	local vo = vertex_output:new()
	
	vo.position = mat_apply(sc.wvp, vi.position)
	vo.normal = mat_apply(sc.w, vi.normal)
	vo.color = vi.color:clone()
	vo.worldpos	= mat_apply(sc.w, vi.position)
	
	return vo
end

-- PS_CONST
pixel_const = {
	lightcolor	= vector:new(),
	lightdir	= vector:new(),
	specular	= vector:new(),
	shine		= 0,
	eye			= vector:new(),
	
	new = function(self)
		return setmetatable({}, { __index = self })
	end,
}

-- PS_INPUT
pixel_input = {
	position	= vector:new(),
	normal		= vector:new(),
	color		= vector:new(),
	worldpos	= vector:new(),
	
	new = function(self)
		return setmetatable({}, { __index = self })
	end,
}

-- PS_OUTPUT
pixel_output = {
	position	= vector:new(),
	color		= vector:new(),
	
	new = function(self)
		return setmetatable({}, { __index = self })
	end,
}

-- PIXEL_SHADER 标准PS，只输出颜色
pixel_shader = function(sc, pi)
	local po = pixel_output:new()
	
	po.position = pi.position
	po.color = pi.color:clone()
	po.color.w = 1.0
	
	return po
end

-- 光照 只考虑Lambert模型
lighting_shader = function(sc, pi)
	local po = pixel_output:new()
	
	po.position = pi.position
	-- lighting
	-- Color *= dot(N, L) * LightColor
	local diffuse = vec_mul(sc.lightcolor, saturate(vec_dot(vec_mul(sc.lightdir, -1), pi.normal)))
	local color = vec_mul(pi.color, diffuse)
	po.color = color
	po.color.w = 1.0

	return po
end

-- 带光照和材质 考虑Lambert模型与blinn-phong模型
material_shader = function(sc, pi)
	local po = pixel_output:new()
	
	po.position = pi.position
	-- lambert
	local diffuse = vec_mul(sc.lightcolor, saturate(vec_dot(vec_mul(sc.lightdir, -1), pi.normal)))
	
	-- blinn-phong光照模型 ：Specular = pow(dot(H, N), shine)
	local view = vec_sub(sc.eye, pi.worldpos)
	view:normalize()
	local halfway = vec_add(vec_mul(sc.lightdir, -1), view):normalize()
	local specular_blinn = vec_mul(sc.specular, math.pow(saturate(vec_dot(halfway, pi.normal)), sc.shine))
	-- 看上面的phong光照的实现，补全blinn-phong光照模型
	
	local color = vec_mul(pi.color, diffuse)
	color = vec_add(color, specular_blinn)
	
	po.color = color
	po.color.w = 1.0
	
	return po
end

-- 带光照和材质 考虑Lambert模型与phong模型
blend_shader = function(sc, pi)
	local po = pixel_output:new()
	
	po.position = pi.position
	-- lambert
	local diffuse = vec_mul(sc.lightcolor, saturate(vec_dot(vec_mul(sc.lightdir, -1), pi.normal)))
	
	-- phong光照模型 ：Specular = pow(dot(V, R), shine) 
	-- specular含义大致为镜面光强, 这里因为将太阳作为光源, 因此材料反射什么颜色的光反射光就是什么颜色所以直接用材料的specolor即sc.specular作为反射光
	local reflect = vec_reflect(sc.lightdir, pi.normal)
	local view = vec_sub(sc.eye, pi.worldpos)
	view:normalize()
	local specular = vec_mul(sc.specular, math.pow(saturate(vec_dot(reflect, view)), sc.shine))
	
	local color = vec_mul(pi.color, diffuse)
	color = vec_add(color, specular)
	
	po.color = color
	po.color.w = pi.color.w
	
	return po
end
dofile'math.lua'
dofile'vertex.lua'
dofile'shader.lua'

_G.DEBUG = true
_G.SHOW = 0
_G.WIDTH = 800
_G.HEIGHT = 600

-- 内置颜色, 用vector表示
_G.COLOR = {
	RED		= vector:new(1,0,0,1),
	GREEN	= vector:new(0,1,0,1),
	BLUE	= vector:new(0,0,1,1),
	BLACK	= vector:new(0,0,0,1),
	WHITE	= vector:new(1,1,1,1),
	GRAY	= vector:new(0.5,0.5,0.5,1),
}

-- 存储一帧里渲染到屏幕上的颜色等数据
device = {
	width		= 0,
	height		= 0,
	framebuffer	= {},
	zbuffer		= {},
}

-- 处理3D空间到2D空间的转换,wh屏幕宽高, aspect宽高比
transform = {
	w = 0,
	h = 0,
	world		= matrix:new(),
	view		= matrix:new(),
	projection	= matrix:new(),
	wvp			= matrix:new(),
	eye			= vector:new(),
	
	init = function(self, w, h)
		self.w, self.h = w, h
		local aspect = w / h
		self.projection:perspective(0.5*math.pi, aspect, 1, 500)
	end,
	
	set_camera = function(self, eye, look, up)
		if not look then 
			look = vector:new()
		end
		if not up then 
			up = vector:new(0,0,1,1)
		end
		
		self.view:lookat(eye, look, up)
		self.eye = eye
	end,
	
	set_world = function(self, mat)
		self.world = mat
	end,
	
	update = function(self)
		self.wvp = mat_mul(mat_mul(self.world, self.view), self.projection)
	end,
	
	-- 转到屏幕像素坐标
	homogenize = function(self, vec)
		local w = 1.0 / vec.w
		local v = vector:new()
		v.x = (1.0 + vec.x * w) * self.w * 0.5
		v.y = (1.0 - vec.y * w) * self.h * 0.5
		v.z = vec.z * w
		v.w = 1.0
		return v
	end,
}

-- 太阳光
sunlight = {
	lightcolor	= COLOR.WHITE,
	lightdir	= vector:new(0,-1,-0.3,1),
}

-- 物体材质 specolor 物体反射光线的颜色类型 shine物体反射比率
material = {
	specolor	= vector:new(2.0,2.0,2.0,1.0),
	shine		= 10.0,
}

-- 一帧开始时清空屏幕数据
function clear(color, depth)
	for i = 1, device.width do
		if not device.framebuffer[i] then device.framebuffer[i] = {} end
		if not device.zbuffer[i] then device.zbuffer[i] = {} end
		for j = 1, device.height do
			device.framebuffer[i][j] = color
			device.zbuffer[i][j] = depth
		end
	end
end

-- 设备初始化, 将设备初始化为全黑, 1深度
function device:init(w, h)
	self.width = w
	self.height = h
	
	clear(_G.COLOR.BLACK, 1.0)
end

-- 经过投影后的裁剪（看在不在方盒里）
function check_cvv(v)
	return v.z > 0 and v.z < v.w and v.x > -v.w and v.x < v.w and v.y > -v.w and v.y < v.w
end

-- 画3D三角形
function device:draw_triangle3d(vertex1, vertex2, vertex3)

	local vi1 = vertex_input:new(vertex1)
	local vi2 = vertex_input:new(vertex2)
	local vi3 = vertex_input:new(vertex3)
	
	-- vertex shader const
	-- transform为全局变量, 表示当前变换
	local vc = vertex_const:new()
	vc.wvp = transform.wvp
	vc.w = transform.world
	
	-- 顶点着色器中的坐标系转换
	local vo1 = vertex_shader(vc, vi1)
	local vo2 = vertex_shader(vc, vi2)
	local vo3 = vertex_shader(vc, vi3)
	
	-- rasterize光栅化
	
	-- check cvv 裁剪
	if not check_cvv(vo1.position) then return end
	if not check_cvv(vo2.position) then return end
	if not check_cvv(vo3.position) then return end
	


	-- homogenize 齐次化
	local v1 = transform:homogenize(vo1.position)
	local v2 = transform:homogenize(vo2.position)
	local v3 = transform:homogenize(vo3.position)

	-- back face cull 背面剔除
	local s21 = vec_sub(v2, v1)
	local s31 = vec_sub(v3, v1)
	if vec_cross(s21, s31).z < 0 then return end

	-- lerp 插值
	v1.w = 1.0 / vo1.position.w
	v2.w = 1.0 / vo2.position.w
	v3.w = 1.0 / vo3.position.w
	
	vo1.color:mul(v1.w, true)
	vo2.color:mul(v2.w, true)
	vo3.color:mul(v3.w, true)
	
	vo1.normal:mul(v1.w)
	vo2.normal:mul(v2.w)
	vo3.normal:mul(v3.w)
	
	-- pixel shader const
	local pc = pixel_const:new()
	pc.lightcolor	= sunlight.lightcolor
	pc.lightdir		= sunlight.lightdir
	pc.specular		= material.specolor
	pc.shine		= material.shine
	pc.eye			= transform.eye

	-- rasterize
	local x0, x1 = min_max(v1.x, v2.x, v3.x)
	local y0, y1 = min_max(v1.y, v2.y, v3.y)
	local nv1 = (v1.y - v2.y) * v3.x + (v2.x - v1.x) * v3.y + v1.x * v2.y - v2.x * v1.y
	local nv2 = (v1.y - v3.y) * v2.x + (v3.x - v1.x) * v2.y + v1.x * v3.y - v3.x * v1.y

	for x = x0, x1 do
		for y = y0, y1 do
			local c = ((v1.y - v2.y) * x + (v2.x - v1.x) * y + v1.x * v2.y - v2.x * v1.y) / nv1
			if c >= 0 and c <= 1 then
				local b = ((v1.y - v3.y) * x + (v3.x - v1.x) * y + v1.x * v3.y - v3.x * v1.y) / nv2
				if b >= 0 and b <= 1 then
					local a = 1 - b - c
					if a >= 0 and a <= 1 then
						local pi = pixel_input:new()

						local w = 1 / ( a * v1.w + b * v2.w + c * v3.w )

						local z = (v1.z * v1.w * a + v2.z * v2.w * b + v3.z * v3.w * c) * w

						local nx = (vo1.normal.x * a + vo2.normal.x * b + vo3.normal.x * c) * w
						local ny = (vo1.normal.y * a + vo2.normal.y * b + vo3.normal.y * c) * w
						local nz = (vo1.normal.z * a + vo2.normal.z * b + vo3.normal.z * c) * w

						local R = (vo1.color.x * a + vo2.color.x * b + vo3.color.x * c) * w
						local G = (vo1.color.y * a + vo2.color.y * b + vo3.color.y * c) * w
						local B = (vo1.color.z * a + vo2.color.z * b + vo3.color.z * c) * w
						local A = (vo1.color.w * a + vo2.color.w * b + vo3.color.w * c) * w

						local wx = (vo1.worldpos.x * a + vo2.worldpos.x * b + vo3.worldpos.x * c) * w
						local wy = (vo1.worldpos.y * a + vo2.worldpos.y * b + vo3.worldpos.y * c) * w
						local wz = (vo1.worldpos.z * a + vo2.worldpos.z * b + vo3.worldpos.z * c) * w

						pi.position = vector:new(x, y, z, 1)
						pi.normal = vector:new(nx, ny, nz, 1):normalize()
						pi.color = vector:new(R, G, B, A)
						pi.worldpos = vector:new(wx, wy, wz, 1)

						-- pixel shader
						-- po = pixel_shader(pc, pi)

						if _G.SHOW == 6 then		po = pixel_shader(pc, pi)
						elseif _G.SHOW == 7 then	po = lighting_shader(pc, pi)
						elseif _G.SHOW == 8 then	po = material_shader(pc, pi)
						elseif _G.SHOW == 9 then	po = blend_shader(pc, pi)
						end

						-- output merge
						self:output_merge(po)
					end
				end
			end
		end
	end
end

-- 深度测试和颜色混合
function device:output_merge(po)
	local x, y, z = math.floor(po.position.x), math.floor(po.position.y), po.position.z
	-- depth test
	if z > self.zbuffer[x][y] then return end
	local color = po.color
	-- color blend
	if color.w < 1.0 then
		local des = self.framebuffer[x][y]
		self.framebuffer[x][y] = vec_lerp(des, color, color.w)
	else
		-- depth write
		self.framebuffer[x][y] = color
		self.zbuffer[x][y] = po.position.z
	end
end

-- 画点
function device:draw_point(x, y, color)
	self.framebuffer[math.floor(x + 1)][math.floor(y + 1)] = color
end

-- 画2D线
-- 画一条从(x1, y1)到(x2, y2)的线段, 颜色从c1变到c2
function device:draw_line(x1, y1, x2, y2, c1, c2)
	c2 = c2 or c1

	-- 只有一个点
	if x1 == x2 and y1 == y2 then
		self:draw_point(x1, y1, c2)

	-- 直线垂直于x轴
	elseif x1 == x2 then
		local step = y2 >= y1 and 1 or -1
		for i = y1, y2, step do
			ratio = (i - y1) / (y2 - y1)
			self:draw_point(x1, i, vec_lerp(c1, c2, ratio))
		end

	-- 直线平行于x轴
	elseif y1 == y2 then
		local step = x2 >= x1 and 1 or -1
		for i = x1, x2, step do
				ratio = (i - x1) / (x2 - x1)
				self:draw_point(i, y1, vec_lerp(c1, c2, ratio))
			end

	-- 倾斜直线
	else
		local diff = 0
		local dx = math.abs(x1 - x2)
		local dy = math.abs(y1 - y2)

		-- 斜率绝对值小于1
		if dx >= dy then
			local j = y1
			local step = x2 > x1 and 1 or -1
			for i = x1, x2, step do
				ratio = vec_sub(vector:new(i, j, 0, 1), vector:new(x1, y1, 0, 1)):magnitude() / vec_sub(vector:new(x2, y2, 0, 1), vector:new(x1, y1, 0, 1)):magnitude()
				self:draw_point(i, j, vec_lerp(c1, c2, ratio))
				diff = diff + dy
				if diff >= dx then
					diff = diff - dx
					j = j + (y2 >= y1 and 1 or -1)
				end
			end

		-- 斜率绝对值大于1
		else
			local step = y2 > y1 and 1 or -1
			local i = x1
			for j = y1, y2, step do
				ratio = vec_sub(vector:new(i, j, 0, 1), vector:new(x1, y1, 0, 1)):magnitude() / vec_sub(vector:new(x2, y2, 0, 1), vector:new(x1, y1, 0, 1)):magnitude()
				self:draw_point(i, j, vec_lerp(c1, c2, ratio))
				diff = diff + dx
				if diff >= dy then
					diff = diff - dy
					i = i + (x2 >= x1 and 1 or -1)
				end
			end
		end
	end
end

-- 画3D点
function device:draw_point3d(x, y, z, color)
	local v = mat_apply(transform.wvp, vector:new(x, y, z, 1.0))
	if not check_cvv(v) then 
		return 
	end
	local vpos = transform:homogenize(v)
	self:draw_point(vpos.x, vpos.y, color)
end

-- 画3D线
function device:draw_line3d(vertex1, vertex2, color)
	local vpos1 = mat_apply(transform.wvp, vertex1.pos)
	local vpos2 = mat_apply(transform.wvp, vertex2.pos)
	if not check_cvv(vpos1) then return end
	if not check_cvv(vpos2) then return end
	
	local v1 = transform:homogenize(vpos1)
	local v2 = transform:homogenize(vpos2)

	if color ~= nil then
		self:draw_line(v1.x, v1.y, v2.x, v2.y, color, color)
	else
		self:draw_line(v1.x, v1.y, v2.x, v2.y, vertex1.color, vertex2.color)
	end
end


-- 画3D三角形线框
function device:draw_triangle_wireframe(vertex1, vertex2, vertex3)
	local vpos1 = mat_apply(transform.wvp, vertex1.pos)
	local vpos2 = mat_apply(transform.wvp, vertex2.pos)
	local vpos3 = mat_apply(transform.wvp, vertex3.pos)
	
	if not check_cvv(vpos1) then return end
	if not check_cvv(vpos2) then return end
	if not check_cvv(vpos3) then return end
	
	local v1 = transform:homogenize(vpos1)
	local v2 = transform:homogenize(vpos2)
	local v3 = transform:homogenize(vpos3)

	self:draw_line(v1.x, v1.y, v2.x, v2.y, vertex1.color, vertex2.color)
	self:draw_line(v1.x, v1.y, v3.x, v3.y, vertex1.color, vertex3.color)
	self:draw_line(v2.x, v2.y, v3.x, v3.y, vertex2.color, vertex3.color)
end


function getTriangleInterp(v1, v2, v3, p, uv)
	local ca = vec_sub(v3, v1)
	local ba = vec_sub(v2, v1)
	local pa = vec_sub(p, v1)

	dot00 = vec_dot(ca, ca)
	dot01 = vec_dot(ca, ba)
	dot02 = vec_dot(ca, pa)
	dot11 = vec_dot(ba, ba)
	dot12 = vec_dot(ba, pa)

	inverDeno = 1 / (dot00 * dot11 - dot01 * dot01)
	uv.u = (dot11 * dot02 - dot01 * dot12) * inverDeno
	if uv.u < 0 or uv.u > 1 then return false end
	uv.v = (dot00 * dot12 - dot01 * dot02) * inverDeno
	if uv.v < 0 or uv.v > 1 then return false end

	if uv.v + uv.u > 1 then return false 
	else return true end
end

-- 填充三角形
function device:draw_triangle_fill(vertex1, vertex2, vertex3)
	local vpos1 = mat_apply(transform.wvp, vertex1.pos)
	local vpos2 = mat_apply(transform.wvp, vertex2.pos)
	local vpos3 = mat_apply(transform.wvp, vertex3.pos)
	
	if not check_cvv(vpos1) then return end
	if not check_cvv(vpos2) then return end
	if not check_cvv(vpos3) then return end
	
	local v1 = transform:homogenize(vpos1)
	local v2 = transform:homogenize(vpos2)
	local v3 = transform:homogenize(vpos3)

	local max = vector:new(v1.x, v1.y, 0, 1)
	local min = vector:new(v1.x, v1.y, 0, 1)

	if v2.x > max.x then max.x = v2.x end
	if v3.x > max.x then max.x = v3.x end
	if v2.y > max.y then max.y = v2.y end
	if v3.y > max.y then max.y = v3.y end

	if v2.x < min.x then min.x = v2.x end
	if v3.x < min.x then min.x = v3.x end
	if v2.y < min.y then min.y = v2.y end
	if v3.y < min.y then min.y = v3.y end

	for i = min.x, max.x do 
		for j = min.y, max.y do
			local uv = {u = 0, v = 0}
			if getTriangleInterp(v1, v2, v3, vector:new(i, j, 0, 1), uv) then
				r = vertex1.color.x * (1 - uv.u - uv.v) + vertex2.color.x * uv.v + vertex3.color.x * uv.u
				g = vertex1.color.y * (1 - uv.u - uv.v) + vertex2.color.y * uv.v + vertex3.color.y * uv.u
				b = vertex1.color.z * (1 - uv.u - uv.v) + vertex2.color.z * uv.v + vertex3.color.z * uv.u
				self:draw_point(i, j, vector:new(r, g, b, 1))
			end
		end
	end
end




-- 初始化
-- init device
device:init(WIDTH, HEIGHT)
transform:init(WIDTH, HEIGHT)
transform:set_camera(vector:new(0,-3,0,1))
transform:set_world(matrix:new())
transform:update()

transform.world:dump('world')
transform.view:dump('view')
transform.projection:dump('proj')
transform.wvp:dump('wvp')

-- init triangle vertices
vtex1 = vertex:new()
vtex2 = vertex:new()
vtex3 = vertex:new()
vtex4 = vertex:new()
vtex5 = vertex:new()
vtex6 = vertex:new()

vtex1.pos = vector:new(-1,0,0,1)
vtex2.pos = vector:new(1,0,0,1)
vtex3.pos = vector:new(0,0,1,1)
vtex4.pos = vector:new(0,1,0,1)
vtex5.pos = vector:new(2,1,0,1)
vtex6.pos = vector:new(1,1,1,1)

vtex1.normal = vector:new(1,0,0,1)
vtex2.normal = vector:new(1,0,0,1)
vtex3.normal = vector:new(1,0,0,1)
vtex4.normal = vector:new(1,0,0,1)
vtex5.normal = vector:new(1,0,0,1)
vtex6.normal = vector:new(1,0,0,1)

vtex1.color = vector:new(0,0,1,0.3)
vtex2.color = vector:new(0,0,1,0.3)
vtex3.color = vector:new(0,0,1,0.3)
vtex4.color = vector:new(0,1,0,0.3)
vtex5.color = vector:new(0,1,0,0.3)
vtex6.color = vector:new(0,1,0,0.3)

vtex1.normal = vec_cross(vec_sub(vtex3.pos, vtex1.pos), vec_sub(vtex2.pos, vtex1.pos)):normalize()
vtex2.normal = vtex1.normal:clone()
vtex3.normal = vtex1.normal:clone()
vtex4.normal = vec_cross(vec_sub(vtex6.pos, vtex4.pos), vec_sub(vtex5.pos, vtex4.pos)):normalize()
vtex5.normal = vtex4.normal:clone()
vtex6.normal = vtex4.normal:clone()

local r = 0

function render(e)
	-- 背景涂黑
	clear(COLOR.BLACK, 1.0)
	
	-- 旋转
	r = r + e * 0.001
	transform:set_world(matrix:rotate(0,0,1,r))
	transform:update()
	
	-- 展示不同阶段
	if SHOW == 0 then		device:draw_point(400,200,COLOR.RED) -- 2D点
	elseif SHOW == 1 then	-- 2D线
		-- 测试： 垂直x轴
		device:draw_line(400,200,400,300,COLOR.RED,COLOR.GREEN)
		device:draw_line(500,300,500,200,COLOR.RED,COLOR.GREEN)

		-- 测试： 平行x轴
		device:draw_line(200,300,400,300,COLOR.RED,COLOR.GREEN)
		device:draw_line(400,400,200,400,COLOR.RED,COLOR.GREEN)

		-- 测试： 斜率<=1
		device:draw_line(400,400,600,500,COLOR.RED,COLOR.GREEN)
		device:draw_line(600,400,400,300,COLOR.RED,COLOR.GREEN)

		-- 测试： 斜率>1
		device:draw_line(600,400,700,600,COLOR.RED,COLOR.GREEN)
		device:draw_line(700,400,600,200,COLOR.RED,COLOR.GREEN)
	elseif SHOW == 2 then	device:draw_point3d(0,0,1,COLOR.GREEN) -- 3D点
	elseif SHOW == 3 then	
		device:draw_line3d(vtex3, vtex2) -- 3D线
	elseif SHOW == 4 then	device:draw_triangle_wireframe(vtex1, vtex2, vtex3) -- 3D线框
	elseif SHOW == 5 then	
		device:draw_triangle_fill(vtex1, vtex2, vtex3) -- 填充三角形
	elseif SHOW == 6 then	device:draw_triangle3d(vtex1, vtex2, vtex3) -- 颜色
	elseif SHOW == 7 then	device:draw_triangle3d(vtex1, vtex2, vtex3) -- 光照
	elseif SHOW == 8 then	device:draw_triangle3d(vtex1, vtex2, vtex3) -- 材质
	elseif SHOW == 9 then	
		device:draw_triangle3d(vtex1, vtex2, vtex3) -- 混合
		device:draw_triangle3d(vtex4, vtex5, vtex6) -- 混合
	end
end

_app:onIdle(function(e)
	render(e)
	for i = 1, device.width do
		for j = 1, device.height do
			local c = device.framebuffer[i][j]
			if c.x > 0 or c.y > 0 or c.z > 0 then
				_rd:drawPoint(i, j, c:tocolor())
			end
		end
	end
end)

_app:onKeyDown(function(k)
	if k == _System.KeyLeft then
		SHOW = (SHOW - 1) % 10
	elseif k == _System.KeyRight then
		SHOW = (SHOW + 1) % 10
	end
	print("SHOW:", SHOW)
end)
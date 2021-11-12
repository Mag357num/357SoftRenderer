-- 4X4矩阵，集缩放旋转平移于一身，方便计算
matrix = {	1, 0, 0, 0, 
			0, 1, 0, 0,
			0, 0, 1, 0,
			0, 0, 0, 1	}

function matrix:new()
	return setmetatable({}, {__index = self })
end

function matrix:identity()
	self[1],  self[2],  self[3],  self[4]	= 1, 0, 0, 0
	self[5],  self[6],  self[7],  self[8]	= 0, 1, 0, 0
	self[9],  self[10], self[11], self[12]	= 0, 0, 1, 0
	self[13], self[14], self[15], self[16]	= 0, 0, 0, 1
end

function matrix:zero()
	self[1],  self[2],  self[3],  self[4]	= 0, 0, 0, 0
	self[5],  self[6],  self[7],  self[8]	= 0, 0, 0, 0
	self[9],  self[10], self[11], self[12]	= 0, 0, 0, 0
	self[13], self[14], self[15], self[16]	= 0, 0, 0, 0
end

-- 在xyz轴上缩放
function matrix:scale(x, y, z)
	self[1],  self[2],  self[3],  self[4]	= x, 0, 0, 0
	self[5],  self[6],  self[7],  self[8]	= 0, y, 0, 0
	self[9],  self[10], self[11], self[12]	= 0, 0, z, 0
	self[13], self[14], self[15], self[16]	= 0, 0, 0, 1
end

-- 绕向量V(x,y,z)旋转r弧度
function matrix:rotate(x, y, z, r)
	local sinvalue, cosvalue = math.sin(r), math.cos(r)
	local cosreverse = 1 - cosvalue

	local m = math.sqrt(x*x + y*y + z*z)
	x, y, z = x/m, y/m, z/m

	local m = matrix:new()
	m[1]  = cosreverse * x * x + cosvalue
	m[2]  = cosreverse * x * y + sinvalue * z
	m[3]  = cosreverse * x * z - sinvalue * y
	m[4]  = 0
	m[5]  = cosreverse * x * y - sinvalue * z
	m[6]  = cosreverse * y * y + cosvalue
	m[7]  = cosreverse * y * z + sinvalue * x
	m[8]  = 0
	m[9]  = cosreverse * x * z + sinvalue * y
	m[10] = cosreverse * y * z - sinvalue * x
	m[11] = cosreverse * z * z + cosvalue
	m[12] = 0
	m[13] = 0
	m[14] = 0
	m[15] = 0
	m[16] = 1
	
	return m
end

-- 平移V(x,y,z)的距离
function matrix:translate(x, y, z)
	self[1],  self[2],  self[3],  self[4]	= 1, 0, 0, 0
	self[5],  self[6],  self[7],  self[8]	= 0, 1, 0, 0
	self[9],  self[10], self[11], self[12]	= 0, 0, 1, 0
	self[13], self[14], self[15], self[16]	= x, y, z, 1
end

-- View空间，以摄像机为坐标原点的空间
function matrix:lookat(eye, look, up)
	-- 现在将w坐标点变成c坐标点, 根据公式Ac = Mcw * Aw, 要求c坐标系到w坐标系的变换矩阵Mcw
	-- 1. 首先求出用w坐标表示的c坐标的基, 因为求的是Mcw, 因此需要得到用c坐标表示的w的基和原点位置
	local z = vec_sub(look, eye):normalize()
	local x = vec_cross(up, z):normalize()
	local y = vec_cross(z, x)
	
	-- 2. 先求c坐标表示的w的原点位置
	-- 已知eye向量为由world坐标系原点指向camera坐标系原点的向量, -eye是由c原点指向w原点的向量
	-- 那么-eye与c的基的点乘就是w坐标原点在c坐标系下的坐标值
	local ex = - vec_dot(x, eye)
	local ey = - vec_dot(y, eye)
	local ez = - vec_dot(z, eye)
	
	-- 3.最后求求c坐标表示的w的基
	-- 由于w的i基可能由c三个基合成, 公式为 iw = ic.x + jc.x + kc.x 因此矩阵第一行为x.x, y.x, z.x, 0
	-- 其他基同理, 得到下面代码
	self[1],  self[2],  self[3],  self[4]	= x.x, y.x, z.x, 0
	self[5],  self[6],  self[7],  self[8]	= x.y, y.y, z.y, 0
	self[9],  self[10], self[11], self[12]	= x.z, y.z, z.z, 0
	self[13], self[14], self[15], self[16]	=  ex,	ey,	 ez, 1
end

-- 投影，把一个视锥内的空间映射到CVV中（一个x:[-1,1] y:[-1,1] z:[0,1]的长方体盒子）
function matrix:perspective(fov, aspect, znear, zfar)
	local ys = 1.0 / math.tan(fov * 0.5)
	local xs = ys / aspect
	local zf = zfar / (zfar - znear)
	local zn = - znear * zf

	self[1],  self[2],  self[3],  self[4]	= xs, 0, 0, 0
	self[5],  self[6],  self[7],  self[8]	= 0, ys, 0, 0
	self[9],  self[10], self[11], self[12]	= 0, 0, zf, 1
	self[13], self[14], self[15], self[16]	= 0, 0, zn, 0
end

-- 矩阵乘法
function mat_mul(mat1, mat2)
	local mat = matrix:new()
	for i = 0, 3 do
		for j = 0, 3 do
			mat[i * 4 + j + 1] = mat1[i * 4 + 1] * mat2[j + 1] + 
								 mat1[i * 4 + 2] * mat2[j + 5] + 
								 mat1[i * 4 + 3] * mat2[j + 9] + 
								 mat1[i * 4 + 4] * mat2[j + 13]
		end
	end
	return mat
end

-- 矩阵乘向量
function mat_apply(mat, vec)
	local v = vector:new()
	v.x = vec.x * mat[1] + vec.y * mat[5] + vec.z * mat[9]  + vec.w * mat[13]
	v.y = vec.x * mat[2] + vec.y * mat[6] + vec.z * mat[10] + vec.w * mat[14]
	v.z = vec.x * mat[3] + vec.y * mat[7] + vec.z * mat[11] + vec.w * mat[15]
	v.w = vec.x * mat[4] + vec.y * mat[8] + vec.z * mat[12] + vec.w * mat[16]
	return v
end

-- 打印矩阵，调试用
function matrix:dump(name)
	if not _G.DEBUG then return end
	print('----------------- ', name, ' -----------------')
	for i = 0, 3 do
		print(  string.format('%2.3f', self[i * 4 + 1]),
				string.format('%2.3f', self[i * 4 + 2]),
				string.format('%2.3f', self[i * 4 + 3]),
				string.format('%2.3f', self[i * 4 + 4]))
	end
end
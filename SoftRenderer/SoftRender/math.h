#pragma once

#ifdef min
#undef min
#endif
#ifdef max
#undef max
#endif

#include <algorithm>

struct Vector
{
	float x, y, z, w;

	inline Vector	operator + ( const Vector& v ) { return { x + v.x, y + v.y, z + v.z }; }
	inline Vector	operator + ( const Vector& v ) const { return { x + v.x, y + v.y, z + v.z }; }
	inline Vector	operator - ( const Vector& v ) { return { x - v.x, y - v.y, z - v.z }; }
	inline Vector	operator - ( const Vector& v ) const { return { x - v.x, y - v.y, z - v.z }; }
	inline Vector	operator * ( const float& num ) { return { x * num, y * num, z * num }; }
	inline float	operator * ( const Vector& v ) { return x * v.x + y * v.y + z * v.z; }
	inline bool		operator == ( const Vector& v ) { return ( x == v.x && y == v.y && z == v.z ); }
	inline void		operator /= ( const float& num ){ if( num == 0 ) return; x /= num; y /= num; z /= num; w /= num; }
};

struct Matrix
{
	float m[4][4];
};

void	VectorAdd( Vector& v, const Vector& x, const Vector& y );
void	VectorSub( Vector& v, const Vector& x, const Vector& y );
void	VectorMul( Vector& v, const Vector& x, float f );
void	VectorCrossProduct( Vector& v, const Vector& x, const Vector& y );
void	VectorNormalize( Vector& v );
void	VectorInterp( Vector& v, const Vector& x, const Vector& y, float t );
void	VectorReflect( Vector& vo, const Vector& v, const Vector& n );

inline float	VectorLength( Vector v ) { return ( float )sqrt( v.x * v.x + v.y * v.y + v.z * v.z ); }
inline float	VectorDotProduct( const Vector& x, const Vector& y ) { return x.x * y.x + x.y * y.y + x.z * y.z; }
inline float	interp( float x1, float x2, float t ) { return x1 + ( x2 - x1 ) * t; }

void	MatrixSetIdentity( Matrix& m );
void	MatrixSetZero( Matrix& m );
void	MatrixAdd( Matrix& m, const Matrix& a, const Matrix& b );
void	MatrixSub( Matrix& m, const Matrix& a, const Matrix& b );
void	MatrixMul( Matrix& m, const Matrix& a, const Matrix& b );
void	MatrixScale( Matrix& m, const Matrix& a, const float f );
void	MatrixApply( Vector& v, const Vector& x, const Matrix& m );
void	MatrixSetTranslate( Matrix& m, float x, float y, float z );
void	MatrixSetScale( Matrix& m, float x, float y, float z );
void	MatrixSetRotate( Matrix& m, float x, float y, float z, float theta );
void	MatrixSetLookAt( Matrix& m, const Vector& eye, const Vector& at, const Vector& up );
void	MatrixSetPerspective( Matrix& m, float fovy, float aspect, float zn, float fn );

inline void getMinAABB2d( Vector& min, const Vector& a, const Vector& b, const Vector& c )
{
	min.x = std::min( { a.x, b.x, c.x } );
	min.y = std::min( { a.y, b.y, c.y } );
}

inline void getMaxAABB2d( Vector& max, const Vector& a, const Vector& b, const Vector& c )
{
	max.x = std::max( { a.x, b.x, c.x } );
	max.y = std::max( { a.y, b.y, c.y } );
}
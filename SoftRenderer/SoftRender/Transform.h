#pragma once
#include "math.h"

class Transform
{
public:
	void init( const int& width, const int& height );
	void update( );
	void homogenizeVert( Vector& sv, const Vector& pv );

	inline void applyWVP( Vector& b, const Vector& a ) { MatrixApply( b, a, transform ); }
	inline void applyWV( Vector& b, const Vector& a ) { MatrixApply( b, a, transform ); }
	inline void setWorld( const Matrix& m ) { world = m; }
	inline void setView( const Matrix& m ) { view = m; }

private:
	Matrix	world;
	Matrix	view;
	Matrix	projection;
	Matrix	transform;
	int		width;
	int		height;
};
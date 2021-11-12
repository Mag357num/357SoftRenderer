#include "Transform.h"

#define PI 3.1415926f

void Transform::init( const int& w, const int& h )
{
	width = w;
	height = h;
	MatrixSetIdentity( world );
	MatrixSetIdentity( view );
	float aspect = ( float )width / height;
	MatrixSetPerspective( projection, PI * 0.5f, aspect, 1.f, 500.f );
	update( );
}

void Transform::update( )
{
	Matrix m;
	MatrixMul( m, world, view );
	MatrixMul( transform, m, projection );
}

void Transform::homogenizeVert( Vector& sv, const Vector& pv )
{
	if( pv.w == 0.f ) return;
	float rhw = pv.w;
	sv.x = ( pv.x / rhw + 1.f ) * width * 0.5f;
	sv.y = ( - pv.y / rhw + 1.f ) * height * 0.5f;
	sv.z = pv.z / rhw;
	sv.w = 1.f;
}
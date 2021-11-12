#include "Device.h"
#include "Vertex.h"
#include "Transform.h"
#include "Light.h"
#include <math.h>

void Device::init( int w, int h, uint32* fb, Transform* ts, int** tex, Light* l, IlluminationMode il )
{
	width = w;
	height = h;
	illuminationMode = il;

	framebuffer = ( uint32** )malloc( h * sizeof( uint32* ) );
	for ( int y = 0; y < h; y ++ )
	{
		framebuffer[y] = fb + y * w;
	}

	zbuffer = ( float* )malloc( w * h * sizeof( float ) );
	memset( zbuffer, 0, w * h * sizeof( float ) );

	transform = ts;
	textures = tex;
	light = l;
}

void Device::SetCamera( float x, float y, float z )
{
	camEye = { x, y, z, 1.f };
	Vector at = { 0.f, 0.f, 0.f, 1.f }, up = { 0.f, 0.f, 1.f, 1.f };
	Matrix m;
	MatrixSetLookAt( m, camEye, at, up );
	transform->setView( m );
	transform->update( );
}

void Device::clear( )
{
	for ( int y = 0; y < height; y ++ )
	{
		for ( int x = 0; x < width; x ++ )
		{
			framebuffer[y][x] = 0x000000;
			zbuffer[y * width + x] = 1.f;
		}
	}
}

void Device::close( )
{
	if ( framebuffer != NULL )
	{
		free( framebuffer );
	}

	if ( zbuffer != NULL )
	{
		free( zbuffer );
	}
}

void Device::drawPoint2d( const Vertex& sv )
{
	int y = ( int )sv.pos.y;
	int x = ( int )sv.pos.x;

	if ( y < 0 || y >= height ) return;
	if ( x < 0 || x >= width ) return;

	if ( zbuffer[y * width + x] < sv.pos.z )
		return;

	int r = sv.color.r > 1 ? 255 : ( int )( sv.color.r * 255 );
	int g = sv.color.g > 1 ? 255 : ( int )( sv.color.g * 255 );
	int b = sv.color.b > 1 ? 255 : ( int )( sv.color.b * 255 );

	int hexColor = ( r << 16 ) | ( g << 8 ) | b;

	framebuffer[y][x] = hexColor;
	zbuffer[y * width + x] = sv.pos.z;
}

void Device::drawLine3d( const Vertex& wv1, const Vertex& wv2 )
{
	if( wv1.pos.w != 1.0f ) return;
	if( wv2.pos.w != 1.0f ) return;

	Vertex pv1 = wv1;
	Vertex pv2 = wv2;

	transform->applyWVP( pv1.pos, wv1.pos );
	transform->applyWVP( pv2.pos, wv2.pos );

	if ( checkCvv( pv1 ) ) return;
	if ( checkCvv( pv2 ) ) return;

	Vertex sv1 = pv1;
	Vertex sv2 = pv2;
	transform->homogenizeVert( sv1.pos, pv1.pos );
	transform->homogenizeVert( sv2.pos, pv2.pos );

	Vector v1 = { ( float )floor( sv1.pos.x ), ( float )floor( sv1.pos.y ), ( float )floor( sv1.pos.z ) };
	Vector v2 = { ( float )floor( sv2.pos.x ), ( float )floor( sv2.pos.y ), ( float )floor( sv2.pos.z ) };

	if ( v1 == v2 )
	{
		drawPoint2d( sv1 );
	}
	else if( v1.x == v2.x )
	{
		int step = v2.y > v1.y ? 1 : -1;
		for ( int i = ( int )v1.y; i != ( int )v2.y; i += step )
		{
			float sf = ( i - v1.y ) / ( v2.y - v1.y );
			float inv = 1 / ( sf / pv1.pos.w + ( 1 - sf ) / pv2.pos.w );
			float wf = ( sf / pv1.pos.w ) * inv;

			Color co = {
				sv1.color.r * ( 1 - wf ) + sv2.color.r * wf,
				sv1.color.g * ( 1 - wf ) + sv2.color.g * wf,
				sv1.color.b * ( 1 - wf ) + sv2.color.b * wf
			};

			Texcoord te = {
				sv1.tex.u * ( 1 - wf ) + sv2.tex.u * wf,
				sv1.tex.v * ( 1 - wf ) + sv2.tex.v * wf
			};

			Vector nor = {
				sv1.normal.x * ( 1 - wf ) + sv2.normal.x * wf,
				sv1.normal.y * ( 1 - wf ) + sv2.normal.y * wf,
				sv1.normal.z * ( 1 - wf ) + sv2.normal.z * wf,
				0.f
			};

			Vertex p = { { v1.x, ( float )i, v1.z * ( 1 - wf ) + v2.z * wf, 1.f }, co, te, nor } ;
			drawPoint2d( p );
		}
	}
	else if ( v1.y == v2.y )
	{
		int step = v2.x > v1.x ? 1 : -1;
		for ( int i = ( int )v1.x; i != ( int )v2.x; i += step )
		{
			float sf = ( i - v1.x ) / ( v2.x - v1.x );
			float inv = 1 / ( sf / pv1.pos.w + ( 1 - sf ) / pv2.pos.w );
			float wf = ( sf / pv1.pos.w ) * inv;

			Color co = {
				sv1.color.r * ( 1 - wf ) + sv2.color.r * wf,
				sv1.color.g * ( 1 - wf ) + sv2.color.g * wf,
				sv1.color.b * ( 1 - wf ) + sv2.color.b * wf
			};

			Texcoord te = {
				sv1.tex.u * ( 1 - wf ) + sv2.tex.u * wf,
				sv1.tex.v * ( 1 - wf ) + sv2.tex.v * wf
			};

			Vector nor = {
				sv1.normal.x * ( 1 - wf ) + sv2.normal.x * wf,
				sv1.normal.y * ( 1 - wf ) + sv2.normal.y * wf,
				sv1.normal.z * ( 1 - wf ) + sv2.normal.z * wf,
				0.f
			};

			Vertex p = { { ( float )i, v1.y, v1.z * ( 1 - wf ) + v2.z * wf, 1.f }, co, te, nor } ;
			drawPoint2d( p );
		}
	}
	else
	{
		float diff = 0;
		float dx = abs( sv1.pos.x - sv2.pos.x );
		float dy = abs( sv1.pos.y - sv2.pos.y );

		if ( dx >= dy )
		{
			int j = ( int )v1.y;
			int step = v2.x > v1.x ? 1 : -1;
			for ( int i = ( int )v1.x; i != ( int )v2.x; i += step )
			{
				Vector pi = { ( float )i, ( float )j, 0, 1 };
				float sf = VectorLength( pi - v1 ) / VectorLength( v2 - v1 );
				float inv = 1 / ( sf / pv1.pos.w + ( 1 - sf ) / pv2.pos.w );
				float wf = ( sf / pv1.pos.w ) * inv;

				Color co = {
					sv1.color.r * ( 1 - wf ) + sv2.color.r * wf,
					sv1.color.g * ( 1 - wf ) + sv2.color.g * wf,
					sv1.color.b * ( 1 - wf ) + sv2.color.b * wf
				};

				Texcoord te = {
					sv1.tex.u * ( 1 - wf ) + sv2.tex.u * wf,
					sv1.tex.v * ( 1 - wf ) + sv2.tex.v * wf
				};

				Vector nor = {
					sv1.normal.x * ( 1 - wf ) + sv2.normal.x * wf,
					sv1.normal.y * ( 1 - wf ) + sv2.normal.y * wf,
					sv1.normal.z * ( 1 - wf ) + sv2.normal.z * wf,
					0.f
				};

				Vertex p = { { ( float )i, ( float )j, v1.z * ( 1 - wf ) + v2.z * wf, 1.f }, co, te, nor } ;
				drawPoint2d( p );

				diff = diff + dy;
				if ( diff >= dx )
				{
					diff -= dx;
					j += ( v2.y > v1.y ? 1 : -1 );
				}
			}
		}
		else
		{
			int j = ( int )v1.x;
			int step = v2.y > v1.y ? 1 : -1;
			for ( int i = ( int )v1.y; i != ( int )v2.y; i += step )
			{
				Vector pi = { ( float )j, ( float )i, 0, 1 };
				float sf = VectorLength( pi - v1 ) / VectorLength( v2 - v1 );
				float inv = 1 / ( sf / pv1.pos.w + ( 1 - sf ) / pv2.pos.w );
				float wf = ( sf / pv1.pos.w ) * inv;

				Color co = {
					sv1.color.r * ( 1 - wf ) + sv2.color.r * wf,
					sv1.color.g * ( 1 - wf ) + sv2.color.g * wf,
					sv1.color.b * ( 1 - wf ) + sv2.color.b * wf
				};

				Texcoord te = {
					sv1.tex.u * ( 1 - wf ) + sv2.tex.u * wf,
					sv1.tex.v * ( 1 - wf ) + sv2.tex.v * wf
				};

				Vector nor = {
					sv1.normal.x * ( 1 - wf ) + sv2.normal.x * wf,
					sv1.normal.y * ( 1 - wf ) + sv2.normal.y * wf,
					sv1.normal.z * ( 1 - wf ) + sv2.normal.z * wf,
					0.f
				};

				Vertex p = { { ( float )j, ( float )i, v1.z * ( 1 - wf ) + v2.z * wf, 1.f }, co, te, nor } ;
				drawPoint2d( p );

				diff = diff + dx;
				if ( diff >= dy )
				{
					diff -= dy;
					j += ( v2.x > v1.x ? 1 : -1 );
				}
			}
		}
	}
}

void Device::drawTriangle3d( const Vertex& wv1, const Vertex& wv2, const Vertex& wv3 )
{
	if( wv1.pos.w != 1.0f ) return;
	if( wv2.pos.w != 1.0f ) return;
	if( wv3.pos.w != 1.0f ) return;

	Vertex pv1 = wv1;
	Vertex pv2 = wv2;
	Vertex pv3 = wv3;

	transform->applyWVP( pv1.pos, wv1.pos );
	transform->applyWVP( pv2.pos, wv2.pos );
	transform->applyWVP( pv3.pos, wv3.pos );

	if ( checkCvv( pv1 ) ) return;
	if ( checkCvv( pv2 ) ) return;
	if ( checkCvv( pv3 ) ) return;

	Vertex sv1 = pv1;
	Vertex sv2 = pv2;
	Vertex sv3 = pv3;
	transform->homogenizeVert( sv1.pos, pv1.pos );
	transform->homogenizeVert( sv2.pos, pv2.pos );
	transform->homogenizeVert( sv3.pos, pv3.pos );

	Vector v12 = sv2.pos - sv1.pos;
	Vector v23 = sv3.pos - sv2.pos;
	Vector cros;
	VectorCrossProduct( cros, v23, v12 );
	VectorNormalize( cros );
	if ( ( Vector { 0.f, 0.f, -1.f, 0.f } * cros ) < 0 ) return;

	Vector min;
	Vector max;
	getMinAABB2d(min, sv1.pos, sv2.pos, sv3.pos);
	getMaxAABB2d(max, sv1.pos, sv2.pos, sv3.pos);

	min.x = ( float )floor( min.x );
	min.y = ( float )floor( min.y );
	max.x = ( float )ceil( max.x );
	max.y = ( float )ceil( max.y );

	float sf1, sf2;
	for ( int j = ( int )min.y; j <= max.y; j ++ )
	{
		for ( int i = ( int )min.x; i <= max.x; i ++ )
		{
			Vector lerpPoint = { ( float )i, ( float )j, 0.f, 1.f };
			if ( triInterp_Barycentric( sv1.pos, sv2.pos, sv3.pos, lerpPoint, sf1, sf2 ) )
			{
				float inv = 1 / ( sf1 / pv1.pos.w + sf2 / pv2.pos.w + ( 1 - sf1 - sf2 ) / pv3.pos.w );
				float wf1 = ( sf1 / pv1.pos.w ) * inv, wf2 = ( sf2 / pv2.pos.w ) * inv;

				Color co = {
					sv1.color.r * wf1 + sv2.color.r * wf2 + sv3.color.r * ( 1 - wf1 - wf2 ),
					sv1.color.g * wf1 + sv2.color.g * wf2 + sv3.color.g * ( 1 - wf1 - wf2 ),
					sv1.color.b * wf1 + sv2.color.b * wf2 + sv3.color.b * ( 1 - wf1 - wf2 )
				};

				Texcoord te = {
					sv1.tex.u * wf1 + sv2.tex.u * wf2 + sv3.tex.u * ( 1 - wf1 - wf2 ),
					sv1.tex.v * wf1 + sv2.tex.v * wf2 + sv3.tex.v * ( 1 - wf1 - wf2 )
				};

				lerpPoint.z = sv1.pos.z * wf1 + sv2.pos.z * wf2 + sv3.pos.z * ( 1 - wf1 - wf2 );

				Vector wnor = {
					wv1.normal.x * wf1 + wv2.normal.x * wf2 + wv3.normal.x * ( 1 - wf1 - wf2 ),
					wv1.normal.y * wf1 + wv2.normal.y * wf2 + wv3.normal.y * ( 1 - wf1 - wf2 ),
					wv1.normal.z * wf1 + wv2.normal.z * wf2 + wv3.normal.z * ( 1 - wf1 - wf2 ),
					0.0f
				};
				VectorNormalize( wnor );

				Vector wpos = {
					wv1.pos.x * wf1 + wv2.pos.x * wf2 + wv3.pos.x * ( 1 - wf1 - wf2 ),
					wv1.pos.y * wf1 + wv2.pos.y * wf2 + wv3.pos.y * ( 1 - wf1 - wf2 ),
					wv1.pos.z * wf1 + wv2.pos.z * wf2 + wv3.pos.z * ( 1 - wf1 - wf2 ),
					1.0f
				};

				Vertex pDraw = { lerpPoint, co, te, wnor };

				switch ( illuminationMode )
				{
					case IlluminationMode::COLOR:
						break;
					case IlluminationMode::DIFFUSE:
						pDraw.color = diffusePS( pDraw, wnor );
						break;
					case IlluminationMode::PHONG:
						pDraw.color = phonePS( pDraw, wnor, wpos, camEye );
						break;
					case IlluminationMode::BLINN:
						pDraw.color = blinnPhonePS( pDraw, wnor, wpos, camEye );
						break;
					default:
						break;
				}
				drawPoint2d( pDraw );
			}
		}
	}
}

bool Device::checkCvv( const Vertex& pv )
{
	float w = pv.pos.w;
	int check = 0;
	if ( pv.pos.z < 0.0f ) check |= 1;
	if ( pv.pos.z > w ) check |= 2;
	if ( pv.pos.x < - w ) check |= 4;
	if ( pv.pos.x > w ) check |= 8;
	if ( pv.pos.y < - w ) check |= 16;
	if ( pv.pos.y > w ) check |= 32;

	return check != 0;
}

bool Device::triInterp_Barycentric( const Vector& v1, const Vector& v2, const Vector& v3, const Vector& p, float& u, float& v )
{
	float num, inv;

	num = - ( p.x - v2.x ) * ( v3.y - v2.y ) + ( p.y - v2.y ) * ( v3.x - v2.x );
	inv = - ( v1.x - v2.x ) * ( v3.y - v2.y ) + ( v1.y - v2.y ) * ( v3.x - v2.x );
	u = num / inv;

	num = - ( p.x - v3.x ) * ( v1.y - v3.y ) + ( p.y - v3.y ) * ( v1.x - v3.x );
	inv = - ( v2.x - v3.x ) * ( v1.y - v3.y ) + ( v2.y - v3.y ) * ( v1.x - v3.x );
	v = num / inv;

	if( u + v > 1 )
		return false;

	return ( u >= 0 && u <= 1 ) && ( v >= 0 && v <= 1 );
}

Color Device::diffusePS( const Vertex& sv, const Vector& normal )
{
	float kd = 0.5f;

	Vector lightDir = light->direction;
	Color lightColor = light->color;
	Color diffuse = lightColor * kd * std::max( 0.f, lightDir * -1.f * normal );

	return diffuse * sv.color;
}

Color Device::phonePS( const Vertex& sv, const Vector& normal, const Vector& pos, const Vector& camEye )
{
	float ks = 1.5f, kd = 1.0f;
	float shine = 20;

	Vector lightDir = light->direction;
	Color lightColor = light->color;
	Color diffuse = lightColor * kd * std::max( 0.f, lightDir * -1.f * normal );

	Vector reflect;
	VectorReflect( reflect, lightDir, normal );
	VectorNormalize( reflect );
	Vector view = camEye - pos;
	VectorNormalize( view );

	Color specular = lightColor * ( float )pow( std::max( 0.f, reflect * view ), shine ) * ks;

	return ( specular + diffuse ) * sv.color;
}

Color Device::blinnPhonePS( const Vertex& sv, const Vector& normal, const Vector& pos, const Vector& camEye )
{
	float ks = 1.5f, kd = 1.0f;
	float shine = 20;

	Vector lightDir = light->direction;
	Color lightColor = light->color;
	Color diffuse = lightColor * kd * std::max( 0.f, lightDir * -1.f * normal );

	Vector view = camEye - pos;
	VectorNormalize( view );
	Vector halfway = view + ( lightDir * -1.f );
	VectorNormalize( halfway );

	Color specular = lightColor * ( float )pow( std::max( 0.f, halfway * normal ), shine ) * ks;

	return ( specular + diffuse ) * sv.color;
}
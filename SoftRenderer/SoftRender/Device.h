#pragma once

#include "Config.h"
#include <Windows.h>
#include "math.h"

class Transform;
struct Vertex;
struct Color;
struct Texcoord;
struct Light;

enum class IlluminationMode{ COLOR, DIFFUSE, PHONG, BLINN };

class Device
{
public:
	inline	Device( ) : transform( NULL ), textures( NULL ), framebuffer( NULL ), zbuffer( NULL ),
		width( 0 ), height( 0 ), illuminationMode( IlluminationMode::COLOR ), light( NULL ), camEye( { 1.0f, 0.f, 0.f, 0.f } ) { }

	void	init( int w, int h, uint32* fb, Transform* ts, int** tex, Light* light, IlluminationMode illuminationMode );
	void	SetCamera( float x, float y, float z );
	void	clear( );
	void	close( );

	void	drawPoint2d( const Vertex& sv );
	void	drawLine3d( const Vertex& wv1, const Vertex& wv2 );
	void	drawTriangle3d( const Vertex& wv1, const Vertex& wv2, const Vertex& wv3 );

	bool	checkCvv( const Vertex& v );
	bool	triInterp_Barycentric( const Vector& v1, const Vector& v2, const Vector& v3, const Vector& p, float& u, float& v );

	Color	diffusePS( const Vertex& sv, const Vector& normal );
	Color	phonePS( const Vertex& sv, const Vector& normal, const Vector& pos, const Vector& camEye );
	Color	blinnPhonePS( const Vertex& sv, const Vector& normal, const Vector& pos, const Vector& camEye );

private:
	Transform*	transform;
	Light*		light;
	int**		textures;
	float *		zbuffer;
	uint32 **	framebuffer;
	int			width;
	int			height;
	Vector		camEye;
	IlluminationMode	illuminationMode;
};
#include <Windows.h>
#include <WinUser.h>
#include <windef.h>
#include <WinBase.h>
#include <time.h>
#include <assert.h>
#include <map>
#include <vector>
#include <math.h>

#include "Screen.h"
#include "Device.h"
#include "Transform.h"
#include "Config.h"
#include "Vertex.h"
#include "Light.h"
#include <fcntl.h>
#include <io.h>
#include <tchar.h>
#include <stdio.h>

#define WINDOW_WIDTH 800
#define WINDOW_HEIGHT 600

Screen* screen = NULL;
Device* device = NULL;
Transform* transform = NULL;
int* textures[3] = { 0,0,0 };

void InitConsoleWindow( )
{
	if ( AllocConsole( ) ) {
		freopen( "CONOUT$", "w", stdout );
	}
}

void TransformLight( Light& light, float theta )
{
	Matrix m;
	MatrixSetRotate( m, 0.f, 0.0f, 1.f, theta );
	transform->setWorld( m );
	transform->update( );

	transform->applyWV( light.direction, { - 0.3f, 1.f, - 0.3f, 0.f } );
	VectorNormalize( light.direction );
}

#define VK_J 0x4A
#define VK_K 0x4B

int WINAPI WinMain( HINSTANCE hInstance, HINSTANCE prevInstance, PSTR cmdLine, int showCmd )
{
	// 分配一个控制台窗口
	InitConsoleWindow( );

	// 创建一个窗口
	screen = new Screen( );
	int ret = screen->init( WINDOW_WIDTH, WINDOW_HEIGHT, _T( "SoftRendering" ) );
	if ( ret < 0 ) {
		printf( "screen init failed( %d )!\n", ret );
		exit( ret );
	}

	// 设置变换矩阵
	transform = new Transform( );
	transform->init( WINDOW_WIDTH, WINDOW_HEIGHT );

	// 设置光源
	Light light = { { 1.f, -1.f, -1.f, 0.f }, { 1.0f, 1.f, 1.f } };
	VectorNormalize( light.direction );

	// 创建设备
	uint32* wfb = ( uint32* )( screen->getFrameBuffer( ) );
	IlluminationMode illuminationMode = IlluminationMode::BLINN;
	device = new Device( );
	device->init( WINDOW_WIDTH, WINDOW_HEIGHT, wfb, transform, textures, &light, illuminationMode );
	device->SetCamera( 5.f, 0.f, 0.f );

	float light_theta = 0.f;
	while ( !screen->isExit( ) )
	{
		device->clear( );
		screen->dispatch( );

		light_theta += 0.01f;
		TransformLight( light, light_theta );

		Vertex v1 = { { 300.f, 400.f, 0.f, 1.f }, { 1.f, 0.f, 0.f }, { 0.f, 0.f }, { 1.0f, 0.f, 0.f, 0.f } };
		device->drawPoint2d( v1 );
		Vertex v2 = { { 301.f, 400.f, 0.f, 1.f }, { 1.f, 0.f, 0.f }, { 0.f, 0.f }, { 1.0f, 0.f, 0.f, 0.f } };
		device->drawPoint2d( v2 );
		Vertex v3 = { { 299.f, 400.f, 0.f, 1.f }, { 1.f, 0.f, 0.f }, { 0.f, 0.f }, { 1.0f, 0.f, 0.f, 0.f } };
		device->drawPoint2d( v3 );
		Vertex v4 = { { 300.f, 401.f, 0.f, 1.f }, { 1.f, 0.f, 0.f }, { 0.f, 0.f }, { 1.0f, 0.f, 0.f, 0.f } };
		device->drawPoint2d( v4 );
		Vertex v5 = { { 300.f, 399.f, 0.f, 1.f }, { 1.f, 0.f, 0.f }, { 0.f, 0.f }, { 1.0f, 0.f, 0.f, 0.f } };
		device->drawPoint2d( v5 );

		Vertex v6 = { { 0.f, 1.f, 1.f, 1.f }, { 1.f, 0.f, 0.f }, { 0.f, 0.f }, { 1.0f, 0.f, 0.f, 0.f } };
		Vertex v7 = { { 0.f, -1.f, -1.f, 1.f }, { 0.f, 1.f, 0.f }, { 0.f, 0.f }, { 1.0f, 0.f, 0.f, 0.f } };
		device->drawLine3d( v6, v7 );

		Vertex v8 = { { 0.f, -1.f, 1.f, 1.f }, { 1.f, 0.f, 0.f }, { 0.f, 0.f }, { 1.0f, 0.f, 0.f, 0.f } };
		Vertex v9 = { { 0.f, 1.f, -1.f, 1.f }, { 1.f, 0.f, 1.f }, { 0.f, 0.f }, { 1.0f, 0.f, 0.f, 0.f } };
		device->drawLine3d( v8, v9 );

		Vertex v10 = { { 0.f, 1.f, 0.f, 1.f }, { 1.f, 0.f, 0.f }, { 0.f, 0.f }, { 1.0f, 0.f, 0.f, 0.f } };
		Vertex v11 = { { 0.f, -1.f, 0.f, 1.f }, { 1.f, 1.f, 0.f }, { 0.f, 0.f }, { 1.0f, 0.f, 0.f, 0.f } };
		device->drawLine3d( v10, v11 );

		Vertex v12 = { { 0.f, 0.f, 1.f, 1.f }, { 1.f, 0.f, 0.f }, { 0.f, 0.f }, { 1.0f, 0.f, 0.f, 0.f } };
		Vertex v13 = { { 0.f, 0.f, -1.f, 1.f }, { 0.f, 1.f, 1.f }, { 0.f, 0.f }, { 1.0f, 0.f, 0.f, 0.f } };
		device->drawLine3d( v12, v13 );

		Vertex v14 = { { 0.f, -1.f, 0.f, 1.f }, { 1.f, 0.f, 0.f }, { 0.f, 0.f }, { 1.0f, 0.f, 0.f, 0.f } };
		Vertex v15 = { { 0.f, 0.f, -1.f, 1.f }, { 0.f, 1.f, 0.f }, { 0.f, 0.f }, { 1.0f, 0.f, 0.f, 0.f } };
		Vertex v16 = { { 0.f, 1.f, 0.f, 1.f }, { 0.f, 0.f, 1.f }, { 0.f, 0.f }, { 1.0f, 0.f, 0.f, 0.f } };
		device->drawTriangle3d( v14, v15, v16 );

		Vertex v17 = { { 0.f, -1.f, 1.f, 1.f }, { 1.f, 0.f, 0.f }, { 0.f, 0.f }, { 1.0f, 0.f, 0.f, 0.f } };
		Vertex v18 = { { 0.f, 0.f, 0.f, 1.f }, { 1.f, 0.f, 0.f }, { 0.f, 0.f }, { 1.0f, 0.f, 0.f, 0.f } };
		Vertex v19 = { { 0.f, 1.f, 1.f, 1.f }, { 1.f, 0.f, 0.f }, { 0.f, 0.f }, { 1.0f, 0.f, 0.f, 0.f } };
		device->drawTriangle3d( v17, v18, v19 );

		Vertex v20 = { { 0.f, -1.f, 0.f, 1.f }, { 1.f, 0.f, 0.f }, { 0.f, 0.f }, { 1.0f, 0.f, 0.f, 0.f } };
		Vertex v21 = { { 0.f, -1.f, -2.f, 1.f }, { 0.f, 0.f, 1.f }, { 0.f, 0.f }, { 1.0f, 0.f, 0.f, 0.f } };
		Vertex v22 = { { 0.f, 0.f, -1.f, 1.f }, { 0.f, 1.f, 0.f }, { 0.f, 0.f }, { 1.0f, 0.f, 0.f, 0.f } };
		device->drawTriangle3d( v20, v21, v22 );

		Vertex v23 = { { 0.f, 1.f, 0.f, 1.f }, { 0.f, 0.f, 1.f }, { 0.f, 0.f }, { 1.0f, 0.f, 0.f, 0.f } };
		Vertex v24 = { { 0.f, 0.f, -1.f, 1.f }, { 0.f, 1.f, 0.f }, { 0.f, 0.f }, { 1.0f, 0.f, 0.f, 0.f } };
		Vertex v25 = { { 0.f, 1.f, -2.f, 1.f }, { 1.f, 0.f, 0.f }, { 0.f, 0.f }, { 1.0f, 0.f, 0.f, 0.f } };
		device->drawTriangle3d( v23, v24, v25 );

		Vertex v26 = { { 0.f, 0.f, -1.f, 1.f }, { 0.f, 1.f, 0.f }, { 0.f, 0.f }, { 1.0f, 0.f, 0.f, 0.f } };
		Vertex v27 = { { 0.f, -1.f, -2.f, 1.f }, { 0.f, 0.f, 1.f }, { 0.f, 0.f }, { 1.0f, 0.f, 0.f, 0.f } };
		Vertex v28 = { { 0.f, 1.f, -2.f, 1.f }, { 1.f, 0.f, 0.f }, { 0.f, 0.f }, { 1.0f, 0.f, 0.f, 0.f } };
		device->drawTriangle3d( v26, v27, v28 );

		screen->dispatch( );
		screen->update( );
		Sleep( 1 );
	}

	device->close( );
	screen->close( );

	for ( int i = 0; i < 3; i ++ )
	{
		if ( textures[i] )
		{
			delete textures[i];
		}
	}

	delete transform;
	delete device;
	delete screen;

	return 0;
}
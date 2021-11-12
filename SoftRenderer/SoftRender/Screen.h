#pragma once
#include <windows.h>

class Screen
{
public:
	int init( int width, int height, LPCTSTR title );
	void update( );
	void dispatch( ); // ≈…∑¢œ˚œ¢
	void close( );
	int isKeyPressed( int key );
	int getKeyUpEvent( int key );
	int isExit( );
	LPVOID getFrameBuffer( );

private:
	HWND wndHandle;
	HDC wndDc;
	HBITMAP wndHb;
	HBITMAP wndOb;
	LPVOID wndFramebuffer;
	int width;
	int height;
};

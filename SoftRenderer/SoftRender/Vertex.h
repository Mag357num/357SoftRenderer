#pragma once

struct Color
{
	float r;
	float g;
	float b;
	inline Color operator * ( const float& num ) { return { r * num, g * num, b * num }; }
	inline Color operator * ( const Color& c ) { return { r * c.r, g * c.g, b * c.b }; }
	inline Color operator + ( const Color& c ) { return { r + c.r, g + c.g, b + c.b }; }
};

struct Texcoord
{
	float u;
	float v;
};

struct Vertex
{
	Vector pos;
	Color color;
	Texcoord tex;
	Vector normal;
};
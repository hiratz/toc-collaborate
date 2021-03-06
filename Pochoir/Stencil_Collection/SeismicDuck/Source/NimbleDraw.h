//******************************************************************************
// Graphics layer for Seismic Duck
// 
// Copyright 1996-2010 Arch D. Robison
//******************************************************************************

#pragma once

#ifndef NimbleDraw_H
#define NimbleDraw_H

#if defined(_WIN32)||defined(_WIN64)
#define NIMBLE_DIRECTX 1	/* Set to 1 for DirectX targets */
#define NIMBLE_MAC 0		/* Set to 1 for Mac targets */
/* Turn off pesky "possible loss of data" and "forcing value to bool" warnings */
#pragma warning(disable: 4244 4800) 
#else
#error unsupported target
#endif /* defined(WIN32)||defined(WIN64) */

#include <cstddef>
#include "AssertLib.h"

typedef unsigned char byte;

//! NimbleIsLittleEndian should be true on little-endian targets, false on big-endian targets.
#if NIMBLE_DIRECTX
const bool NimbleIsLittleEndian = true;
#elif NIMBLE_MAC
const bool NimbleIsLittleEndian = false;
#else
#error Unknown target
#endif

//! A point
class NimblePoint {
public:
    short x, y;
};

//! Vector subtraction of two points
inline NimblePoint operator-( NimblePoint a, NimblePoint b ) {
	NimblePoint c;
	c.x = a.x-b.x;
	c.y = a.y-b.y;
	return c;
}

//! A rectangle or bounding box.
/** The bounds form the product of half-open intervals [left,right) x [top,bottom) */
class NimbleRect {
public:
    short left, right, top, bottom;

	//! Construct undefined rectangle.
	NimbleRect() {}

	//! Construct rectangle with given corners.
	NimbleRect( int left_, int top_, int right_, int bottom_ ) : 
	    left(left_), top(top_), right(right_), bottom(bottom_) 
	{
		Assert(left<=right);
		Assert(top<=bottom);
	}

	//! Width of rectange
    int width() const {return right-left;}

    //! Height of rectangle
    int height() const {return bottom-top;}

	//! Return *this translated by given delta
	NimbleRect translate( int dx, int dy ) const {
		return NimbleRect(left+dx, top+dy, right+dx, bottom+dy);
	}

    //! True if rectangle contains horizontal coordinate x.
    bool containsX( int x ) const {return unsigned(x-left) < unsigned(width());}

    //! True if rectangle contains vertical coordinate y. 
    bool containsY( int y ) const {return unsigned(y-top) < unsigned(height());}

    //! True if rectangle contains point p.
    bool contains( const NimblePoint& p ) const {return containsX(p.x) && containsY(p.y);}

    //! True if map completely contains rectangle rect.
    bool contains( const NimbleRect& rect ) const {
        return left <= rect.left && rect.right <= right &&
               top <= rect.top && rect.bottom <= bottom;
    }

    //! Set *this to intersection of *this and r.
	/** Warning: result may have backwards intervals. */
    void intersect( const NimbleRect r ) {
        if( r.left>left ) left=r.left;
        if( r.right<right ) right=r.right;
        if( r.top>top ) top=r.top;
        if( r.bottom<bottom ) bottom=r.bottom;
    }
};

//! A pixel
/** Old versions of NimbleDraw supported 16-bit and 32-bit pixels.
    The current version supports only 32-bit pixels. */
typedef unsigned NimblePixel;

//! A device-independent color
struct NimbleColor {
#if NIMBLE_MAC
	typedef unsigned short component_t;
	enum {
	    FULL=0xFFFF					// Full intensity for component
	};
#elif NIMBLE_DIRECTX
	typedef byte component_t;		// Always some integral type
	enum {
	    FULL=0xFF					// Full intensity for component
	};
#else
#error Unknown target
#endif
    component_t red, green, blue;	// Always of type component_t
    NimbleColor() {}
    explicit NimbleColor( int gray ) : red(gray), green(gray), blue(gray) {}
    NimbleColor( int r, int g, int b ) : red(r), green(g), blue(b) {};
	void mix( const NimbleColor& other, float f );
};

inline void NimbleColor::mix( const NimbleColor& other, float f ) {
	Assert(0<=f && f<=1.0f);
	red = red*(1-f)+other.red*f;
	green = green*(1-f)+other.green*f;
	blue = blue*(1-f)+other.blue*f;
}

//! A view of memory as a rectangular region of NimblePixel.
/** The pixels within the map are those in the half-open interval [0,width()) x [0,height()).
    The map also provides mappings between colors and pixels. */
class NimblePixMap {
public:
    //! Construct undefined map.
	NimblePixMap() : myBaseAddress(0), myBytesPerRow(0) {}
	
    //! Construct map as view of memory.
    NimblePixMap( int width, int height, int bitsPerPixel, void* base, int bytesPerRow ); 

    //! Construct map for rectangular subregion of another map. 
    NimblePixMap( const NimblePixMap& src, const NimbleRect& rect ); 
	
    //! Base-2 log of bits per pixel
	/** In old versions of NimblePixMap, the depth was determined at run-time. 
	    In the current version, a NimblePixel is presumed to be 32 bits. */
    int lgBitPixelDepth() const {
		Assert(sizeof(NimblePixel)==4);
		return 5;
	}
 
    // Base-2 log of bytes per pixel
    int lgBytePixelDepth() const {return lgBitPixelDepth()-3;}

    // Pixel depth in bits per pixel  
    int bitPixelDepth() const {return 1<<lgBitPixelDepth();}	

    //! Pixel depth in bytes per pixel
    int bytePixelDepth() const {return 1<<lgBytePixelDepth();}	
 
   	//! Given color, convert to pixel.
  	NimblePixel pixel( const NimbleColor& color ) const;

	//! Given pixel, convert to color
	NimbleColor color( NimblePixel pixel ) const;

	//! Extract alpha component from a pixel.
	NimbleColor::component_t alpha( NimblePixel pixel ) const;

    //! Width of map in pixels.
    int width() const {return myWidth;}

    //! Height of map in pixels
    int height() const {return myHeight;}

    //! Byte offset from a pixel to the pixel below it.
    /** Declared short because result is often used in multiplications, 
        and so compiler gets hint that 16x16 multiply will suffice. */
    short bytesPerRow() const {return myBytesPerRow;} 

	//! Draw rectangle using given pixel for its color.
	void draw( const NimbleRect& r, NimblePixel pixel );

	//! Draw this map onto dst.
	void drawOn( NimblePixMap& dst, int x, int y ) const;

	//! Move base address by ammount corresponding to given deltaX and deltaY
	void shift( int deltaX, int deltaY );

    //! Move top edge of map down by given number of bytes
	void adjustTop( int delta );

 	//! Unchecked (in production mode) subscript into map.  Returns pointer to pixel at (x,y)
    void* at( int x, int y ) const;

	//! Return value of pixel at (x,y)
	NimblePixel pixelAt( int x, int y ) const {return *(NimblePixel*)at(x,y);}

	//! Return color of pixel at (x,y)
	NimbleColor colorAt( int x, int y ) const {return color(pixelAt(x,y));}

	//! Return alpha of pixel at (x,y)
	NimbleColor::component_t alphaAt( int x, int y ) const {return alpha(pixelAt(x,y));}

private:
	//! Pointer to pixel at (0,0)
    NimblePixel* myBaseAddress;

	//! Byte offset from a pixel to the pixel below it.
    short myBytesPerRow;

	//! Width of region in pixels.
    short myWidth;

	//! Height of region in pixels.
	short myHeight; 

    void setBitPixelDepth( int bitsPerPixel );

	// Deny access to assignment in order to prevent slicing errors with NimblePixMapWithOwnership
	void operator=( const NimblePixMap& src );
	friend class NimblePixMapWithOwnership;
};

inline void* NimblePixMap::at( int x, int y ) const {
    Assert( 0 <= x && x < width() );
    Assert( 0 <= y && y < height() );
    return (byte*)myBaseAddress + myBytesPerRow*y + (x<<lgBytePixelDepth());
}
 
inline NimbleColor::component_t NimblePixMap::alpha( NimblePixel pixel ) const {
#if NIMBLE_DIRECTX
	return pixel>>24;
#else
#error Not yet implemented on this platform
#endif /* NIMBLE_DIRECTX */
}
//! NimblePixMap that owns its buffer.
class NimblePixMapWithOwnership: public NimblePixMap {
	void operator=( const NimblePixMapWithOwnership& ); 
    NimblePixMapWithOwnership( const NimblePixMapWithOwnership& ); 
public:
	NimblePixMapWithOwnership() {}
    void deepCopy( const NimblePixMap& src );
	~NimblePixMapWithOwnership();
};

enum NimbleRequest {
	NimbleUpdate=1,
	NimbleDraw=2
};

inline NimbleRequest operator|( NimbleRequest x, NimbleRequest y ) {
	return NimbleRequest(int(x)|int(y));
}

inline NimbleRequest operator&( NimbleRequest x, NimbleRequest y ) {
	return NimbleRequest(int(x)&int(y));
}

inline NimbleRequest operator-( NimbleRequest x, NimbleRequest y ) {
	return NimbleRequest(x&~y);
}

#endif /*NimbleDraw_H*/
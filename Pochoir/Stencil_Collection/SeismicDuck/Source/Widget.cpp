//******************************************************************************
// Various meters for Seismic Duck
//
// Copyright 1996-2010 Arch D. Robison
//******************************************************************************

#include "NimbleDraw.h"
#include "Sprite.h"
#include "Widget.h"
#include "Utility.h"
#include <cstring>

//! Given point inside transparent box, find bounds of box.
static NimbleRect FindTransparentBox( const NimblePixMap& map, int xInside, int yInside ) {
	NimbleRect box;
	Assert( map.alphaAt(xInside,yInside)<NimbleColor::FULL/2 );
 	int x=xInside;
	int y=yInside;
	while( x>0 && map.alphaAt(x-1,y)<NimbleColor::FULL/2 ) 
		--x;
	while( y>0 && map.alphaAt(x,y-1)<NimbleColor::FULL/2 ) 
		--y;
	box.left=x;
	box.top=y;
	x=xInside;
	y=yInside;
	while( y+1<map.height() && map.alphaAt(x,y+1)<NimbleColor::FULL/2 ) 
		++y;
	while( x+1<map.width() && map.alphaAt(x+1,y)<NimbleColor::FULL/2 ) 
		++x;
	box.right=x+1;
	box.bottom=y+1;
	return box;
}

//-----------------------------------------------------------------
// Widget
//-----------------------------------------------------------------

void Widget::buildFrom( const NimblePixMap& map ) {
	myPixMap.deepCopy(map);
}

//-----------------------------------------------------------------
// RubberImage
//-----------------------------------------------------------------

RubberImage::RubberImage( const char* resourceName ) : 
    Widget( resourceName )
{}

void RubberImage::drawOn( NimblePixMap& map, int top, int bottom ) const {
    int dWidth=map.width();
    int dHeight=map.height();
    int sWidth=myPixMap.width();
    int sHeight=myPixMap.height();
	int x1=sWidth/2;
	int x2=dWidth-x1;
    int y1=sHeight/2;
    int y2=dHeight-y1;
	for( int y=top; y<bottom; ++y ) {
		int srcY = y<y1 ? y : y<y2 ? y1 : y-(y2-y1);
		NimblePixel* src = (NimblePixel*)myPixMap.at(0,srcY);
        NimblePixel* dst = (NimblePixel*)map.at(0,y);
		memcpy( dst, src, x1*sizeof(NimblePixel) );
		NimblePixel fill = src[x1];
		for( int k=x1; k<x2; ++k )
			dst[k] = fill;
		memcpy( dst+x2, src+x1,(dWidth-x2)*sizeof(NimblePixel) );
	}
}

//-----------------------------------------------------------------
// Font
//-----------------------------------------------------------------

inline bool Font::isBlankColumn( const NimblePixMap& map, int x ) {
	Assert(0<=x && x<map.width());
	int h = map.height();
	for( int i=0; i<h; ++i )
		if( map.pixelAt(x,i)&0xFF )
			return false;
	return true;
}

void Font::buildFrom( const NimblePixMap& map ) {
	Assert(!storage);
	myHeight = map.height();
	const int nByte = map.height()*map.width(); 
	storage = new byte[nByte];
	byte* p = storage;
	int x = 0;
	// Zeroth column must be blank
	Assert( isBlankColumn( map, 0 ));
	for( int k=charMin; k<=charMax; ++k ) {
		while( isBlankColumn( map, x ) ) {
			++x;
		}
		int xStart = x-1;
		int width=2;
		while( !isBlankColumn( map, x )) {
			++x;
			++width;
		}
		start[k-charMin] = p-storage;
        for( int i=0; i<myHeight; ++i )
			for( int j=0; j<width; ++j ) {
				Assert(p<storage+nByte);
				// Bottom row of pixels is used only as internal marker for ' ' and ".
				*p++ = i==myHeight-1 ? 0 : map.pixelAt(xStart+j,i)&0xFF; 
			}
	}
	start[charMax+1-charMin] = p-storage;
}

int Font::width( const char* s ) const {
	Assert(storage);
	Assert(myHeight>0);
	// Accumulate width times height into w.
	int w = 0;
	for(; int c = *s; ++s) {
		Assert(charMin<=c && c<=charMax);
		w  += start[c+1-charMin]-start[c-charMin];
	}
    return w/myHeight;
}

int Font::drawOn( NimblePixMap& map, int x, int y, const char* s, NimblePixel ink ) {
	for(; int c = *s; ++s) {
		Assert(charMin<=c && c<=charMax);
		byte* p = storage + start[c-charMin];
		byte* q = storage + start[c+1-charMin];
		Assert((q-p)%myHeight==0);
		int width = (q-p)/myHeight;
		if( x+width>map.width() ) {
			width = map.width()-x;
			if( width==0 )
				return x;
		}
		for( int i=0; i<myHeight; ++i ) {
			NimblePixel* dst = (NimblePixel*)map.at(x,y+i);
			for( int j=0; j<width; ++j, ++dst )
				if( *p++>=0x80 ) 
					*dst = ink;
		}
	    //	Assert(p==q);
        x+=width;
	}
	return x;
}

//-----------------------------------------------------------------
// DecimalNumeral
//-----------------------------------------------------------------

const int DIGIT_MAX = 10;

struct DecimalNumeral {
	DecimalNumeral( unsigned value, bool zeroIsEmptyString=false );
	byte digit[DIGIT_MAX];
	//! Number of valid digits in array digit.
	byte size;
};

DecimalNumeral::DecimalNumeral( unsigned value, bool zeroIsEmptyString ) {
	// Convert to decimal. 
	int k=0;
	if( value || !zeroIsEmptyString ) {
	    while( value>=10u ) {
		    digit[k++] = value%10u;
		    value/=10u;
	    }
        digit[k++]=value;
    }
	size=k;
}

//-----------------------------------------------------------------
// WheelMeter
//-----------------------------------------------------------------

class WheelDigits: public Widget {
	int faceHeight;
	void buildFrom( const NimblePixMap& map );
public:
	WheelDigits( const char* resourceName ) : Widget(resourceName) {}
	void drawOn( NimblePixMap& map, float value );
};

void WheelDigits::buildFrom( const NimblePixMap& map ) {
	Widget::buildFrom(map);
	faceHeight = myPixMap.height()/12;
}

void WheelDigits::drawOn( NimblePixMap& map, float value ) { 
    int faceTop = int(faceHeight*value);
	int faceWidth = myPixMap.width();
	// Center the face if it is not exactly the same size as the map.
	int dx = faceWidth-map.width();
	int dy = faceHeight-map.height();
	NimblePixMap subrect( myPixMap, NimbleRect(dx>>1, faceTop+(dy>>1), faceWidth-(dx-(dx>>1)), faceTop+faceHeight-(dy-(dy>>1)) ) );
	subrect.drawOn( map, 0, 0 ); 
}

static WheelDigits TheWheelDigits("WHEEL_DIGITS");

//-----------------------------------------------------------------
// WheelMeter
//-----------------------------------------------------------------

WheelMeter::WheelMeter( const char* resourceName ): 
    Widget( resourceName ),
    myValue(0),
    myNdigit(0)
{
}

void WheelMeter::buildFrom(const NimblePixMap& map) {
	// Build background image
	Widget::buildFrom(map);
	// Scan for digit windows
    int midy = map.height()/2;
	for( int x=map.width(); --x>=0; ) 
		if( map.alphaAt(x,midy)<NimbleColor::FULL/2 ) {
			Assert(myNdigit<DIGIT_MAX);
			myDigitWindow[myNdigit] = FindTransparentBox(map,x,midy);
			x=myDigitWindow[myNdigit].left;
			++myNdigit;
		}
}

void WheelMeter::drawOn( NimblePixMap& map, int x, int y ) const {
	// Draw background
	myPixMap.drawOn(map,x,y);
	// Now draw the digits
    float value = myValue;
	// Future extension: add support for negative values.
    if( value<0 ) value = -value;
	DecimalNumeral numeral(value,/*zeroIsEmptyString=*/true);
    const int faceWidth = myPixMap.width();
    const int faceHeight = height();
    float frac = value-int(value);
    for( int k=0; k<myNdigit; k++ ) {
        Assert( 0 <= frac && frac<1.0 );
		float d = k<numeral.size ? numeral.digit[k] : 0;
        const double threshold = k==0 ? 0 : (8.0/9);
        if( frac>=threshold ) {
            d += (frac-threshold)/(1.0-threshold);
        } 
		frac = d/10;
		if( d<=1.0 && k<numeral.size ) {
		    d += 10;
		}
		NimblePixMap subrect(map,myDigitWindow[k].translate(x,y));
		TheWheelDigits.drawOn( subrect, d ); 
     }
}

//-----------------------------------------------------------------
// DigitalMeter
//-----------------------------------------------------------------

DigitalMeter::DigitalMeter( int nDigit, int nDecimal ) :
    Widget( "DIGITAL_METER" ),
    myValue(0),
    myNdigit(nDigit),
	myNdecimal(nDecimal)
{
	Assert( 0<nDigit && nDigit<=DIGIT_MAX );
	Assert( 0<=nDecimal && nDecimal<=DIGIT_MAX );
}

void DigitalMeter::drawOn( NimblePixMap& map, int x, int y ) const {
	static const double powerOfTen[] = {1,10,100,1000};
	Assert(myValue>=0);	// Negative values not yet supported
	Assert( myNdecimal<sizeof(powerOfTen)/sizeof(powerOfTen[0]));
 	DecimalNumeral numeral(myValue*powerOfTen[myNdecimal]+0.5f);
	int faceWidth = myPixMap.width();
	int faceHeight = height();
	for( int k=0; k<myNdigit; ++k ) {
		int i = myNdecimal ?
			        k<myNdecimal ? (k<numeral.size ? numeral.digit[k] : 0) :
			        k==myNdecimal ? 12 :
					k-1<numeral.size ? numeral.digit[k-1] : 10 :
                k<numeral.size ? numeral.digit[k] : 10;
		int faceTop=i*faceHeight;
		NimblePixMap subrect( myPixMap, NimbleRect(0, faceTop, faceWidth, faceTop+faceHeight ) );
		subrect.drawOn( map, x+faceWidth*(myNdigit-1-k), y );
	}
}

//-----------------------------------------------------------------
// BarMeter
//-----------------------------------------------------------------

BarMeter::BarMeter( const char* resourceName ) : 
    Widget(resourceName), myValue(0) 
{
}

void BarMeter::drawOn( NimblePixMap& map, int x, int y ) const {
	int w = myPixMap.width()/2;
	int h = myPixMap.height();
	float value = myValue;
	// Clip value
	if( value<0.0f ) value=0.0f;
	if( value>1.0f ) value=1.0f;
	int fill = h*value;
    // Draw empty part of meter
	NimblePixMap(myPixMap, NimbleRect(0,0,w,h-fill)).drawOn( map, x, y );
	NimblePixMap(myPixMap, NimbleRect(w,h-fill,2*w,h)).drawOn( map, x, y+h-fill );
}

//-----------------------------------------------------------------
// GraphMeter
//-----------------------------------------------------------------
 
GraphMeter::GraphMeter( int width, int height ) :
    myWidth(width),
	myHeight(height),
	myHead(0),
	myMin(0.0f),
	myMax(1.0f)
{
	int n = myWidth<<lg2Scale;
	myArray = new float[n];
	myEnd = myArray+n;
	myHead = myArray;
    memset( myArray, 0, n*sizeof(float) );
}
 
void GraphMeter::drawOn( NimblePixMap& map, int x, int y ) const {
	NimblePixel green( map.pixel( NimbleColor(0,0xFF,0)));
	NimbleRect r(x,y,x+myWidth,y+myHeight);
	map.draw(r,NimblePixel(0));
	int h = myHeight;
	float *p = myHead;
	float a = -h/(myMax-myMin);
	float b = h - a*myMin;
	const int scale = 1;
	for( int t=(x+myWidth-1)<<scale; t>=x<<scale; --t ) {
		int i = Round(*p*a+b);
		if( p==myArray ) p=myEnd;
		--p;
		// Clip
		if( i<0 ) i=0;
		if( i>=h ) i=h-1; 
		*(NimblePixel*)map.at(t>>scale,y+i) = green;
	}
}

//-----------------------------------------------------------------
// Clickable
//-----------------------------------------------------------------
void Clickable::drawOn( NimblePixMap& map, int x, int y ) {
	myPosition.x = x;
	myPosition.y = y;
	NimblePixMap submap(map,NimbleRect(x,y,map.width(),map.height()));
	doDrawOn(submap);
}

bool Clickable::mouseDown( NimblePoint p ) {
	if( contains(p) ) {
		doMouseDown(p-myPosition);
		return true;
	} else {
		return false;
	}
}

void Clickable::mouseMove( NimblePoint p ) {
    doMouseMove(p-myPosition);
}

Clickable::action Clickable::mouseUp( NimblePoint p ) {
	return doMouseUp(p-myPosition);
}

//-----------------------------------------------------------------
// Dialog
//-----------------------------------------------------------------

Dialog::Dialog( const char* resourceName ) :
    BuiltFromResourcePixMap( resourceName ) 
{
}

void Dialog::buildFrom( const NimblePixMap& map ) {
    myPixMap.deepCopy( map );
	setClickableSize(myPixMap.width(),myPixMap.height());
}

void Dialog::doDrawOn( NimblePixMap& map ) {
	myPixMap.drawOn( map, 0, 0 );
}

Dialog::action Dialog::doMouseUp( NimblePoint p ) {
	if( 0<=p.y && p.y<32 && width()-32<=p.x && p.x<width() ) {
		return hide;
	} else {
		return none;
	}
}

//-----------------------------------------------------------------
// ButtonDialog
//-----------------------------------------------------------------

static RubberImage ButtonBackground("BUTTON_BACKGROUND");
static RubberImage ButtonSelected("BUTTON_SELECTED");

void ButtonDialog::buildFrom( const NimblePixMap& map ) {
	// Build background image
	Dialog::buildFrom( map );
	// Scan for button area
	for( int y=0; y<map.height(); ++y )
        for( int x=0; x<map.width(); ++x )
            if( map.alphaAt(x,y)<NimbleColor::FULL/2 ) {
                myButtonRect = FindTransparentBox(map,x,y);
                return;
            }
    Assert(0); // Fails if button area not found
}

void ButtonDialog::doDrawOn( NimblePixMap& map ) {
	Dialog::doDrawOn( map ); 
	NimblePixel black = map.pixel(NimbleColor(0,0,0));
	NimblePixMap buttonMap( map, myButtonRect );
    (myButtonSelected ? ButtonSelected : ButtonBackground).drawOn(buttonMap);
	int w = myButtonRect.width();
	for( int y=myButtonRect.top; y<myButtonRect.bottom; ++y ) {
		const NimblePixel* src = (NimblePixel*)myPixMap.at(myButtonRect.left,y);
		NimblePixel* dst = (NimblePixel*)map.at(myButtonRect.left,y);
		for( int j=0; j<w; ++j ) 
			if( map.alpha(src[j])>=NimbleColor::FULL/2 )
				dst[j] = src[j];
	}
}

void ButtonDialog::trackMouse( NimblePoint p ) {
    myButtonSelected = myButtonRect.contains(p);
}

void ButtonDialog::doMouseDown( NimblePoint p ) {
	trackMouse(p);
}

void ButtonDialog::doMouseMove( NimblePoint p ) {
	trackMouse(p);
}

Clickable::action ButtonDialog::doMouseUp( NimblePoint p ) {
    if( myButtonRect.contains(p) ) {
        onSelect();
    }
	return none;
}

//-----------------------------------------------------------------
// SliderDialog
//-----------------------------------------------------------------

static Sprite SliderKnob("SLIDER_KNOB");
static Sprite SliderKnobSelected("SLIDER_KNOB_SELECTED");

SliderDialog::SliderDialog( const char* resourceName ) :
    Dialog( resourceName ),
	myDrag(false),
	myNumberOfValues(-1),
	mySelectedSlider(-1)
{
	for( int k=0; k<maxSliders; ++k ) {
	    myMinValue[k] = 0;
		myMaxValue[k] = 1;
	}
}

void SliderDialog::buildFrom( const NimblePixMap& map ) {
	// Build background image
	Dialog::buildFrom( map );
	// Scan across middle looking for slots
	int n = 0;
	int h = map.height();
	int midy = h/2;
	for( int x=1; x<map.width() && n<maxSliders; ++x )
		if( map.alphaAt(x,midy)<NimbleColor::FULL/2 ) {
			// Found a slot
			mySlotX[n] = x;
			myValue[n] = myMinValue[n];
			if( n==0 ) {
				// Find extent of zeroth slot (rest are presumed to have same extent)
				NimbleRect r = FindTransparentBox(map,x,midy);
                mySlotTop=r.top;
				mySlotBottom=r.bottom;
			}
			++n;
		}
	myNumberOfValues = n;
}

void SliderDialog::doDrawOn( NimblePixMap& map ) {
	Dialog::doDrawOn(map);
	int knobHalfWidth = SliderKnob.width()/2;
	int knobHalfHeight = SliderKnob.height()/2;
	for( int k=0; k<myNumberOfValues; ++k ) {
		int knobX = mySlotX[k]; 
		int knobY =(mySlotBottom-mySlotTop)*(1-(myValue[k]-myMinValue[k])/(myMaxValue[k]-myMinValue[k]))+mySlotTop;
		(k==mySelectedSlider?SliderKnobSelected:SliderKnob).drawOn( map, knobX-knobHalfWidth, knobY-knobHalfHeight );
	}
}

void SliderDialog::trackMouse( NimblePoint p ) {
	int knobWidth = 40;
	int knobHeight = 10;
	for( int k=0; k<myNumberOfValues; ++k ) {
		int knobX = mySlotX[k]; 
		int knobY =(mySlotBottom-mySlotTop)*(1-(myValue[k]-myMinValue[k])/(myMaxValue[k]-myMinValue[k]))+mySlotTop;
		NimbleRect r( knobX-knobWidth/2, knobY-knobHeight/2, knobX+knobWidth/2, knobY+knobHeight/2 );
		if( r.contains(p) ) {
			mySelectedSlider=k;
			mySelectedPoint=p;
			return;
		}
	}
	mySelectedSlider = -1;
}

void SliderDialog::doMouseDown( NimblePoint p ) {
	trackMouse(p);
	if( mySelectedSlider>=0 ) 
		myDrag = true;
}

void SliderDialog::doMouseMove( NimblePoint p ) {
	if( myDrag ) {
		int k = mySelectedSlider;
	    int totalY = mySlotBottom-mySlotTop;
        int deltaY = mySlotBottom-(p.y);
	    float value = Max(myMinValue[k],Min(myMaxValue[k],myMinValue[k]+float(deltaY)/totalY*(myMaxValue[k]-myMinValue[k])));
		myValue[mySelectedSlider] = value;
		changeNotice(mySelectedSlider,value);
	} else {
		trackMouse(p);
	}
}

Clickable::action SliderDialog::doMouseUp( NimblePoint p ) {
	myDrag = false;
	if( mySelectedSlider>=0 ) {
	    mySelectedSlider = -1;
		return update;
	} else {
		return Dialog::doMouseUp(p);
	}
}

void SliderDialog::setValue( int whichSlider, float newValue ) {
	Assert( 0<=whichSlider && whichSlider<myNumberOfValues );
	Assert( myMinValue[whichSlider] <= newValue );
	Assert( newValue<=myMaxValue[whichSlider] );
    myValue[whichSlider] = newValue;
}

void SliderDialog::setLimits( int whichSlider, float min, float max ) {
	Assert(min<max);
	myMinValue[whichSlider]=min;
	myMaxValue[whichSlider]=max;
}

//-----------------------------------------------------------------
// Menu
//-----------------------------------------------------------------

static const short MarginH = 5;
static const short MarginV = 2;

static const char MenuCheckPrefix[] = {127,' ',0};

void Menu::append( item& i ) {
    *end = &i;
	end = &i.next;
}

void Menu::finishConstruction() {
	myTabWidth = myFont.width(myTab)+2*MarginH;
	myTabHeight = myFont.height()+2*MarginV;
	myWidth = 0;
	myShortcutWidth = 0;
	myHeight = myTabHeight;
	for( item* i=root; i; i=i->next ) {
	    myHeight += myTabHeight;
	    myWidth = Max( myWidth, short(myFont.width(i->text())) );
		if( i->shortcut() ) 
			myShortcutWidth = Max( myShortcutWidth, short(myFont.width(i->shortcut())) );
	}
	myCheckWidth = myFont.width(MenuCheckPrefix);
	myWidth += myCheckWidth + myFont.width("  ")+myShortcutWidth+2*MarginH;
}

void Menu::doDrawOn( NimblePixMap& map ) {
	int y = 0;
	int full = NimbleColor::FULL;
	NimblePixel black = map.pixel(NimbleColor(0,0,0));
	NimblePixel gray = map.pixel(NimbleColor(3*full/4,3*full/4,3*full/4));
	NimblePixMap buttonMap( map, NimbleRect(0,0,myTabWidth,myTabHeight));
	(mySelectedRow==0 ? ButtonSelected : ButtonBackground).drawOn(buttonMap);
	myFont.drawOn( map, MarginH, y+MarginV, myTab, black );
	y += myTabHeight;
	if( myState==tabbed ) {
		setClickableSize(myTabWidth,y);
	} else {
		NimblePixMap background( map,NimbleRect(0,y,myWidth,myHeight) );
		if( mySelectedRow==noRow||mySelectedRow==0 )
		    ButtonBackground.drawOn(background);
		else {
			int y1 = (mySelectedRow-1)*myTabHeight;
			int y2 = y1+myTabHeight;
			ButtonBackground.drawOn(background,0,y1);
			ButtonSelected.drawOn(background,y1,y2);
            ButtonBackground.drawOn(background,y2,background.height());
		}
		int row = 1;
		for( item* i=root; i; i=i->next ) {
			NimblePixel ink = i->isEnabled() ? black : gray;
			if( i->isChecked() )
				myFont.drawOn( map, MarginH, y+MarginV, MenuCheckPrefix, ink );
			int x = myFont.drawOn( map, MarginH+myCheckWidth, y+MarginV, i->text(), ink );
			if( i->shortcut() )
				x = myFont.drawOn( map, myWidth-MarginH-myShortcutWidth, y+MarginV, i->shortcut(), ink );
			Assert(x<=myWidth);
			y += myTabHeight;
			++row;
		}
	    setClickableSize(myWidth,y);
	}
}

void Menu::trackMouse( NimblePoint p, bool act ) {
	if( 0<=p.y && p.y<myHeight ) {
        int k = p.y/myTabHeight;
		if( k==0 ) {
			mySelectedRow = 0<=p.x && p.x<myTabWidth ? 0 : noRow;
		} else {
			mySelectedRow = k;
		}
		if( mySelectedRow>0 && act ) {
			item* i=root; 
			for(int n = mySelectedRow-1;n;--n) {
				// Following check should not be necessary in theory, but included to 
				// prevent crashes if there is an accounting error.
				if( !i ) return;
				if( n==0 ) break;
				i=i->next;
			}
			if( i->isEnabled() )
				i->onSelect();
		}
	} else 
		mySelectedRow = noRow;
}

void Menu::doMouseDown( NimblePoint p ) {
	switch( myState ) {
		case tabbed:
			trackMouse(p,false);
			myState = pulled;
			break;
		case pulled:
		case armed:
			trackMouse(p,true);
		    myState = tabbed;
			break;
	}
}

void Menu::doMouseMove( NimblePoint p ) {
	switch( myState ) {
		case tabbed:
			trackMouse(p,false);
			break;
		case pulled:
		case armed:	
			trackMouse(p,false);
			break;
	}
}

Clickable::action Menu::doMouseUp( NimblePoint p ) {
	switch( myState ) {
		case tabbed:
		    break;
		case pulled:
			if( 0<=p.y && p.y<myTabHeight )
				myState = armed;
			else {
				trackMouse(p,true);
				myState = tabbed;
			}
			break;
		case armed:
			trackMouse(p,true);
			myState = tabbed;
			break;
	}
	return hide;
}



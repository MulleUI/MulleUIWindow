#define _GNU_SOURCE

#import "import-private.h"
//
// Keyboard monitor demo — draws a keyboard layout and highlights pressed keys.
// Demonstrates keyDown:/keyUp: + becomeFirstResponder for keyboard input.
//
// This is the keyboard equivalent of main-gamepad-monitor.m
//

#define WINDOW_W    680.0
#define WINDOW_H    260.0
#define KEY_W       40.0
#define KEY_H       40.0
#define KEY_GAP     3.0
#define MARGIN_X    16.0
#define MARGIN_Y    16.0
#define NUM_KEYS    49


struct KeyDef
{
   UIEventKey   code;
   char         *label;
   CGFloat      x;
   CGFloat      y;
   CGFloat      w;
};


static struct KeyDef   keys[ NUM_KEYS] =
{
   // Row 0: number row
   { UIEventKey1,           "1",   0, 0, 1 },
   { UIEventKey2,           "2",   1, 0, 1 },
   { UIEventKey3,           "3",   2, 0, 1 },
   { UIEventKey4,           "4",   3, 0, 1 },
   { UIEventKey5,           "5",   4, 0, 1 },
   { UIEventKey6,           "6",   5, 0, 1 },
   { UIEventKey7,           "7",   6, 0, 1 },
   { UIEventKey8,           "8",   7, 0, 1 },
   { UIEventKey9,           "9",   8, 0, 1 },
   { UIEventKey0,           "0",   9, 0, 1 },
   { UIEventKeyMinus,       "-",  10, 0, 1 },
   { UIEventKeyEqual,       "=",  11, 0, 1 },

   // Row 1: QWERTY
   { UIEventKeyQ,           "Q",   0.5, 1, 1 },
   { UIEventKeyW,           "W",   1.5, 1, 1 },
   { UIEventKeyE,           "E",   2.5, 1, 1 },
   { UIEventKeyR,           "R",   3.5, 1, 1 },
   { UIEventKeyT,           "T",   4.5, 1, 1 },
   { UIEventKeyY,           "Y",   5.5, 1, 1 },
   { UIEventKeyU,           "U",   6.5, 1, 1 },
   { UIEventKeyI,           "I",   7.5, 1, 1 },
   { UIEventKeyO,           "O",   8.5, 1, 1 },
   { UIEventKeyP,           "P",   9.5, 1, 1 },
   { UIEventKeyLeftBracket, "[",  10.5, 1, 1 },
   { UIEventKeyRightBracket,"]",  11.5, 1, 1 },

   // Row 2: ASDF
   { UIEventKeyA,           "A",   0.75, 2, 1 },
   { UIEventKeyS,           "S",   1.75, 2, 1 },
   { UIEventKeyD,           "D",   2.75, 2, 1 },
   { UIEventKeyF,           "F",   3.75, 2, 1 },
   { UIEventKeyG,           "G",   4.75, 2, 1 },
   { UIEventKeyH,           "H",   5.75, 2, 1 },
   { UIEventKeyJ,           "J",   6.75, 2, 1 },
   { UIEventKeyK,           "K",   7.75, 2, 1 },
   { UIEventKeyL,           "L",   8.75, 2, 1 },
   { UIEventKeySemicolon,   ";",   9.75, 2, 1 },

   // Row 3: ZXCV
   { UIEventKeyZ,           "Z",   1.25, 3, 1 },
   { UIEventKeyX,           "X",   2.25, 3, 1 },
   { UIEventKeyC,           "C",   3.25, 3, 1 },
   { UIEventKeyV,           "V",   4.25, 3, 1 },
   { UIEventKeyB,           "B",   5.25, 3, 1 },
   { UIEventKeyN,           "N",   6.25, 3, 1 },
   { UIEventKeyM,           "M",   7.25, 3, 1 },

   // Row 4: space + arrows
   { UIEventKeySpace,       " ",   3.0,  4, 4 },
   { UIEventKeyLeft,        "<",   9.0,  4, 1 },
   { UIEventKeyDown,        "v",  10.0,  4, 1 },
   { UIEventKeyRight,       ">",  11.0,  4, 1 },
   { UIEventKeyUp,          "^",  10.0,  3, 1 },

   // Specials
   { UIEventKeyEscape,      "Es", 12.5, 0, 1 },
   { UIEventKeyEnter,       "Rt", 12.5, 2, 1 },
   { UIEventKeyTab,         "Tb", 12.5, 1, 1 },
};


// global key state, written by KeyboardView, read by drawKeyboard
static BOOL   s_pressed[ NUM_KEYS];


//
// KEYBOARD VIEW — sole purpose is to receive keyboard events.
// Must be first responder to get keyDown:/keyUp:.
//
@interface KeyboardView : UIView
@end


@implementation KeyboardView

- (BOOL) canBecomeFirstResponder
{
   return( YES);
}


static int   indexOfKey( UIEventKey code)
{
   int   i;

   for( i = 0; i < NUM_KEYS; i++)
      if( keys[ i].code == code)
         return( i);
   return( -1);
}


- (UIInputEvent *) keyDown:(UIKeyboardEvent *) event
{
   int   idx;

   idx = indexOfKey( [event key]);
   if( idx >= 0)
      s_pressed[ idx] = YES;
   return( nil);
}


- (UIInputEvent *) keyUp:(UIKeyboardEvent *) event
{
   int   idx;

   idx = indexOfKey( [event key]);
   if( idx >= 0)
      s_pressed[ idx] = NO;
   return( nil);
}

@end


static void   drawKeyboard( CGContext *context, CGRect canvas)
{
   struct KeyDef   *k;
   CGRect          rect;
   CGColor         color;
   CGColor         textColor;
   CGColor         strokeColor;
   CGFloat         x;
   CGFloat         y;
   CGFloat         w;
   int             i;

   strokeColor = CGColorMakeWithRGBA( 0.4, 0.4, 0.5, 1.0);

   [context useDefaultFont];

   for( i = 0; i < NUM_KEYS; i++)
   {
      k = &keys[ i];

      x = MARGIN_X + k->x * (KEY_W + KEY_GAP);
      y = MARGIN_Y + k->y * (KEY_H + KEY_GAP);
      w = k->w * KEY_W + (k->w - 1.0) * KEY_GAP;

      rect = CGRectMake( x, y, w, KEY_H);

      if( s_pressed[ i])
      {
         color     = CGColorMakeWithRGBA( 0.2, 0.85, 0.4, 1.0);
         textColor = CGColorMakeWithRGBA( 0.0, 0.0, 0.0, 1.0);
      }
      else
      {
         color     = CGColorMakeWithRGBA( 0.22, 0.22, 0.28, 1.0);
         textColor = CGColorMakeWithRGBA( 0.85, 0.85, 0.85, 1.0);
      }

      CGContextFillRoundedRectWithColor( context, rect, 4.0, color);
      CGContextStrokeRoundedRectWithColor( context, rect, 4.0, 1.0, strokeColor);

      CGContextFontSize( context, 14.0);
      CGContextCombinedTextAlignment( context, CGTextAlignCenter | CGTextAlignMiddle);
      CGContextTextColor( context, textColor);
      CGContextText( context, CGPointMake( x + w / 2.0, y + KEY_H / 2.0), k->label, 0);
   }
}


static UIWindowDisplayBits   display( UIPureWindow *window,
                                      id <UIGraphicsContext> context,
                                      struct CGFrameInfo *frameInfo,
                                      UIWindowDisplayBits displayBits)
{
   drawKeyboard( (CGContext *) context, CGFrameInfoGetContentRect( frameInfo));
   displayBits = UIWindowDefaultRenderViews( window, context, frameInfo, displayBits);
   return( displayBits);
}


int   main( int argc, char *argv[])
{
   UIWindow        *window;
   KeyboardView    *view;
   NSUInteger      styleMask;

   [UIApplication sharedInstance];

   styleMask = UIWindowStyleMaskDefault & ~UIWindowStyleRetained;
   window    = [UIWindow windowWithFrame:CGRectMake( 0.0, 0.0, WINDOW_W, WINDOW_H)
                         titleUTF8String:"Keyboard Monitor"
                               styleMask:styleMask];
   assert( window);

   [window setFrameCallback:display];
   [window setFrameRate:UIWindowFrameRateSynced];
   [window setBackgroundColor:CGColorMakeWithRGBA( 0.1, 0.1, 0.12, 1.0)];

   // Add an invisible view that captures keyboard events
   view = [[[KeyboardView alloc] initWithFrame:CGRectMake( 0, 0, WINDOW_W, WINDOW_H)] autorelease];
   [[window contentView] addSubview:view];
   [view becomeFirstResponder];

   return( UIApplicationRunWindow( window));
}

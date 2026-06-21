#define _GNU_SOURCE

#import "import-private.h"
//
// Keyboard polling demo — draws a keyboard layout and highlights pressed keys.
// Instead of keyDown:/keyUp: events handled by a UIView, this queries the
// OSWindow's cached keyboard state each frame (maintained from events,
// resynced via os_pressedKeys:count: on focus regain).
// Demonstrates pressedKeys:count: for game-style input.
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


static void   drawKeyboard( CGContext *context, CGRect canvas,
                            NSUInteger *pressedKeys, NSUInteger pressedCount)
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
   NSUInteger      j;
   BOOL            isPressed;

   strokeColor = CGColorMakeWithRGBA( 0.4, 0.4, 0.5, 1.0);

   [context useDefaultFont];

   for( i = 0; i < NUM_KEYS; i++)
   {
      k = &keys[ i];

      // check if this key is in the pressed array
      isPressed = NO;
      for( j = 0; j < pressedCount; j++)
      {
         if( pressedKeys[ j] == k->code)
         {
            isPressed = YES;
            break;
         }
      }

      x = MARGIN_X + k->x * (KEY_W + KEY_GAP);
      y = MARGIN_Y + k->y * (KEY_H + KEY_GAP);
      w = k->w * KEY_W + (k->w - 1.0) * KEY_GAP;

      rect = CGRectMake( x, y, w, KEY_H);

      if( isPressed)
      {
         color     = CGColorMakeWithRGBA( 0.85, 0.4, 0.2, 1.0);
         textColor = CGColorMakeWithRGBA( 1.0, 1.0, 1.0, 1.0);
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
      CGContextText( context, CGPointMake( x + w / 2.0, y + KEY_H / 2.0), k->label, (size_t) -1);
   }
}


static UIWindowDisplayBits   display( UIPureWindow *window,
                                      id <UIGraphicsContext> context,
                                      struct CGFrameInfo *frameInfo,
                                      UIWindowDisplayBits displayBits)
{
   NSUInteger   pressedKeys[ 32];
   NSUInteger   pressedCount;

   // query cached keyboard state (maintained from events, resynced on focus)
   pressedCount = [(id <UIOSWindow>) [context OSWindow] pressedKeys:pressedKeys
                                                              count:32];

   drawKeyboard( (CGContext *) context,
                 CGFrameInfoGetContentRect( frameInfo),
                 pressedKeys,
                 pressedCount);
   return( displayBits);
}


int   main( int argc, char *argv[])
{
   UIWindow     *window;
   NSUInteger   styleMask;

   [UIApplication sharedInstance];

   styleMask = UIWindowStyleMaskDefault & ~UIWindowStyleRetained;
   window    = [UIWindow windowWithFrame:CGRectMake( 0.0, 0.0, WINDOW_W, WINDOW_H)
                         titleUTF8String:"Keyboard Poll"
                               styleMask:styleMask];
   assert( window);

   [window setFrameCallback:display];
   [window setFrameRate:UIWindowFrameRateSynced];
   [window setBackgroundColor:CGColorMakeWithRGBA( 0.1, 0.1, 0.12, 1.0)];

   return( UIApplicationRunWindow( window));
}

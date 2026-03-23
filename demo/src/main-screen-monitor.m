#import "import.h"

struct ShapeAppearance
{
    CGColor  fillColor;
    CGColor  strokeColor;
    CGFloat  strokeWidth;
};
#define ShapeAppearanceData( fc, sc, sw) \
(struct ShapeAppearance)                 \
{                                        \
   .fillColor   = fc,                    \
   .strokeColor = sc,                    \
   .strokeWidth = sw                     \
}

static void  drawPathWithAppearance( struct CGContext *context,
                                        struct ShapeAppearance *appearance)
{
   if( ! CGColorIsTransparent( appearance->fillColor))
   {
      CGContextFillColor( context, appearance->fillColor);
      CGContextFill( context);
   }

   if( appearance->strokeWidth > 0.0)
   {
      CGContextStrokeColor( context, appearance->strokeColor);
      CGContextStrokeWidth( context, appearance->strokeWidth);
      CGContextStroke( context);
   }
}

struct TextAppearance
{
    CGColor      textColor;
    CGColor      textBackgroundColor;
};

#define TextAppearanceData( tc, tbc) \
(struct TextAppearance)              \
{                                    \
   .textColor = tc,                  \
   .textBackgroundColor = tbc        \
}
static void  textWithAppearance( struct CGContext *context,
                                    CGPoint point,
                                    char *text,
                                    struct TextAppearance *appearance)
{
   CGContextTextColor( context, appearance->textColor);
   CGContextTextBackgroundColor( context, appearance->textBackgroundColor);
   CGContextText( context, point, text, (size_t) -1);
}
struct MonitorAppearance
{
    struct ShapeAppearance   bezel;
    struct ShapeAppearance   screen;
    struct ShapeAppearance   stand;
    struct ShapeAppearance   circle;
    struct TextAppearance    digit;
    struct TextAppearance    info;
};
static struct MonitorAppearance  appearance =
{
    .bezel  =
    {
      .fillColor   = CGColorDataTransparent,
      .strokeColor = CGColorDataBlack,
      .strokeWidth = 3.0f
    },
    .screen = ShapeAppearanceData( CGColorDataBlack,       CGColorDataTransparent, 0.0),
    .stand  = ShapeAppearanceData( CGColorDataGray,        CGColorDataBlack, 3.0),
    .circle = ShapeAppearanceData( CGColorDataWhiteSmoke,  CGColorDataTransparent, 0.0),
    .digit  = TextAppearanceData( CGColorDataGray, CGColorDataWhiteSmoke),
    .info   = TextAppearanceData( CGColorDataWhite, CGColorDataBlack)
};
//
// the monitor draw function was coded by Cody/Sourcegraph/Claude Sonnet 3.5
// it's doing a pretty good job.
//
static void drawMonitor( struct CGContext *context,
                        CGRect frame,
                        NSUInteger index,
                        id <UIScreen> screen,
                        struct MonitorAppearance *appearance)
{
  CGRect screenRect;
  CGRect bezelRect;
  CGRect standRect;
  CGRect infoRect;
  CGFloat cornerRadius = 10.0;
  CGRect circleBounds;
  CGSize actualScreenSize = [screen frame].size;
  CGFloat aspectRatio = actualScreenSize.width / actualScreenSize.height;

  // Calculate available space for the screen (subtracting space for bezel and stand)
  CGFloat availableWidth = CGRectGetWidth(frame) * 0.8;
  CGFloat availableHeight = CGRectGetHeight(frame) * 0.6;

  // Calculate screen dimensions while maintaining aspect ratio
  if (availableWidth / availableHeight > aspectRatio) {
      screenRect.size.height = availableHeight;
      screenRect.size.width = screenRect.size.height * aspectRatio;
  } else {
      screenRect.size.width = availableWidth;
      screenRect.size.height = screenRect.size.width / aspectRatio;
  }

  screenRect.origin.x = CGRectGetMidX(frame) - screenRect.size.width / 2;
  screenRect.origin.y = CGRectGetMidY(frame) - screenRect.size.height / 2;

  // Draw outer rounded rectangle (monitor frame)
  CGContextBeginPath( context);
  bezelRect = CGRectInset(screenRect, -10, -10);
  CGContextRoundedRect( context, bezelRect, cornerRadius);
  drawPathWithAppearance(context, &appearance->bezel);

  // Draw inner rectangle (screen)
  CGContextBeginPath( context);
  CGContextRect( context, screenRect);
  drawPathWithAppearance(context, &appearance->screen);

  // Draw stand using CGRectGetMaxY(bezelRect) for precise connection
  CGFloat baseWidth = screenRect.size.width * 0.4;
  CGFloat baseHeight = screenRect.size.height * 0.05;
  CGFloat baseX = CGRectGetMidX(frame) - baseWidth / 2;
  CGFloat baseY = CGRectGetMaxY(bezelRect) + screenRect.size.height * 0.075;
  CGFloat neckWidth = screenRect.size.width * 0.05;
  CGFloat neckX = CGRectGetMidX(frame) - neckWidth / 2;
  CGFloat neckTopY = CGRectGetMaxY(bezelRect);

  CGContextBeginPath( context);
  CGContextMoveTo( context, CGPointMake(baseX, baseY + baseHeight));
  CGContextLineTo( context, CGPointMake(baseX + baseWidth, baseY + baseHeight));
  CGContextLineTo( context, CGPointMake(baseX + baseWidth, baseY));
  CGContextLineTo( context, CGPointMake(neckX + neckWidth, baseY));
  CGContextLineTo( context, CGPointMake(neckX + neckWidth, neckTopY));
  CGContextLineTo( context, CGPointMake(neckX, neckTopY));
  CGContextLineTo( context, CGPointMake(neckX, baseY));
  CGContextLineTo( context, CGPointMake(baseX, baseY));
  CGContextClosePath( context);
  drawPathWithAppearance(context, &appearance->stand);   CGContextSave( context);

   // Set up clipping to screenFrame
   CGContextIntersectScissor( context, screenRect);
   {
  // Draw big circle
  CGFloat radius = fmin(CGRectGetWidth(screenRect), CGRectGetHeight(screenRect)) * 0.3;
  circleBounds = CGRectInset( screenRect, radius / 2, radius / 2);
  CGPoint center = CGRectGetCenter(circleBounds);
  radius = fmin(CGRectGetWidth(circleBounds), CGRectGetHeight(circleBounds)) * 0.3;

  CGContextBeginPath( context);
  CGContextCircle( context, CACircleMakeWithCenterAndRadius( center, radius));
  drawPathWithAppearance( context, &appearance->circle);

  // Draw index number (assuming index 1 for this example)
  CGContextFontSize( context, radius);
  CGContextCombinedTextAlignment( context, CGTextAlignCenter | CGTextAlignMiddle);
  mulle_buffer_do( buffer)
  {
     mulle_buffer_sprintf( buffer, "%tu", index + 1);
     textWithAppearance(context, center, mulle_buffer_get_string( buffer), &appearance->digit);
  }

  infoRect = CGRectInset( screenRect, 10, 10);
  CGContextFontSize( context, 14);
  CGContextCombinedTextAlignment( context, CGTextAlignBottom | CGTextAlignLeft);
  CGPoint namePoint = CGRectGetCornerPoint( infoRect, CADirectionBottom|CADirectionLeft);
  textWithAppearance(context, namePoint, [screen nameUTF8String], &appearance->info);

  CGContextCombinedTextAlignment( context, CGTextAlignTop | CGTextAlignRight);
  CGPoint sizePoint = CGRectGetCornerPoint( infoRect, CADirectionTop|CADirectionRight);
  textWithAppearance(context, sizePoint, CGRectUTF8String( [screen frame]), &appearance->info);
   }
   CGContextRestore( context);
}
static void  drawStuff( CALayer *layer, CGContext *context)
{
   CGRect              canvas;
   id <UIScreen>       screen;
   NSUInteger          i, n;
   CGRect              rects[ 9]; // h w
   CGRect              *p_rects;

   canvas = [layer canvas];

   [context useDefaultFont];

   // divide screen into equal parts
   n = [UIApp numberOfScreens];
   switch( n)
   {
   case 1 :
      p_rects = (CGRect *) &canvas;
      break;

   case 2 :
      CGRectPartitionIntoRows( canvas, 20, 2, rects);
      p_rects = (CGRect *) rects;
      break;

   case 3 :
   case 4 :
      CGRectPartition2x2( canvas, CGSizeMake( 20, 20), (CGRect *) rects);
      p_rects = (CGRect *) rects;
      break;

   case 5 :
   case 6 :
   case 7 :
   case 8 :
   default :
         n = n >= 9 ? 9 : n;
         CGRectPartition3x3( canvas, CGSizeMake( 20, 20), (CGRect *) rects);
         p_rects = (CGRect *) rects;
         break;
   }

   for( i = 0; i < n; i++)
   {
      screen = [UIApp screenAtIndex:i];
      drawMonitor(context, *p_rects++, i, screen, &appearance);
   }
}

@interface ScreenMonitorView : UIView
@end
@implementation ScreenMonitorView

- (instancetype) initWithLayer:(id <UILayer>)layer
                         frame:(CGRect) frame
{
   self = [super initWithLayer:layer
                         frame:frame];
   [self setAutoresizingMask:UIViewAutoresizingFlexibleSize];
   [self setBackgroundColor:CGColorMakeAliceBlue()];
   [(CGGraphicsLayer *) layer  setDrawCallback:(CGGraphicsLayerDrawCallback_t *) drawStuff];
   return( self);
}

//
// Only the view (root) of the UIWindow gets events, that do not have a
// mousePosition, so we made our view the root view. Otherwise we would
// have needed to subclass UIWindow
//
- (UIEvent *) handleEvent:(UIEvent *)event
{
   if( [event eventType] == UIEventTypeScreen)
   {
      [self setNeedsDisplay];
      return( event);  // don't snarf let it propagate
   }
   return( event);
}

@end
//
// could also make UIWindow with NoView and then setView: (or create as
// is and setView:) many different ways to skin that cat
//
@implementation UIWindow( RootViewClass)

+ (Class) viewClass
{
   return( [ScreenMonitorView class]);
}

@end
int   main( int argc, char *argv[])
{
   UIWindow        *window;
   UIApplication   *app;
   NSUInteger      styleMask;
   
   app = [UIApplication sharedInstance];
   {
      // demo runs single threaded
      // styleMask = UIWindowStyleMaskDefault & ~(UIWindowStyleRetained|UIWindowStylePlanes);
      // demo runs multi threaded
      styleMask = UIWindowStyleMaskDefault & ~(UIWindowStylePlanes);
      window    = [UIWindow windowWithFrame:CGRectMake( 0.0, 0.0, 800.0, 800.0)
                            titleUTF8String:"Demo"
                                  styleMask:styleMask];

      assert( window);

      [app addWindow:window];
   }
   return( [app runApp]);
}

//
//                           ,╓≤æKª╨╙╙▓█D"╙╙╙*╨¥W▄╓,
//                      ╓▄ª╙└╧▓        █           ⁿ▓▓ª╦w
//                  ╓#╜^*█⌐   `╕       █           ╓▌    `╙%w
//               ╓ΦΓ      █    ╙⌐     ,█,,,Φ      ╓▌         ╙¥▄
//            ,▄▀ █▄       █µ,╓╝,╓≤╗≡≡ª╨╨╨¥≡∞╗w╓,ª█,  ,       ]▄▀V,
//          ,Φ└   ║"▀▄     ,▄▀╨"                 "╙¥▓▓       ▄▀  º▄¥,
//        ,#▌Φ▓▄╓  Φ `█Q▄M╙                           ╙¥▄ ,▄▀ ╙▄⌐`  `Φ
//       ▄▀   `V,"▀▀¼╓╩└                                 ╙¥▓╗ ,       ╙▄
//      Φ       `¥═▄▀                            ╒          ▀▄          ▓
//    .▓         ╓▓]V▄H       ▓                 ,Å            ▀,         ▀
//    █      ,-ª▓╛  `██▀½      "▄  ,╓╓╓╓;╓▄▄▄▄╗▄█,             ╙▄         ▀
//   █  `██▄   ▓. - Φ█═.~     ,≤█▄▀-      `   █└"▀▀▀▀▄╓╓╓╓       ▌    ██▄, █
//  ║⌐  " ▀   ▓╨⌐   }▀`      ,█  `           █      .█▀▄▄███▄     ▌  ` ▀    ▌
//  ▌        ▐M A   '┴      ▌                ▀        ╙█▌████▌    ╙▄        ║⌐
// ║⌐        █⌐'║▄ Γr2«    ║▀                 ▄▄▄      ╙▌▄███      █         ▌
// █]     ,▄▐H  ██████═ª  ╓` ▄█▀▀▀▀█▄        ████     ╓███` `╙╙║█  ▐H        █
// █ "% ,▄▀ ║░╠K█═╣███^   ╛╓█▀      ▐█         ,╓╓═ª╙└   █      ╙█▄▐▌▓######▌╫
// █║▄▄▄█▄▄▄║H:  "╙▀███▄╓▄,█▌╓▄,,▄∩  ██p$ΦΦ▀▀▀▀▀ΦΦΦR≡≥▄╓ ║▄       ╙j▌` ▄▀╙╗ `╫
// █"      ╙▐H-═M ▄███████¥█H "^╙    '█, ,«^``     `     ║▌        ▐M▄▀    "Φ█
// ║        !█▄▄████≤═^`╓█ █▌╓▀╦▄▀█   ╙█⌐               ╓█▌        ▓ `       █
//  ▌      ,▄██╫██ ▄█═╜" █▌▐█╣Hj⌐ █    █▌╙¥w,           ██▄       ╓▌        ▐M
//  ╢"▄▄#▀▀╙╟█Ü███▀`▀█  ║██J█▄▌jH █    ██    ╙▀W▄;    ,██  `╙w,   █▄     ,╓ █
//   █╙     ▐███▌▀█w ▀█ ╠██████j▌║█▌   ▀██▄       `╙▓██▀w,     ╙╗█'`"▀█▀╙"`║`
//   ╙▌     Φ████████▄██ ███████████    ═██▀W▄,   ╓█▀└         ╓▀ "    ╙▄ ╓▀
//    ╙▄     ╙▀███╙█▄▐██▄,╙▀█████▄▀▄▀▄   ,█M╗ ▀▄██▀╙""*ⁿ═─≈-,,▄▌,        ▄▀
//     `▌╙µ,▄Φ▀x███▄██████████▀V███▀╙└ ,▄#▌████▀`"*«,      .█▀▄▀▄,      ▄╛
//       ▀Ö█  ;▓████████▄▄█▀▄╙W "V▄██▀▀│▄███▀└ ▀╦     "*═╥▄▀ ║,  ║▀▄  ,▓
//        ╙W▀ '█████╨▀▀█████████   "▀▀████└      ╙▄   ,▄▀'   `▀▀╣H ▐▀▄▀
//          ╙▄  ▀▀Γ╓▌  ▄▀ⁿ`╙▀███      ██▌         ╓█R▀▄A█        ▀▀▄▀
//            ╙W,Φ╙  ║█        ▄╙╙ª%≡╦██≤≤╗╗≡≡╜▀▀   ╣▌   █╕     ,▄▀
//              `▀▄M█┘        ║▀▌   ╫"    *Φ▄  █       Φ` ▀▌, ▄M╙
//                 "▀╦,       M ╙▌  ▀       `█W▐▌       wæQ▄▀╙
//                     ╙▀W╥,╓╣   ╙█║        ╫M  █    ,╓▄╝╙`
//                          ╙╙▀%▄▄▄▌,≤▄_▄≡,▐▓▓▄▄#ª▀"`


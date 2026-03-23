#import "import.h"
#ifndef M_PI
# define M_PI 3.14159265358979323846
#endif
static void   drawColorwheel(CGContext *context, float x, float y, float w, float h, NSUInteger frameNumber)
{
   int i;
   float r0, r1, ax,ay, bx,by, cx,cy, aeps, r;
   float fummel = fmod( frameNumber / 100.0, M_PI * 2.0) == 0.0 ? 1.0 : fmod( frameNumber / 100.0, M_PI * 2.0);
   float hue = sinf( fummel * 0.12);
   float rot;
   CGPaint paint;

   // stolen from a demo and stupedified

   // RING
   CGContextSave( context);
   {
      cx = x + w*0.5f;
      cy = y + h*0.5f;
      r1 = (w < h ? w : h) * 0.5f - 5.0f;
      r0 = r1 - 20.0f;
      aeps = 0.5f / r1; // half a pixel arc length in radians (2pi cancels out).

      CGContextTranslate( context, CGPointMake(cx, cy));
      rot = -fummel;
      CGContextRotate( context, rot);
      CGContextTranslate( context, CGPointMake(-cx, -cy));

      for (i = 0; i < 6; i++) {
         float a0 = (float)i / 6.0f * M_PI * 2.0f - aeps;
         float a1 = (float)(i+1.0f) / 6.0f * M_PI * 2.0f + aeps;
         CGContextBeginPath( context);
         CGContextArc( context, cx,cy, r0, a0, a1, CGPathFillStyleSolid);
         CGContextArc( context, cx,cy, r1, a1, a0, CGPathFillStyleHole);
         CGContextClosePath( context);
         ax = cx + cosf(a0) * (r0+r1)*0.5f;
         ay = cy + sinf(a0) * (r0+r1)*0.5f;
         bx = cx + cosf(a1) * (r0+r1)*0.5f;
         by = cy + sinf(a1) * (r0+r1)*0.5f;
         paint = CGContextSetFillLinearGradient( context, ax,ay, bx,by, CGColorMakeWithHSLA(a0/(M_PI*2),1.0f,0.55f,255), CGColorMakeWithHSLA(a1/(M_PI*2),1.0f,0.55f,255));
         CGContextFillPaint( context, paint);
         CGContextFill( context);
      }

      CGContextBeginPath( context);
      CGContextCircle( context, CACircleMakeWithCenterAndRadius( CGPointMake(cx, cy), r0-0.5f));
      CGContextCircle( context, CACircleMakeWithCenterAndRadius( CGPointMake(cx, cy), r1+0.5f));
      CGContextStrokeColor( context, CGColorMakeWithRGBABytes(0,0,0,64));
      CGContextStrokeWidth( context, 1.0f);
      CGContextStroke( context);
   }
   CGContextRestore( context);

   // TRIANGLE
   CGContextSave( context);
   {
      CGContextTranslate( context, CGPointMake(cx, cy));
      rot = fummel;
      CGContextRotate( context, rot);

      r = r0 - 6;
      ax = cosf(120.0f/180.0f*M_PI) * r;
      ay = sinf(120.0f/180.0f*M_PI) * r;
      bx = cosf(-120.0f/180.0f*M_PI) * r;
      by = sinf(-120.0f/180.0f*M_PI) * r;
      CGContextBeginPath( context);
      CGContextMoveTo( context, CGPointMake(r, 0));
      CGContextLineTo( context, CGPointMake(ax, ay));
      CGContextLineTo( context, CGPointMake(bx, by));
      CGContextClosePath( context);
      paint = CGContextSetFillLinearGradient( context, r,0, ax,ay, CGColorMakeWithHSLA(hue,1.0f,0.5f,255), CGColorMakeWithRGBABytes(255,255,255,255));

      CGContextFillPaint( context, paint);
      CGContextFill( context);
      paint = CGContextSetFillLinearGradient( context, (r+ax)*0.5f,(0+ay)*0.5f, bx,by, CGColorMakeWithRGBABytes(0,0,0,0), CGColorMakeWithRGBABytes(0,0,0,255));
      CGContextFillPaint( context, paint);
      CGContextFill( context);
      CGContextStrokeColor( context, CGColorMakeWithRGBABytes(0,0,0,64));
      CGContextStroke( context);
   }
   CGContextRestore( context);
}
static void  drawStuff( CALayer *layer, CGContext *context)
{
   CGFloat   diameter;
   CGRect    canvas;
   CGRect    rect;
   CGPoint   a;
   CGPoint   b;

   canvas      = [layer canvas];
   rect        = UIEdgeInsetsInsetRect( canvas, UIEdgeInsetsMake( 50, 50, 50, 50));
   diameter    = CGFloatMinimum( CGRectGetWidth( rect), CGRectGetHeight( rect));
   rect.origin = CGSizeGetCenterInRect( CGSizeMake( diameter, diameter), rect);
   rect.size   = CGSizeMake( diameter, diameter);

   drawColorwheel( context,
                   rect.origin.x,
                   rect.origin.y,
                   diameter,
                   diameter,
                   [context numberOfFrames]);
}
static void   setupSceneInWindow( UIWindow *window)
{
   UIView   *view;
   CGRect   frame;
   UIView   *contentPlane;

   contentPlane = [window contentView];

   frame = [contentPlane contentRect];
   frame = UIEdgeInsetsInsetRect( frame, UIEdgeInsetsMake( 40, 40, 40, 40));

   view  = [UIView viewWithFrame:frame];
   [view setBackgroundColor:CGColorMakeWithRGBA( 0.0, 0.0, 0.0, 1.0)];
   [(CGGraphicsLayer *) [view layer] setDrawCallback:drawStuff];
   [contentPlane addSubview:view];
}
int   main( int argc, char *argv[])
{
   UIWindow        *window[ 2];
   UIApplication   *app;
   BOOL            closed[ 2];

   //
   // MEMO: the framerate for windows in one-thread scenario is additive
   //       the app should probably handle that
   //
   app = [UIApplication sharedInstance];
   {
      window[ 0] = [UIWindow windowWithFrame:CGRectMake( 0.0, 0.0, 400.0, 400.0)];
      [window[ 0] setFrameRateHz:30.0];
      [window[ 0] setBackgroundColor:CGColorMakeWithRGBA( 1.0, 0.0, 0.0, 1.0)];
      setupSceneInWindow( window[ 0]);
      [app addWindow:window[ 0]];
      window[ 1] = [UIWindow windowWithFrame:CGRectMake( 400.0, 0.0, 400.0, 400.0)];
      [window[ 0] setFrameRateHz:60.0];
      [window[ 1] setBackgroundColor:CGColorMakeWithRGBA( 0.0, 1.0, 0.0, 1.0)];
      setupSceneInWindow( window[ 1]);
      [app addWindow:window[ 1]];

      // app should handle this...
      closed[ 0] = NO;
      closed[ 1] = NO;
      while( ! closed[ 0] && ! closed[ 1])
      {
         if( ! closed[ 0])
         {
            closed[ 0] = [window[ 0] processOneFrame];
            if( closed[ 0])
               fprintf( stderr, "0 closed\n");
         }
         if( ! closed[ 1])
         {
            closed[ 1] = [window[ 1] processOneFrame];
            if( closed[ 1])
               fprintf( stderr, "1 closed\n");
         }
      }
   }
   return( [app terminate]);
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


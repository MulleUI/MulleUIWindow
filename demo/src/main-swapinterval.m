#define _GNU_SOURCE
#ifndef M_PI
# define M_PI 3.14159265358979323846
#endif

#import "import.h"

#include <stdio.h>
#include <time.h>
static void   drawColorwheel(CGContext *context, float x, float y, float w, float h, NSUInteger frameNumber)
{
   int i;
   float r0, r1, ax,ay, bx,by, cx,cy, aeps, r;
   float fummel = fmod( frameNumber / 100.0, M_PI * 2.0) == 0.0 ? 1.0 : fmod( frameNumber / 100.0, M_PI * 2.0);
   float hue = sinf( fummel * 0.12);
   float rot;

   // stolen from a demo and stupidified

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
         CGContextArc( context, CACircleMakeWithCenterAndRadius( CGPointMake(cx, cy), r0), CARadiansToAngle( a0), a1 - a0);
         CGContextArc( context, CACircleMakeWithCenterAndRadius( CGPointMake(cx, cy), r1), CARadiansToAngle( a1), a0 - a1);
         CGContextClosePath( context);
         ax = cx + cosf(a0) * (r0+r1)*0.5f;
         ay = cy + sinf(a0) * (r0+r1)*0.5f;
         bx = cx + cosf(a1) * (r0+r1)*0.5f;
         by = cy + sinf(a1) * (r0+r1)*0.5f;
         CGContextSetFillLinearGradient( context, CGPointMake(ax, ay), CGPointMake(bx, by), CGColorMakeWithHSLA(a0/(M_PI*2),1.0f,0.55f,1.0f), CGColorMakeWithHSLA(a1/(M_PI*2),1.0f,0.55f,1.0f));
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
      CGContextSetFillLinearGradient( context, CGPointMake(r, 0), CGPointMake(ax, ay), CGColorMakeWithHSLA(hue,1.0f,0.5f,1.0f), CGColorMakeWithRGBA(1,1,1,1));
      CGContextFill( context);
      CGContextSetFillLinearGradient( context, CGPointMake((r+ax)*0.5f, (0+ay)*0.5f), CGPointMake(bx, by), CGColorMakeWithRGBA(0,0,0,0), CGColorMakeWithRGBA(0,0,0,1));
      CGContextFill( context);
      CGContextStrokeColor( context, CGColorMakeWithRGBABytes(0,0,0,64));
      CGContextStroke( context);
   }
   CGContextRestore( context);
}
static BOOL   drawStuff( CGGraphicsLayer *layer, CGContext *_context)
{
   CGContext  *context = _context;
   CGFloat    diameter;
   CGRect     canvas;
   CGRect     rect;

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

#if 0
   {
      struct timespec         sleep;

      sleep.tv_sec  = 0.0;
      sleep.tv_nsec = 10000 * (rand() % 1000);
      nanosleep( &sleep, NULL);

   }
#endif
   return( YES);
}
static void   setupSceneInView( UIView *contentPlane)
{
   UIView   *view;
   CGRect   frame;

   frame = [contentPlane contentRect];
   frame = UIEdgeInsetsInsetRect( frame, UIEdgeInsetsMake( 40, 40, 40, 40));

   view  = [[[UIView alloc] initWithFrame:frame] autorelease];
   [view setBackgroundColor:CGColorMakeWithRGBA( 0.0, 0.0, 0.0, 1.0)];
   [(CGGraphicsLayer *) [view layer] setDrawCallback:drawStuff];
   [contentPlane addSubview:view];
}
int   main( int argc, char *argv[])
{
   UIWindow        *window;
   UIApplication   *app;
   MulleUIPerf     *perf;
   NSUInteger      swapInterval;

   swapInterval = 0;
   if( argc > 1)
      swapInterval = atoi( argv[ 1]);

   app = [UIApplication sharedInstance];
   {
      window = [UIWindow windowWithFrame:CGRectMake( 0.0, 0.0, 800.0, 600.0)];
      assert( window);

      [window setBackgroundColor:CGColorMakeWithRGBA( 1.0, 1.0, 1.0, 1.0)];

      [window setFrameRate:UIWindowFrameRateSynced];
      [window setSwapInterval:swapInterval];
      setupSceneInView( [window contentView]);

      perf = [MulleUIPerf instance];
      [window setFrameDelegate:perf];

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


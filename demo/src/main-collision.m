#import "import.h"

#include <math.h>

#define NUM_BALLS    3
#define RADIUS       60.0
#define WINDOW_W     800.0
#define WINDOW_H     600.0


//
// The layer does the drawing and keeps the visual properties of the view
//
@interface BallLayer : CGGraphicsLayer

@property( assign) CGColor   color;

@end


@interface BallView : UIView

@property( assign) CGVector   velocity;
@property( assign, getter=isTrapped) BOOL       trapped;

- (instancetype) initWithColor:(CGColor) color
                      velocity:(CGVector) velocity
                      position:(CGPoint) position;

@end


//
// With MulleAutolockingObjectProtocols, this will work with
// UIWindowStyleMaskDefault and its use of multi-threaded windows.
// Otherwise you either have to set Game up in the window thread or use
// acquire/release methods
//
@interface Game : MulleObject < MulleAutolockingObjectProtocols>
{
   BallView   *_balls[ NUM_BALLS];
   UIWindow   *_window;
}

- (instancetype) initWithWindow:(UIWindow *) window;
- (void) moveBalls;
- (void) collideBalls;
- (BallView *) ballAtIndex:(int) i;

@end



@implementation Game

//
// The window frame render callback. We do our game loop in here, and then
// because we use UIViews, we call UIWindow to actually layout,
// animate and render them.
//
static UIWindowDisplayBits   display( UIPureWindow *window,
                                      id <UIGraphicsContext> context,
                                      struct CGFrameInfo *frameInfo,
                                      UIWindowDisplayBits displayBits)
{
   UIWindow   *uiWindow = MULLE_OBJC_CLASS_CAST_OR_NIL( UIWindow, window);
   Game       *game;

   game = [window userInfo];
   [game moveBalls];
   [uiWindow invalidateQuadTree];
   [game collideBalls];

//   displayBits |= UIWindowDisplayNeedsLayout;
//   displayBits |= UIWindowDisplayNeedsAnimation;
   displayBits |= UIWindowDisplayNeedsRedraw;
   displayBits |= UIWindowDisplayNeedsMouseEvent;

   displayBits = UIWindowDefaultRenderViews( window, context, frameInfo, displayBits);

   // for our trackins areas to update if mouse is still but circles move
   // below pointer

   return( displayBits);
}



- (void) setupInView:(UIView *) view
{
   UITrackingArea  *area;
   NSUInteger      i;

   static struct { CGPoint pos; CGVector vel; CGColor color; } init[ NUM_BALLS] =
   {
      { { 200, 300 }, { 6.0,  4.0 }, CGColorDataWithRGBA( 1.0, 0.2, 0.2, 0.6) },
      { { 400, 200 }, { -4.0, 6.0 }, CGColorDataWithRGBA( 0.2, 1.0, 0.2, 0.6) },
      { { 600, 400 }, { 4.0, -5.0 }, CGColorDataWithRGBA( 0.3, 0.3, 1.0, 0.6) }
   };


   for( i = 0; i < NUM_BALLS; i++)
   {
      _balls[i] = [[BallView alloc] initWithColor:init[i].color
                                         velocity:init[i].vel
                                         position:init[i].pos];

      // set up tracking areas for collision detection
      area = [UITrackingArea trackingAreaWithRect:[_balls[i] contentRect]];
      [area setAutoresizingMask:UIViewAutoresizingScaleToFill];
      [area setUserInfo:_balls[i]];
      [_balls[i] addTrackingArea:area];

      [view addSubview:_balls[i]];
   }
}



- (instancetype) initWithWindow:(UIWindow *) window
{
   UIView       *contentView;
   CGGradient   *gradient;

   self = [super init];
   if( self)
   {
      _window     = window;

      [window setFrameRateHz:60.0];
      [window setUserInfo:self];
      [window setFrameCallback:display];
      contentView = [window contentView];
      gradient    = [CGGradient gradientWithStartColor:CGColorMakeWithRGBA( 0.25, 0.25, 0.35, 1.0)
                                                             endColor:CGColorMakeWithRGBA( 0.05, 0.05, 0.1, 1.0)];
      [contentView setBackgroundPaint:gradient];

      [self setupInView:contentView];
   }
   return( self);
}



- (void) dealloc
{
   int   i;

   for( i = 0; i < NUM_BALLS; i++)
      [_balls[i] release];
   [super dealloc];
}


- (BallView *) ballAtIndex:(int) i
{
   return( _balls[i]);
}


- (CGPoint) ballCenter:(int) i
{
   CGRect   frame;

   frame = [_balls[i] frame];
   return( CGPointMake( CGRectGetMidX( frame), CGRectGetMidY( frame)));
}


- (void) moveBalls
{
   int        i;
   CGPoint    pos;
   CGVector   vel;
   CGRect     frame;

   for( i = 0; i < NUM_BALLS; i++)
   {
      if( [_balls[i] isTrapped])
         continue;

      vel = [_balls[i] velocity];

      pos = [self ballCenter:i];
      pos.x += vel.dx;
      pos.y += vel.dy;

      if( pos.x - RADIUS < 0)
      {
         pos.x  = RADIUS;
         vel.dx = -vel.dx;
      }
      if( pos.x + RADIUS > WINDOW_W)
      {
         pos.x  = WINDOW_W - RADIUS;
         vel.dx = -vel.dx;
      }
      if( pos.y - RADIUS < 0)
      {
         pos.y  = RADIUS;
         vel.dy = -vel.dy;
      }
      if( pos.y + RADIUS > WINDOW_H)
      {
         pos.y  = WINDOW_H - RADIUS;
         vel.dy = -vel.dy;
      }

      [_balls[i] setVelocity:vel];

      frame = CGRectMake( pos.x - RADIUS, pos.y - RADIUS,
                          RADIUS * 2, RADIUS * 2);
      [_balls[i] setFrame:frame];
   }
}


- (void) collideBalls
{
   UITrackingArea   *hits[NUM_BALLS];
   NSUInteger       n;
   CACircle         circleI;
   CACircle         circleK;
   CGVector         normal;
   CGVector         velI;
   CGVector         velK;
   CGFloat          overlap;
   CGFloat          dvn;
   BallView         *other;
   int              i;
   int              j;

   for( i = 0; i < NUM_BALLS; i++)
   {
      n = [_window getTrackingAreasIntersectingRect:[_balls[i] frame]
                                             areas:hits
                                          maxAreas:NUM_BALLS];

      for( j = 0; j < n && j < NUM_BALLS; j++)
      {
         other = [hits[j] userInfo];
         if( ! other || other <= _balls[i])
            continue;

         circleI = CACircleMakeWithCenterAndRadius( [self ballCenter:i], RADIUS);
         circleK = CACircleMakeWithCenterAndRadius( CGRectGetCenterPoint( [other frame]), RADIUS);

         overlap = CACircleOverlapWithCircle( circleI, circleK);
         if( overlap <= 0.0)
            continue;

         normal = CACircleCollisionNormal( circleI, circleK);

         velI = [_balls[i] velocity];
         velK = [other velocity];

         dvn = (velI.dx - velK.dx) * normal.dx
             + (velI.dy - velK.dy) * normal.dy;

         if( dvn > 0)
         {
            velI.dx -= dvn * normal.dx;
            velI.dy -= dvn * normal.dy;
            velK.dx += dvn * normal.dx;
            velK.dy += dvn * normal.dy;
            [_balls[i] setVelocity:velI];
            [other setVelocity:velK];
         }

         overlap /= 2.0;
         [_balls[i] setFrame:CGRectMake( circleI.center.x - overlap * normal.dx - RADIUS,
                                         circleI.center.y - overlap * normal.dy - RADIUS,
                                         RADIUS * 2, RADIUS * 2)];
         [other setFrame:CGRectMake( circleK.center.x + overlap * normal.dx - RADIUS,
                                     circleK.center.y + overlap * normal.dy - RADIUS,
                                     RADIUS * 2, RADIUS * 2)];
      }
   }
}

@end


@implementation BallLayer

- (BOOL) drawInContext:(CGContext *) context
{
   CGRect     canvas;

   canvas = [self canvas];
   CGContextGlobalCompositeOperation( context, CGCompositeOperationSourceOver);
   CGContextFillCircleWithColor( context,
                                 CACircleMakeWithCenterAndRadius(
                                    CGPointMake( canvas.size.width / 2.0,
                                                 canvas.size.height / 2.0),
                                    RADIUS),
                                 [self color]);
   return( YES);
}

@end



@implementation BallView

+ (Class) layerClass
{
   return( [BallLayer class]);
}


- (instancetype) initWithColor:(CGColor) color
                      velocity:(CGVector) velocity
                      position:(CGPoint) position
{
   CGRect      frame;
   BallLayer   *layer;

   frame = CGRectMake( position.x - RADIUS, position.y - RADIUS,
                       RADIUS * 2, RADIUS * 2);
   self  = [super initWithFrame:frame];
   if( self)
   {
      _velocity = velocity;

      layer = MULLE_OBJC_CLASS_CAST( BallLayer, [self layer]);
      [layer setColor:color];
   }
   return( self);
}


- (void) mouseEntered:(UIMouseTrackingEvent *) event
{
   [super mouseEntered:event];

   [self setBorderColor:CGColorMakeWhite()];
   [self setBorderWidth:2.0];
   [self setNeedsDisplay];
}


- (void) mouseExited:(UIMouseTrackingEvent *) event
{
   [super mouseExited:event];

   [self setBorderColor:CGColorMakeWhite()];
   [self setBorderWidth:0.0];
   [self setNeedsDisplay];
}


- (UIEvent *) mouseDown:(UIEvent *) event
{
   [self setTrapped:YES];

   return( nil);
}


- (UIEvent *) mouseUp:(UIEvent *) event
{
   [self setTrapped:NO];
   return( nil);
}


@end



int   main( int argc, char *argv[])
{
   UIWindow            *window;
   UIApplication       *app;
   Game                *game;
   UIWindowStyleMask   styleMask;

   app        = [UIApplication sharedInstance];
   styleMask  = UIWindowStyleMaskDefault; //UIWindowStyleMaskNonRetained
   styleMask |= UIWindowStyleInputPolling;
   window     = [UIWindow windowWithFrame:CGRectMake( 0, 0, WINDOW_W, WINDOW_H)
                          titleUTF8String:"Collision Demo"
                                styleMask:styleMask];

   game = [[[Game alloc] initWithWindow:window] autorelease];

   [app addWindow:window];

   return( [app runApp]);
}

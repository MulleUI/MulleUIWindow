//
// Copyright (c) 2021 Nat!, Mulle kybernetiK
//
#import "UIWindow+Render.h"

#import "import-private.h"

#import "UIWindow+DebugPrivate.h"
#import "UIWindow+Layout.h"
#import "UIWindow+RenderQueue.h"

//#define LAYOUT_ANIMATIONS
//#define RENDER_DEBUG
//#define RENDER_DEBUG_VERBOSE
//#define RENDER_FRAMEINFO_DEBUG

// #define DRAW_FRAMEBUFFER_ID_RECT


//
//
// UIWindow frame chain
//
//    Creates a queue of CALayers from the UIView hierarchy. Layers are
//    setup so they draw themselves into the window coordinate space.
//
//                                                  UIWindow Delegate Views
//  .----------------------------------------.      .---.---.
//  | UIWindow willLayoutWithAbsoluteTime:   |      | B | C |
//  '----------------------------------------'      '---'---'
//                       |
//                       |
//                       v                          UIView hierarchy tree
//  .-----------------------------------------.           .---.
//  | UIView layout                           |           | A |-.
//  '-----------------------------------------'           '---' |
//                       |                                |     |
//                       |                          .---. |     |
//                       v                          | B |<'     v
//  .-----------------------------------------.     '---'     .---.
//  | UIView createRenderQueue:               |               | C |
//  '-----------------------------------------'               '---'
//                       |                                  |
//    From here on the   |                                  |
//    only hierarchy     |                                  |
//    is the order       |                                  |
//    of the layers in   |                                  v
//    the queue.         |
//                       v                          CALayer Render Queue
//  .------------------------------------------.    .---.---.---.---.---.----.
//  | CGAnimation animateObjects:absoluteTime: |    | A1| B1| B2| C1| C2| C3 |
//  '------------------------------------------'    '---'---'---'---'---'----'
//                       |
//                       |
//                       v
//  .-----------------------------------------.
//  | CGContext drawObjects:                  |
//  '-----------------------------------------'
//
// glitch hunt:
//
// a) we sometimes overflow the current frame
// b) we are doublebuffering
// c) the glitch occurs when there is already drawing on the screen
// d) the glitch looks like the buffer is cleared and then not swapped
//
// With the parameters, you should be able to render into a different
// context from the window context, with all the delegate calls intact.
//
// A window must not run two renderFrames concurrently!
// A view calling [(UIWindow *) [self window] context] could get the wrong context
// though. Maybe need a -renderContext ?
// Or should
//

@implementation UIWindow( Render)


- (void) initCategory
{
   _frameCallback  = UIWindowDefaultDrawViews;
}


// use very basic drawing
// render everything line by line
//
// typedef struct CGFrameInfo
// {
//    struct CGWindowInfo    window;
//    CGPixelRect    viewportFrame;    // used for the viewport (use: 0, 0, frameSize)
//    CGFloat                alpha;            // set to 1.0
//    mulle_absolutetime_t   now;              // mulle_absolutetime_t
// } CGFrameInfo;
//
// typedef struct CGWindowInfo
// {
//    CGRect                 frame;            // window coordinates frame
//    CGPixelSize    framebufferSize;  // actual pixels (frameSize * pixelRatio)
//    CGVector               UIScale;
//    CGFloat                pixelRatio;
// } CGWindowInfo;

- (void) renderDebugInfo:(struct UIWindowDebugInfo *) p
                 atPoint:(CGPoint) point
                hexColor:(NSUInteger) color
         graphicsDrawing:(id <UIGraphicsDrawing>) context
{
   struct CGFrameInfo    *info;

   assert( p);

   info = p->info;

   mulle_buffer_do( buffer)
   {
      mulle_buffer_sprintf( buffer, "frame              : %s\n",   CGRectUTF8String( info->window.frame));
      mulle_buffer_sprintf( buffer, "framebufferSize    : %s\n",   CGPixelSizeUTF8String( info->window.framebufferSize));
      mulle_buffer_sprintf( buffer, "UIScale            : %s\n",   CGVectorUTF8String( info->window.UIScale));
      mulle_buffer_sprintf( buffer, "pixelRatio         : %.3f\n", info->window.pixelRatio);
      mulle_buffer_sprintf( buffer, "viewportFrame      : %s\n",   CGPixelRectUTF8String( info->viewportFrame));
      mulle_buffer_sprintf( buffer, "alpha              : %.3f\n", info->alpha);
      mulle_buffer_sprintf( buffer, "now                : %.6f\n", info->now);
      mulle_buffer_sprintf( buffer, "numberOfFrames     : %tu\n",  p->numberOfFrames);
      mulle_buffer_sprintf( buffer, "activeAnimations   : %td\n",  p->activeAnimations);
      mulle_buffer_sprintf( buffer, "runningAnimations  : %td\n",  p->runningAnimations);
      mulle_buffer_sprintf( buffer, "finishedAnimations : %td\n",  p->finishedAnimations);

      [context drawAtPoint:point
            textUTF8String:mulle_buffer_get_string( buffer)
        fontNameUTF8String:"mono"
                  fontSize:11.0
                  hexColor:color];
   }
}


- (void) renderDisplayBits:(NSUInteger) displayBits
                   atPoint:(CGPoint) point
           graphicsDrawing:(id <UIGraphicsDrawing>) context
{
//   UIWindowDisplayNeedsRedraw     = 0x1,   // needs immediate attention
//   UIWindowDisplayNeedsLayout     = 0x2,   // needs immediate attention, forces redraw
//   UIWindowDisplayNeedsAnimation  = 0x4,   // needs attention according to animationRate
//   UIWindowDisplayNeedsMouseEvent = 0x8    // layout change needs to retrack mouse
   CGFloat      distance    = 8.0;
   CGFloat      diameter    = 7.0;
   CGFloat      radius      = diameter / 2.0;
   CGPoint      center;
   CACircle     circle;
   uint32_t     backColor   = 0x202020FF;
   uint32_t     offColor    = 0x101010FF;
   uint32_t     onColor;
   uint32_t     greenColor  = 0x20D020FF;
   uint32_t     orangeColor = 0xD04010FF;
   uint32_t     yellowColor = 0xD0D020FF;
   uint32_t     blueColor   = 0x0087FFFF;
   NSUInteger   bit;

   center = CGPointMake( point.x + radius, point.y + radius);

   for( bit = UIWindowDisplayNeedsMouseEvent; bit; bit >>= 1)
   {
      circle = CACircleMake( center, radius);
      [context fillCircle:circle
                 hexColor:backColor];
      circle = CACircleMake( center, radius - 0.75);
      switch( bit)
      {
      case UIWindowDisplayNeedsAnimation  : onColor = orangeColor; break;
      case UIWindowDisplayNeedsLayout     : onColor = greenColor; break;
      case UIWindowDisplayNeedsMouseEvent : onColor = yellowColor; break;
      default                             : onColor = blueColor; break;
      }
      [context fillCircle:circle
                 hexColor:(displayBits & bit) ? onColor : offColor];
      center.x += distance;
   }
}


- (void) drawDebug:(struct CGFrameInfo *) info
   graphicsDrawing:(id <UIGraphicsDrawing>) context
{
   MulleWindowProfileBegin();

   if( _debuggingFlags & UIWindowDebugFramebufferIdRect)
   {
      CGRect   rect;

      rect.origin = CGPointZero;
      rect.size   = info->window.frame.size;
      rect        = CGRectInset( rect, 24, 24);
      [context strokeRect:rect
              strokeWidth:4.0
                 hexColor:0xE04020FF];
   }

   if( self->_debuggingFlags & UIWindowDebugRenderFrameInfo)
   {
      struct UIWindowDebugInfo    debugInfo;

      memset( &debugInfo, 0, sizeof( debugInfo));
      debugInfo.info                = info;
      debugInfo.numberOfFrames      = [_renderGraphicsContext numberOfFrames];

      debugInfo.activeAnimations    = [_preLayoutAnimator numberOfActiveAnimations];
      debugInfo.runningAnimations   = [_preLayoutAnimator numberOfRunningAnimations];
      debugInfo.finishedAnimations  = [_preLayoutAnimator numberOfFinishedAnimations];

      debugInfo.activeAnimations   += [_postLayoutAnimator numberOfActiveAnimations];
      debugInfo.runningAnimations  += [_postLayoutAnimator numberOfRunningAnimations];
      debugInfo.finishedAnimations += [_postLayoutAnimator numberOfFinishedAnimations];

      [self renderDebugInfo:&debugInfo
                    atPoint:CGPointMake( 20, 20)
                   hexColor:0xC03000FF
            graphicsDrawing:context];
   }

   if( self->_debuggingFlags & UIWindowDebugRenderDisplayBits)
   {
      UIWindowRenderLogVerbose( "display=0x%tx return=0x%tx", _debugDisplayBits, _debugReturnBits);

      [self renderDisplayBits:_debugDisplayBits
                      atPoint:CGPointMake( info->window.frame.size.width - 50,
                                           info->window.frame.size.height - 21)
              graphicsDrawing:context];

      [self renderDisplayBits:_debugReturnBits
                      atPoint:CGPointMake( info->window.frame.size.width - 50,
                                           info->window.frame.size.height - 12)
              graphicsDrawing:context];
   }

   MulleWindowProfileEnd();
}



- (void) drawViewsInFrame:(struct CGFrameInfo *) info
          graphicsContext:(id <UIGraphicsContext>) context
{
   MulleWindowProfileBegin();

   [context useDefaultFont];

   if( _willDrawViewsCallback)
      (*_willDrawViewsCallback)( self, context, info);

   UIWindowRenderLogVerbose( "drawing objects");
   [context drawObjects:&_drawingQueue];
   UIWindowRenderLogVerbose( "drew objects");

   // reset for frameDelegate and others
   [context reset];

   if( _didDrawViewsCallback)
      (*_didDrawViewsCallback)( self, context, info);

   [self drawDebug:info
   graphicsDrawing:MULLE_OBJC_PROTOCOL_CAST( UIGraphicsDrawing, context)];

   [context suspendRender];  // this calls nvgEndFrame

   MulleWindowProfileEnd();
}

//
// The default "rawFrameCallback" used in -renderWithFrameInfo:displayBits:
//
UIWindowDisplayBits
   UIWindowDefaultDrawViews( UIPureWindow *self_in,
                             id <UIGraphicsContext> context,
                             struct CGFrameInfo *info,
                             UIWindowDisplayBits displayBits)
{
   UIWindow              *self = MULLE_OBJC_CLASS_CAST( UIWindow, self_in);
   UIWindowDisplayBits   returnBits;

   UIWindowDisplayBitsLog( "%s enters (0x%tx)", __FUNCTION__, displayBits);

   // first two functions should happen outside of any context being
   // active or not, we are still adding bits to displayBits here
   displayBits  = UIWindowDefaultLayoutViews( self, info, displayBits);
   displayBits  = UIWindowDefaultPrepareRenderQueue( self, info, displayBits);
   returnBits   = displayBits & ~0xFFFF;

   // for debugging (could be deleted)
   self->_debugDisplayBits = displayBits;
   self->_debugReturnBits  = returnBits;

   if( displayBits & UIWindowDisplayNeedsRedraw)
   {
      [self drawViewsInFrame:info
             graphicsContext:context];
   }

   UIWindowDisplayBitsLog( "%s returns (0x%tx)", __FUNCTION__, returnBits);
   return( returnBits);
}

@end

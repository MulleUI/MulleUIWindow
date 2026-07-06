//
// Copyright (c) 2021 Nat!, Mulle kybernetiK
//
#import "UIWindow+Render.h"

#import "import-private.h"

#import "UIWindow+DebugPrivate.h"
#import "UIWindow+Layout.h"
#import "UIWindow+RenderQueue.h"
#import "UIWindow+Styling.h"

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
//  | CGContext renderObjects:                  |
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

@dependency UIWindow( Layout);

// this will or oughta be only called by UIWindow when running init
// it's not clobbered by anything
- (void) initCategory
{
   _frameCallback  = UIWindowDefaultRenderViews;
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
//    CGRect         frame;            // window coordinates frame
//    CGPixelSize    framebufferSize;  // actual pixels (frameSize * pixelRatio)
//    CGVector       UIScale;
//    CGFloat        pixelRatio;
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


- (void) render_drawDebug:(struct CGFrameInfo *) info
          graphicsDrawing:(id <UIGraphicsDrawing>) drawing
{
   MulleWindowProfileBegin();

   [super render_drawDebug:info
           graphicsDrawing:drawing];

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
            graphicsDrawing:drawing];
   }

   MulleWindowProfileEnd();
}


- (void) renderLayersInFrame:(struct CGFrameInfo *) info
             graphicsContext:(id <UIGraphicsContext>) context
{
   MulleWindowProfileBegin();

   [context useDefaultFont];

   if( _willRenderLayersCallback)
      (*_willRenderLayersCallback)( self, context, info);

   UIWindowRenderLogVerbose( "rendering layers");
   [context renderObjects:&_renderQueue];
   UIWindowRenderLogVerbose( "drew layers");

   if( _didRenderLayersCallback)
   {
      [context reset];
      (*_didRenderLayersCallback)( self, context, info);
   }

   MulleWindowProfileEnd();
}

//
// The default "_frameCallback" used in UIPureWindowDefaultRawFrameCallback
//
UIWindowDisplayBits
   UIWindowDefaultRenderViews( UIPureWindow *self_in,
                               id <UIGraphicsContext> context,
                               struct CGFrameInfo *info,
                               UIWindowDisplayBits displayBits)
{
   UIWindow              *self = MULLE_OBJC_CLASS_CAST( UIWindow, self_in);
   UIWindowDisplayBits   returnBits;

   UIWindowDisplayBitsLogVerbose( "enters (%s)", UIWindowDisplayBitsUTF8String( displayBits));

   // Cascade: Styling → Layout → Display
   // Each stage implies the next.
   if( displayBits & UIWindowDisplayNeedsStyling)
   {
      [self style];
      displayBits &= ~UIWindowDisplayNeedsStyling;
      displayBits |= UIWindowDisplayNeedsLayout;
   }
   displayBits = UIWindowDefaultLayoutViews( self, info, displayBits);
   displayBits = UIWindowDefaultPrepareRenderQueue( self, context, info, displayBits);
   returnBits  = displayBits & ~0xFFFF;

   // Drawing always happens when a frame runs.
   [self renderLayersInFrame:info
             graphicsContext:context];

   UIWindowDisplayBitsLogVerbose( "returns (%s)", UIWindowDisplayBitsUTF8String( returnBits));
   return( returnBits);
}

@end

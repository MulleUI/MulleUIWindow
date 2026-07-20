#import <MulleUIWindow/MulleUIWindow.h>

#include "../fake-ui-application-glue.inc"


@interface TestView : UIView
@end


@implementation TestView

- (void) layout
{
   mulle_printf( "layout\n");
   [super layout];
}


- (void) createRenderQueue:(struct mulle_pointerarray *) renderQueue
                   context:(struct UIRenderQueueContext *) ctx
{
   mulle_printf( "createRenderQueue\n");
   [super createRenderQueue:renderQueue
                    context:ctx];
}

@end


static void   simulateFrame( UIWindow *window)
{
   UIWindowDisplayBits   displayBits;
   struct CGFrameInfo    frameInfo;

   //
   // read and clear pending display bits (mimics renderAndSwapOneFrame)
   //
   displayBits  = [window needsDisplayBitsClearIfSet];
   displayBits |= UIWindowDisplayNeedsRedraw;

   memset( &frameInfo, 0, sizeof( frameInfo));
   frameInfo.window.frame = [window frame];
   frameInfo.alpha        = 1.0;

   UIWindowDefaultRenderViews( (UIPureWindow *) window,
                               nil,
                               &frameInfo,
                               displayBits);
}


int   main( void)
{
   UIWindow   *window;
   UIView     *contentView;
   TestView   *view;
   CGRect     frame;

   frame       = CGRectMake( 0, 0, 640, 480);
   window      = [[UIWindow alloc] initWithFrame:frame
                                 titleUTF8String:"Test"
                                       styleMask:UIWindowStyleMaskNonRetained & ~UIWindowStylePlanes];
   contentView = [window contentView];
   view        = [TestView viewWithFrame:CGRectMake( 0, 0, 100, 100)];
   [contentView addSubview:view];

   //
   // Frame 1: initial frame, layout must happen (window init sets needsLayout)
   //
   mulle_printf( "---frame1---\n");
   simulateFrame( window);

   //
   // Frame 2: nothing set, layout does NOT happen again.
   //          createRenderQueue always runs (render queue is rebuilt every frame)
   //
   mulle_printf( "---frame2---\n");
   simulateFrame( window);

   //
   // Frame 3: setNeedsLayout triggers layout AND display
   //
   [view setNeedsLayout];
   mulle_printf( "---frame3---\n");
   simulateFrame( window);

   //
   // Frame 4: setNeedsDisplay on a view triggers display but NOT layout
   //
   [view setNeedsDisplay];
   mulle_printf( "---frame4---\n");
   simulateFrame( window);

   //
   // Frame 5: setNeedsRenderLayers on window triggers display but NOT layout
   //
   [window setNeedsRenderLayers];
   mulle_printf( "---frame5---\n");
   simulateFrame( window);

   [window release];
   return( 0);
}

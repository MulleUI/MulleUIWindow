#import <MulleUIWindow/MulleUIWindow.h>

#include "../fake-ui-application-glue.inc"


static int   step;


@interface TestView : UIView
@end


@implementation TestView

- (void) layout
{
   mulle_printf( "%d:layout\n", ++step);
   [super layout];
}


- (void) createRenderQueue:(struct mulle_pointerarray *) renderQueue
                   context:(struct UIRenderQueueContext *) ctx
{
   mulle_printf( "%d:createRenderQueue\n", ++step);
   [super createRenderQueue:renderQueue
                    context:ctx];
}

@end


int   main( void)
{
   UIWindow                *window;
   UIView                  *contentView;
   TestView                *view;
   CGRect                  frame;
   UIWindowDisplayBits     displayBits;
   struct CGFrameInfo      frameInfo;

   frame       = CGRectMake( 0, 0, 640, 480);
   window      = [UIWindow windowWithFrame:frame
                           titleUTF8String:"Test"
                                 styleMask:UIWindowStyleMaskDefault & ~UIWindowStylePlanes];

   contentView = [window contentView];
   view        = [TestView viewWithFrame:CGRectMake( 0, 0, 100, 100)];
   [contentView addSubview:view];

   displayBits  = [window needsDisplayBitsClearIfSet];
   mulle_printf( "0:displayBits=0x%tx\n", displayBits);
   [window getFrameInfo:&frameInfo];  // retrieve newest geometry
   displayBits  = [window renderWithFrameInfo:&frameInfo
                                  displayBits:displayBits];

   return( 0);
}

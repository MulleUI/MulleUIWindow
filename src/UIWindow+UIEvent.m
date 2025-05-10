#define _GNU_SOURCE

#import "UIWindow+UIEvent.h"

#import "import-private.h"

#import "UIWindow+FrameInfo.h"
#import "UIWindow+UITrackingArea.h"
#import "UIWindow+UIResponder.h"
#import "UIView+UITrackingArea.h"
#import "UIView+UIFirstResponder.h"
#import "UIView+UIWindow.h"


@implementation UIWindow( UIEvent)


- (UIMouseMotionEvent *) acceptMouseMotionEvent:(UIMouseMotionEvent *) event
{
   BOOL   inDrag;

   if( [self isTracking])
   {
      if( _trackingAreasEnabled)
      {
         inDrag = [event buttonStates] != 0;
         [self handleTrackingAreaForInputEvent:event
                                        inDrag:inDrag];
      }
   }

   return( event);
}


@end

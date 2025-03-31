#define _GNU_SOURCE

#import "UIWindow+OneFrame.h"

#import "import-private.h"

#import "UIWindow+FrameInfo.h"
#import "UIWindow+UIEvent.h"
#import "UIWindow+UIResponder.h"
#import "UIWindow+UITrackingArea.h"
#import "UIView+UIWindow.h"


//#define MOUSE_MOTION_CALLBACK_DEBUG
//#define MOUSE_BUTTON_CALLBACK_DEBUG
//#define RESIZE_CALLBACK_DEBUG
//#define HANDLE_EVENT_DEBUG
//#define PROCESS_EVENT_DEBUG


@implementation UIWindow( OneFrame)

- (void) eventHandlingWithFrameRate:(mulle_relativetime_t) frameRate
{
   [self setupQuadtree];
   [super eventHandlingWithFrameRate:frameRate];
}

@end

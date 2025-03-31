#import "UIWindow.h"

//
// This is support for the "conventional" GLFW render/waitForEvents loop
// which has fallen out of favor for UIApplication
//
@interface UIWindow( OneFrame)

- (void) eventHandlingWithFrameRate:(mulle_relativetime_t) frameRate;

@end


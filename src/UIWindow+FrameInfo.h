//
// Copyright (c) 2021 Nat!, Mulle kybernetiK
//

#import "UIWindow.h"


//
// Frame is about layouting views, animating views and layers and
// finally rendering into a framebuffer. If you want to directly get called
// without UIView handling then override the frameCallback.
//
@interface UIWindow( FrameInfo)

- (void) render_setupInitialFirstResponderIfNeeded;
- (UIWindowDisplayBits) render_adjustFrameWithFrameInfo:(struct CGFrameInfo *) info
                                            displayBits:(UIWindowDisplayBits) displayBits;

@end


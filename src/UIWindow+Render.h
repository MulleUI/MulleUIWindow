//
// Copyright (c) 2021 Nat!, Mulle kybernetiK
//
// prefer a local UIWindow over one in import.h
#ifdef __has_include
# if __has_include( "UIWindow.h")
#  import "UIWindow.h"
# endif
#endif

// we want "import.h" always anyway
#import "import.h"



//
// this callback does the UIView layout, animation unless _frameCallback is set
//
// +----------------------------------+
// | UIWindowDefaultLayoutViews            |
// +----------------------------------+
//           |
//           v
// +-----------------------------------+
// | UIWindowDefaultPrepareRenderQueue |
// +-----------------------------------+
//           |
//           v
// +--------------------------------------+
// | UIWindowDefaultDrawInGraphicsContext |
// +--------------------------------------+
//
// it also takes care of frameDelegate callbacks
//
// - window:willBeginFrame:graphicsContext:
// - window:didEndFrame:graphicsContext:
//
// not id <UIGraphicsContext> context is intentional


UIWindowDisplayBits
   UIWindowDefaultRenderViews( UIPureWindow *self_in,
                             id <UIGraphicsContext> context,
                             struct CGFrameInfo *info,
                             UIWindowDisplayBits displayBits);

struct UIWindowDebugInfo
{
   struct CGFrameInfo  *info;
   NSUInteger          numberOfFrames;
   NSUInteger          activeAnimations;
   NSUInteger          runningAnimations;
   NSUInteger          finishedAnimations;
};


@interface UIWindow( Render)

- (void) renderLayersInFrame:(struct CGFrameInfo *) info
            graphicsContext:(id <UIGraphicsContext>) context;

@end


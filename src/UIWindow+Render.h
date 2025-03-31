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

//
// The default "rawFrameCallback" used in -renderWithFrameInfo:displayBits:
//

UIWindowDisplayBits
   UIWindowDefaultDrawViews( UIPureWindow *self_in,
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

- (void) drawViewsInFrame:(struct CGFrameInfo *) info
         graphicsContext:(id <UIGraphicsContext>) context;

- (void) drawDebug:(struct CGFrameInfo *) info
  graphicsDrawing:(id <UIGraphicsDrawing>) context;

- (void) renderDebugInfo:(struct UIWindowDebugInfo *) p
                 atPoint:(CGPoint) point
                hexColor:(NSUInteger) color
         graphicsDrawing:(id <UIGraphicsDrawing>) context;

- (void) renderDisplayBits:(NSUInteger) displayBits
                   atPoint:(CGPoint) point
           graphicsDrawing:(id <UIGraphicsDrawing>) context;
@end


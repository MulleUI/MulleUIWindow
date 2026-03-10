//
// Copyright (c) 2024 Nat!, Mulle kybernetiK
//
// prefer a local UIWindow over one in import.h
#ifdef __has_include
# if __has_include( "UIWindow.h")
#  import "UIWindow.h"
# endif
#endif

// we want "import.h" always anyway
#import "import.h"


@protocol UIGraphicsContext;


@interface UIWindow( RenderQueue)

- (UIWindowDisplayBits) willLayoutWithAbsoluteTime:(mulle_absolutetime_t) renderStart;

- (void) createRenderQueueForFrame:(struct CGFrameInfo *) info
                   graphicsContext:(id <UIGraphicsContext>) context;

- (void) createRenderQueue:(struct mulle_pointerarray *) renderQueue
           graphicsContext:(id <UIGraphicsContext>) context;

@end


// returns UIWindowAnimationDidHappened if animations were run
// otherwise zero
UIWindowDisplayBits
   UIWindowDefaultPrepareRenderQueue( UIWindow *self,
                                      id <UIGraphicsContext> context,
                                      struct CGFrameInfo *info,
                                      UIWindowDisplayBits displayBits);
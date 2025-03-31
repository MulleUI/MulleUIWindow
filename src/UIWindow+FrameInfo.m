//
// Copyright (c) 2021 Nat!, Mulle kybernetiK
//
#define _GNU_SOURCE

#import "UIWindow+FrameInfo.h"

#import "import-private.h"

#import "UIWindow+Layout.h"
#import "UIWindow+UIResponder.h"
#import "UIWindow+UIEvent.h"
#import "UIView+UIFirstResponder.h"

@interface UIWindow( Private)

- (void) _setFrame:(CGRect) frame;

@end


@implementation UIWindow ( FrameInfo)

- (UIWindowDisplayBits) render_adjustFrameWithFrameInfo:(struct CGFrameInfo *) info
                                            displayBits:(UIWindowDisplayBits) displayBits

{
   // if the window size changed, we need to relayout
   if( ! CGSizeEqualToSize( info->window.frame.size, [self frame].size))
   {
      [self _setFrame:info->window.frame]; // don't trigger property change
      displayBits |= UIWindowDisplayNeedsLayout;
   }
   return( displayBits);
}


- (void) render_setupInitialFirstResponderIfNeeded
{
   id <UIResponder>   responder;

   if( ! _initialFirstResponderState)
   {
      responder = _initialFirstResponder;
      if( ! _initialFirstResponder)
         responder = [[self contentView] nextFirstResponder];
      [responder becomeFirstResponder];
      _initialFirstResponderState = responder ? 1 : -1;
   }
}

@end


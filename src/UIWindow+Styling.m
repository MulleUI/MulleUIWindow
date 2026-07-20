//
// Copyright (c) 2024 Nat!, Mulle kybernetiK
//
#import "UIWindow+Styling.h"

#import "UIView+UIWindow.h"


@implementation UIWindow( Styling)

- (void) setNeedsStyling
{
   [self setNeedsDisplayBit:UIWindowDisplayNeedsStyling];
}


- (BOOL) needsStyling
{
   return( [self needsDisplay] & UIWindowDisplayNeedsStyling ? YES : NO);
}


- (void) style
{
   [[self view] style];
}

@end

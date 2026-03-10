//
// Copyright (c) <|YEAR|> Nat!, Mulle kybernetiK
//
#import "UIWindow+Styling.h"

#import "import-private.h"



@implementation UIWindow ( Styling)

- (void) style 
{
#if DEBUG_DUPLICATE_LAYOUT
   assert( ! _isStyling);
   _isStyling = YES;
#endif

//   [self->_style styleViews:self->_view]
//   [self->_view didStyle:self];

#if DEBUG_DUPLICATE_LAYOUT
   _isStyling = NO;
#endif
}

@end

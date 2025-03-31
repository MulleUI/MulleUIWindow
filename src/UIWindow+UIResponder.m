#import "UIWindow+UIResponder.h"

#import "UIView+UIFirstResponder.h"
#import "UIView+UIFirstResponderSearch.h"

//#define FIRST_RESPONDER_DEBUG

@implementation UIWindow( UIResponder)

- (id <UIResponder>) firstResponderSearchInPrimaryDirection:(CADirection) primaryDirection
                                         secondaryDirection:(CADirection) secondaryDirection
{
   struct UIFirstResponderSearch   search;
   id <UIResponder>           best;

   UIFirstResponderSearchInit( &search, _firstResponder, primaryDirection, secondaryDirection);
   [[self contentView] _firstResponderSearch:&search];
   best = UIFirstResponderSearchGetResult( &search);
   UIFirstResponderSearchDone( &search);
   
   return( best);
}


- (id <UIResponder>) previousFirstResponder
{
   id <UIResponder>  responder;

   responder = [super previousFirstResponder];
   if( responder)
      return( responder);

   return( [self firstResponderSearchInPrimaryDirection:CADirectionTop
                                     secondaryDirection:CADirectionLeft]);
}


- (id <UIResponder>) nextFirstResponder
{
   id <UIResponder>  responder;

   responder = [super nextFirstResponder];
   if( responder)
      return( responder);
   return( [self firstResponderSearchInPrimaryDirection:CADirectionBottom
                                     secondaryDirection:CADirectionRight]);
}


@end

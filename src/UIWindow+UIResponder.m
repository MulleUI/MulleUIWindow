//
//  UIWindow+UIResponder.m
//  MulleUIWindow
//
//  Copyright (c) 2019 Nat! - Mulle kybernetiK.
//  All rights reserved.
//
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//
//  Redistributions of source code must retain the above copyright notice, this
//  list of conditions and the following disclaimer.
//
//  Redistributions in binary form must reproduce the above copyright notice,
//  this list of conditions and the following disclaimer in the documentation
//  and/or other materials provided with the distribution.
//
//  Neither the name of Mulle kybernetiK nor the names of its contributors
//  may be used to endorse or promote products derived from this software
//  without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
//  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
//  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
//  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
//  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
//  POSSIBILITY OF SUCH DAMAGE.
//
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

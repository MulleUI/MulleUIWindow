//
//  UIView+UIFirstResponder.m
//  MulleUIWindow
//
//  Copyright (c) 2025 Nat! - Mulle kybernetiK.
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
#import "UIView+UIFirstResponder.h"

#import "UIView+UIWindow.h"
#import "UIWindow+UIResponder.h"
#import <MulleUIView/UIView+DebugPrivate.h>


@implementation UIView( UIFirstResponder)

@dependency UIView( UIEvent);
MULLE_OBJC_DEPENDS_ON_CATEGORY( UIView, UIEvent);

- (BOOL) becomeFirstResponder
{
   UIWindow           *window;
   id <UIResponder>   firstResponder;

   // I think calling this too often is not good, as it does too much
   // (later: not so much now). We do this check later again soo
   //if( [self isFirstResponder])
   //   return( YES);
   
   UIViewEventLog( nil,  "");

   // if window is nil, the function will eventually return NO
   window         = (UIWindow *) _window;
   firstResponder = [window firstResponder];
   if( firstResponder)
   {   
      if( firstResponder == self)
         return( YES);
      if( ! [firstResponder canResignFirstResponder])
         return( NO);
      if( ! [firstResponder resignFirstResponder])
         return( NO);
   }
   
   if( [window makeFirstResponder:self])
   {
      [self didBecomeFirstResponder];
      return( YES);
   }
   return( NO);
}


- (BOOL) resignFirstResponder
{
   if( ! [self isFirstResponder])
      return( YES);

   UIViewEventLog( nil, "");

   if( [(UIWindow *) _window makeFirstResponder:nil])
   {
      [self didResignFirstResponder];
      return( YES);
   }
   return( NO);
}


- (BOOL) isFirstResponder
{
   id    responder;

   // if not part of a window, no problem
   responder = [(UIWindow *) _window firstResponder];
   return( responder == self);
}


- (id <UIResponder>) previousFirstResponder
{
   return( nil);
}


- (id <UIResponder>) nextFirstResponder
{
   return( nil);
}


@end

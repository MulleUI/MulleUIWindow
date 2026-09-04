//
//  UIView+CAAnimation.h
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
#ifdef __has_include
# if __has_include( "UIView.h")
#  import "UIView.h"
# endif
#endif

#import "import.h"


typedef NS_ENUM( NSUInteger, UIViewAnimationCurve)
{
   UIViewAnimationCurveEaseInOut = CAAnimationCurveEaseInOut,
   UIViewAnimationCurveEaseIn    = CAAnimationCurveEaseIn,
   UIViewAnimationCurveEaseOut   = CAAnimationCurveEaseOut,
   UIViewAnimationCurveLinear    = CAAnimationCurveLinear
};


typedef NS_OPTIONS( NSUInteger, UIViewForgetImplicitAnimationsMode)
{
   UIViewForgetImplicitAnimationsAll          = 0x0,
   UIViewForgetImplicitAnimationsSkipSelf     = 0x1,
   UIViewForgetImplicitAnimationsSkipLayers   = 0x2,
   UIViewForgetImplicitAnimationsSkipSubviews = 0x4,
};


// MEMO: talking about class methods here...
//
// Doing it like this is kinda bad, because different windows could have
// different threads but they couldn't create animations at the same time
// because it is tied to the class. On the other, one can reuse more
// UIKit code, by keeping this as is.
// Possible solution: Have [UIWindow window] in a thread local variable
// and forward all these UIView calls there
//
// TODO: outsource this into CATransaction ?
//
@interface UIView ( CAAnimation) <CAImplicitlyAnimatableObject>

+ (void) beginAnimations:(char *) animationID
                 context:(id) context;

//
// this is different to UIView, you get a CAAnimationGroup and have to
// add it to the window of your choice
//
+ (CAAnimationGroup *) commitAnimations;

+ (BOOL) areAnimationsEnabled;

+ (void) setAnimationDelegate:(id) delegate;

+ (NSUInteger) animationCurve;
+ (void) setAnimationCurve:(NSUInteger) curve;

+ (CATweenFunction *) animationTweenFunction;
+ (void) setAnimationTweenFunction:(CATweenFunction *) curve;

+ (mulle_relativetime_t) animationDelay;
+ (void) setAnimationDelay:(mulle_relativetime_t) delay;

+ (mulle_relativetime_t) animationDuration;
+ (void) setAnimationDuration:(mulle_relativetime_t) duration;

+ (mulle_relativetime_t) animationOffset;
+ (void) setAnimationOffset:(mulle_relativetime_t) offset;

+ (BOOL) animationRepeatAutoreverses;
+ (void) setAnimationRepeatAutoreverses:(BOOL) flag;

+ (BOOL) animationIsAdditive;
+ (void) setAnimationIsAdditive:(BOOL) flag;

// incompatible, this like setAnimationRepeatCount:-1 (YES)
// or setAnimationRepeatCount:0
+ (BOOL) mulleAnimationRepeats;
+ (void) mulleSetAnimationRepeats:(BOOL) flag;

// if repeatCount < 0.0 then it repeats indefinitely
+ (void ) setAnimationRepeatCount:(float) repeatCount;
+ (float) animationRepeatCount;

+ (void) addAnimatableObject:(id <CAImplicitlyAnimatableObject>) object;

- (void) willChange;

// this by default also removes animations from layers and subviews
- (void) forgetImplicitAnimations:(UIViewForgetImplicitAnimationsMode) mode;

@end

static inline BOOL   UIViewAreAnimationsEnabled( void)
{
   return( CATransactionGetCurrentTransaction() != nil);
}

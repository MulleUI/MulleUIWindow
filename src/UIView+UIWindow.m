//
//  UIView+UIWindow.m
//  MulleUIWindow
//
//  Copyright (c) 2021 Nat! - Mulle kybernetiK.
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
#import "UIView+UIWindow.h"

#import "import-private.h"

#import "UIWindow+UIEvent.h"
#import "UIWindow+UITrackingArea.h"
#import "UIWindow+Styling.h"
#import "UIView+UIFirstResponder.h"
#import "UIView+UITrackingArea.h"

#import <MulleUIView/UIView+DebugPrivate.h>


@interface NSObject ( UIWindow)

- (BOOL) __isUIWindow     MULLE_OBJC_THREADSAFE_METHOD;

@end


@implementation UIView ( UIWindow)


//
// if window changes, remove ourselves from old window tracking and move
// to new window tracking. Also resign as firstResponder, if we are
//
// If you change code here, also change it in UIView.m -setWindow:
//
- (void) setWindow:(id <UIWindow>) aWindow
{
   UIView    *view;
   UIWindow  *window;
   UIWindow  *oldWindow;

   window = MULLE_OBJC_CLASS_CAST_OR_NIL( UIWindow, aWindow);
   if( _window == window)
      return;

   oldWindow = MULLE_OBJC_CLASS_CAST_OR_NIL( UIWindow, _window);

   [self willMoveToWindow:window];
   [oldWindow removeTrackingView:self];

   // we if the view moves out of the window, we force the resignation of
   // firstResponder even if the view would say NO, but we teill it that
   // it didResign
   if( [self isFirstResponder])
   {
      if( [oldWindow makeFirstResponder:nil])
      {
         [self didResignFirstResponder];
      }
   }

   self->_window = window;
   [window setNeedsStyling];

   UIViewSubviewsFor( self, view)
      [view setWindow:window];

   if( mulle_pointerarray_get_count( &_trackingAreas))
      [window addTrackingView:self];

   [self didMoveToWindow:window];
}


/*
- (UIWindow *) window
{
   UIView   *view;
   UIView   *parent;

   for( view = self; (parent = view->_superview); view = parent)
   {
   }

   if( [view __isUIWindow])
      return( (UIWindow *) view);
   return( nil);
}
*/


// this is really quite conservative, maybe too conservative
- (UIWindowPlane *) windowPlane
{
   UIView     *view;
   UIView     *parent;
   UIView     *before;
   UIWindow   *window;

   before = nil;
   for( view = self; (parent = view->_superview); before = view, view = parent)
   {
   }

   if( [view __isUIWindow])
   {
      window = MULLE_OBJC_CLASS_CAST( UIWindow, view);
      if( [window isWindowPlane:before])
         return( MULLE_OBJC_CLASS_CAST( UIWindowPlane, before));
   }
   return( nil);
}


# pragma mark - screen

- (CGFloat) pixelsPerInchOfCurrentScreen
{
   id <UIScreen>         screen;
   struct UIScreenInfo   info;
   UIWindow              *window;

   window = MULLE_OBJC_CLASS_CAST( UIWindow, [self window]);

   memset( &info, 0, sizeof( info));
   screen = [window screenOrPrimaryScreen:YES];
   [screen getScreenInfo:&info];

   // UIScreenInfoGetPPI will return 72.0 if info is zero
   return( UIScreenInfoGetPPI( &info));
}


- (void) setNeedsDisplay
{
   UIWindow   *window;

   UIViewDisplayBitsLog( "");

   window = MULLE_OBJC_CLASS_CAST( UIWindow, [self window]);
   if( ! window)
      UIViewLog( "view has no window, so setNeedsDisplay does nothing");
   [window setNeedsDisplay];
}


- (BOOL) needsLayout
{
   UIWindow   *window;

   window = MULLE_OBJC_CLASS_CAST( UIWindow, [self window]);
   assert( window);
   return( [window needsLayout]);
}

//
// propagate up, but stop if already marked
//
- (void) setNeedsLayout
{
   UIWindow   *window;

   window = (UIWindow *) [self window];
   assert( window);
//   UIView   *view;
//   UIView   *next;

   [window setNeedsLayout];

   // MEMO: if we manually setFrame: on a UIView we want to reset the
   //       _originalFrame so that sizeChanges are noticed. (otherwise on
   //       legacy autoresizing we would use a cached version). Because
   //       setFrame: as called from layouting code and setFrame: as called
   //       "manually" is indistinguishable, we force manual code to issue
   //       setNeedsLayout: (by convention), when using legacy bits...
   _originalFrame.size.width = 0.0;

// FIX: ugly hackage
//   if( self->_superview)
//      self->_superview->_lastBounds.size.width = 0.0;
//
//   next = self;
//   for(;;)
//   {
//      view = next;
//      // if( view->_needsLayout)
//      //    break;
//
//      next = view->_superview;
//      if( ! next)  // we are the window
//      {
//         // window may use special atomic flag, so don't ignore accessor
//         return;
//      }
//
//      // view->_needsLayout = YES;  // quick mark and unto next
//   }
}


- (void) style
{
   // does nothing by default (MulleUIWidget will override this)   
}

@end

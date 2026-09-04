#define _GNU_SOURCE

#import "import-private.h"

// MEMO: this demo does nothing with views and should therefore move to
//       UIPureWindow if it isn't already there
//
// TODO: This crashes because we are running -refresh in the main loop and
//       then an intermediate resources is apparently no longer needed but
//       it belongs to the main thread.
//
// Thread 1 "window-view-dra" received signal SIGABRT, Aborted.
// __pthread_kill_implementation (no_tid=0, signo=6, threadid=<optimized out>) at ./nptl/pthread_kill.c:44
// warning: 44 ./nptl/pthread_kill.c: No such file or directory
// (gdb) bt
// #0  __pthread_kill_implementation (no_tid=0, signo=6, threadid=<optimized out>) at ./nptl/pthread_kill.c:44
// #1  __pthread_kill_internal (signo=6, threadid=<optimized out>) at ./nptl/pthread_kill.c:78
// #2  __GI___pthread_kill (threadid=<optimized out>, signo=signo@entry=6) at ./nptl/pthread_kill.c:89
// #3  0x00007ffff7a4527e in __GI_raise (sig=sig@entry=6) at ../sysdeps/posix/raise.c:26
// #4  0x00007ffff7a288ff in __GI_abort () at ./stdlib/abort.c:79
// #5  0x0000555555740d4e in __mulle_objc_puts_abort (
//     s=0x555556beb050 "Instance <CGContext 0x7FFFEC15B7A0> with affinity to thread <NSThread 0x555556AD0220 \"UIWindowThread\"> and TAO strategy MulleObjCTAOReceiverPerformsFinalize gets a -removeResourceForKey: call from thr"...)
//     at /home/src/srcO/mulle-objc/mulle-objc-runtime/src/mulle-objc-universe-fail.c:73
// #6  0x0000555555740e90 in _mulle_objc_vprintf_abort (
//     format=0x5555567f0890 "Instance <CGContext 0x7FFFEC15B7A0> with affinity to thread <NSThread 0x555556AD0220 \"UIWindowThread\"> and TAO strategy MulleObjCTAOReceiverPerformsFinalize gets a -removeResourceForKey: call from thr"..., args=0x7fffffffad90)
//     at /home/src/srcO/mulle-objc/mulle-objc-runtime/src/mulle-objc-universe-fail.c:103
// #7  0x00005555557410b2 in _mulle_objc_printf_abort (
//     format=0x5555567f0890 "Instance <CGContext 0x7FFFEC15B7A0> with affinity to thread <NSThread 0x555556AD0220 \"UIWindowThread\"> and TAO strategy MulleObjCTAOReceiverPerformsFinalize gets a -removeResourceForKey: call from thr"...)
//     at /home/src/srcO/mulle-objc/mulle-objc-runtime/src/mulle-objc-universe-fail.c:128
// #8  0x00005555556dd4d4 in MulleObjCTAOLogAndFail (obj=0x7fffec15b7a0, osThread=140737232504512, desc=0x555555fe4250)
//     at /home/src/srcO/mulle-objc/MulleObjC/src/class/NSThread.m:1379
// #9  0x00005555557420aa in mulle_objc_universe_fail_wrongthread (universe=0x555555ff1bc0 <mulle_objc_defaultuniverse>, obj=0x7fffec15b7a0,
//     affinity_thread=140737232504512, desc=0x555555fe4250) at /home/src/srcO/mulle-objc/mulle-objc-runtime/src/mulle-objc-universe-fail.c:510
// #10 0x0000555555710e8a in mulle_objc_object_taocheck_call (obj=0x7fffec15b7a0, methodid=1607606648)
//     at /home/src/srcO/mulle-objc/mulle-objc-runtime/src/mulle-objc-call.c:353
// #11 0x000055555570f652 in _mulle_objc_implementation_debug (imp=0x5555556abed0 <-[MulleUIResourceMap removeResourceForKey:]>,
//     obj=0x7fffec15b7a0, methodid=1607606648, parameter=0x7fffec131bb0, cls=0x55555622afd0)
//     at /home/src/srcO/mulle-objc/mulle-objc-runtime/src/mulle-objc-call.h:87
// #12 0x000055555571177d in _mulle_objc_object_callback_cache_miss_get_implementation (obj=0x7fffec15b7a0, methodid=1607606648,
//     parameter=0x7fffec131bb0) at /home/src/srcO/mulle-objc/mulle-objc-runtime/src/mulle-objc-call.c:526
// #13 0x00005555557117d1 in _mulle_objc_object_callback_cache_miss (obj=0x7fffec15b7a0, methodid=1607606648, parameter=0x7fffec131bb0)
//     at /home/src/srcO/mulle-objc/mulle-objc-runtime/src/mulle-objc-call.c:537
// #14 0x000055555570fc41 in mulle_objc_object_call (obj=0x7fffec15b7a0, methodid=1607606648, parameter=0x7fffec131bb0)
//     at /home/src/srcO/mulle-objc/mulle-objc-runtime/src/mulle-objc-call.c:98
// #15 0x000055555569b84c in -[CGImage finalize] (self=0x7fffec131bb0, _cmd=<incomplete type>)
//     at /home/src/srcO/MulleUI/MulleCG/src/CGImage.m:311
// #16 0x0000555555711104 in _mulle_objc_object_callback_class (obj=0x7fffec131bb0, methodid=2649333754, parameter=0x7fffec131bb0,
//     cls=0x555556229d40) at /home/src/srcO/mulle-objc/mulle-objc-runtime/src/mulle-objc-call.c:428
// #17 0x0000555555720fb9 in _mulle_objc_object_handle_fastmethodtablefault (obj=0x7fffec131bb0, methodid=2649333754, param=0x7fffec131bb0,
//     index=2) at /home/src/srcO/mulle-objc/mulle-objc-runtime/src/mulle-objc-fastmethodtable.c:78
// #18 0x0000555555721064 in _mulle_objc_fastmethodtablefaulthandler_2 (obj=0x7fffec131bb0, sel=2649333754, param=0x7fffec131bb0)
//     at /home/src/srcO/mulle-objc/mulle-objc-runtime/src/mulle-objc-fastmethodtable.c:93
// #19 0x000055555572f1a8 in mulle_objc_implementation_invoke (parameter=0x7fffec131bb0, sel=2649333754, self=0x7fffec131bb0,
//     imp=0x555555721035 <_mulle_objc_fastmethodtablefaulthandler_2>)
// --Type <RET> for more, q to quit, c to continue without paging--
//     at /home/src/srcO/mulle-objc/mulle-objc-runtime/src/mulle-objc-call.h:129
// #20 _mulle_objc_fastmethodtable_invoke (index=2, table=0x555556229dc0, param=0x7fffec131bb0, methodid=2649333754, obj=0x7fffec131bb0)
//     at /home/src/srcO/mulle-objc/mulle-objc-runtime/src/mulle-objc-call.h:201
// #21 mulle_objc_object_call_inline_partial (parameter=0x7fffec131bb0, methodid=2649333754, obj=0x7fffec131bb0)
//     at /home/src/srcO/mulle-objc/mulle-objc-runtime/src/mulle-objc-call.h:233
// #22 _mulle_objc_object_call_finalize (obj=0x7fffec131bb0)
//     at /home/src/srcO/mulle-objc/mulle-objc-runtime/src/mulle-objc-retain-release.h:343
// #23 0x000055555573094d in _mulle_objc_object_tryfinalizetrydealloc (obj=0x7fffec131bb0)
//     at /home/src/srcO/mulle-objc/mulle-objc-runtime/src/mulle-objc-retain-release.c:114
// #24 0x00005555556fe4fa in _mulle_objc_object_release_inline (obj=0x7fffec131bb0)
//     at /home/mulle-kybernetik-tv/.mulle/var/demos-4fd3f1c00ec5/dependency/Debug/include/mulle-objc-runtime/mulle-objc-retain-release.h:197
// #25 0x00005555556fe231 in -[MulleObjCRootObject release] (self=0x7fffec131bb0, _cmd=<incomplete type>)
//     at /home/src/srcO/mulle-objc/MulleObjC/src/protocol/MulleObjCRootObject.m:142
// #26 0x0000555555711104 in _mulle_objc_object_callback_class (obj=0x7fffec131bb0, methodid=57337825, parameter=0x7fffec131bb0,
//     cls=0x555556229d40) at /home/src/srcO/mulle-objc/mulle-objc-runtime/src/mulle-objc-call.c:428
// #27 0x00005555556c604f in mulle_objc_object_call_inline_partial (obj=0x7fffec131bb0, methodid=57337825, parameter=0x7fffec131bb0)
//     at /home/mulle-kybernetik-tv/.mulle/var/demos-4fd3f1c00ec5/dependency/Debug/include/mulle-objc-runtime/mulle-objc-call.h:239
// #28 _mulle_objc_object_call_release (obj=0x7fffec131bb0)
//     at /home/mulle-kybernetik-tv/.mulle/var/demos-4fd3f1c00ec5/dependency/Debug/include/mulle-objc-runtime/mulle-objc-retain-release.h:360
// #29 0x00005555556c589a in _mulle_autoreleasepointerarray_release_and_free (end=0x555556bed480, staticStorage=0x555556bed480,
//     object_map=0x5555560fe0e0) at /home/src/srcO/mulle-objc/MulleObjC/src/mulle-objc-autoreleasepointerarray-private.h:246
// #30 0x00005555556c256e in releaseAllObjectsInPool (config=0x5555560fe098, pool=0x555556bed440)
//     at /home/src/srcO/mulle-objc/MulleObjC/src/class/NSAutoreleasePool.m:898
// #31 0x00005555556bfef9 in popAutoreleasePool (config=0x5555560fe098, aPool=0x555556bed440)
//     at /home/src/srcO/mulle-objc/MulleObjC/src/class/NSAutoreleasePool.m:935
// #32 0x00005555556c284f in -[NSAutoreleasePool dealloc] (self=0x555556bed440, _cmd=<incomplete type>)
//     at /home/src/srcO/mulle-objc/MulleObjC/src/class/NSAutoreleasePool.m:1037
// #33 0x0000555555711104 in _mulle_objc_object_callback_class (obj=0x555556bed440, methodid=2569661245, parameter=0x555556bed440,
//     cls=0x55555620ca30) at /home/src/srcO/mulle-objc/mulle-objc-runtime/src/mulle-objc-call.c:428
// #34 0x0000555555720fb9 in _mulle_objc_object_handle_fastmethodtablefault (obj=0x555556bed440, methodid=2569661245, param=0x555556bed440,
//     index=3) at /home/src/srcO/mulle-objc/mulle-objc-runtime/src/mulle-objc-fastmethodtable.c:78
// #35 0x0000555555721095 in _mulle_objc_fastmethodtablefaulthandler_3 (obj=0x555556bed440, sel=2569661245, param=0x555556bed440)
//     at /home/src/srcO/mulle-objc/mulle-objc-runtime/src/mulle-objc-fastmethodtable.c:94
// #36 0x000055555572f639 in mulle_objc_implementation_invoke (parameter=0x555556bed440, sel=2569661245, self=0x555556bed440,
//     imp=0x555555721066 <_mulle_objc_fastmethodtablefaulthandler_3>)
//     at /home/src/srcO/mulle-objc/mulle-objc-runtime/src/mulle-objc-call.h:129
// #37 _mulle_objc_fastmethodtable_invoke (index=3, table=0x55555620cab0, param=0x555556bed440, methodid=2569661245, obj=0x555556bed440)
//     at /home/src/srcO/mulle-objc/mulle-objc-runtime/src/mulle-objc-call.h:201
// #38 mulle_objc_object_call_inline_partial (parameter=0x555556bed440, methodid=2569661245, obj=0x555556bed440)
//     at /home/src/srcO/mulle-objc/mulle-objc-runtime/src/mulle-objc-call.h:233
// #39 _mulle_objc_object_call_dealloc (obj=0x555556bed440) at /home/src/srcO/mulle-objc/mulle-objc-runtime/src/mulle-objc-retain-release.h:350
// #40 0x00005555557309e3 in _mulle_objc_object_tryfinalizetrydealloc (obj=0x555556bed440)
// --Type <RET> for more, q to quit, c to continue without paging--
//     at /home/src/srcO/mulle-objc/mulle-objc-runtime/src/mulle-objc-retain-release.c:124
// #41 0x00005555556c261a in _mulle_objc_object_release_inline (obj=0x555556bed440)
//     at /home/mulle-kybernetik-tv/.mulle/var/demos-4fd3f1c00ec5/dependency/Debug/include/mulle-objc-runtime/mulle-objc-retain-release.h:197
// #42 0x00005555556c25e8 in -[NSAutoreleasePool release] (self=0x555556bed440, _cmd=<incomplete type>)
//     at /home/src/srcO/mulle-objc/MulleObjC/src/class/NSAutoreleasePool.m:1017
// #43 0x000055555570fc41 in mulle_objc_object_call (obj=0x555556bed440, methodid=57337825, parameter=0x0)
//     at /home/src/srcO/mulle-objc/mulle-objc-runtime/src/mulle-objc-call.c:98
// #44 0x000055555576238a in -[UIPureWindow(ThreadRefresh) refresh] (self=0x555556287e60, _cmd=<incomplete type>)
//     at /home/src/srcO/MulleUI/MulleUIPureWindow/src/UIPureWindow+ThreadRefresh.m:176
// #45 0x000055555570fc41 in mulle_objc_object_call (obj=0x555556287e60, methodid=1327915853, parameter=0x0)
//     at /home/src/srcO/mulle-objc/mulle-objc-runtime/src/mulle-objc-call.c:98
// #46 0x0000555555768e4c in -[UIPureWindow(UIWindow) displayFrameIfNeeded:] (self=0x555556287e60, _cmd=<incomplete type>,
//     _param=0x7fffffffc870) at /home/src/srcO/MulleUI/MulleUIPureWindow/src/UIPureWindow+UIWindow.m:129
// #47 0x000055555570fc41 in mulle_objc_object_call (obj=0x555556287e60, methodid=3284848613, parameter=0x7fffffffc870)
//     at /home/src/srcO/mulle-objc/mulle-objc-runtime/src/mulle-objc-call.c:98
// #48 0x00005555557773ae in -[UIApplication runLoop] (self=0x555556230890, _cmd=<incomplete type>)
//     at /home/src/srcO/MulleUI/MulleUIApplication/src/UIApplication.m:1345
// #49 0x00005555557117ec in _mulle_objc_object_callback_cache_miss (obj=0x555556230890, methodid=189943689, parameter=0x0)
//     at /home/src/srcO/mulle-objc/mulle-objc-runtime/src/mulle-objc-call.c:538
// #50 0x000055555570fc41 in mulle_objc_object_call (obj=0x555556230890, methodid=189943689, parameter=0x0)
//     at /home/src/srcO/mulle-objc/mulle-objc-runtime/src/mulle-objc-call.c:98
// #51 0x0000555555777c9d in -[UIApplication runWindow:] (window=0x555556287e60)
//     at /home/src/srcO/MulleUI/MulleUIApplication/src/UIApplication.m:1457
// #52 0x000055555566747e in main (argc=1, argv=0x7fffffffcc98) at /home/src/srcO/MulleUI/MulleUIWindow/demo/src/main-window-view-draw.m:114
// (gdb)
//

#ifndef STYLEMASK
# define STYLEMASK   UIWindowStyleMaskDefault
#endif
#ifndef FRAMERATE
# define FRAMERATE   UIWindowFrameRateUnsynced
#endif

//
// This demo uses a frameCallback to draw stuff into an UIWindow without
// UIViews. It's a little more convenient, than doing it with GLFWOSWindow
// but not much. 
//
static CGColor  first_colors[ 3] =
{
   CGColorDataRed,
   CGColorDataBlack,
   CGColorDataYellow
};
static CGColor  second_colors[ 3] =
{
   CGColorDataWhite,
   CGColorDataRed,
   CGColorDataBlue
};

static CGColor  third_colors[ 3] =
{
   CGColorDataBlue,
   CGColorDataGold,
   CGColorDataRed
};
static void   drawStuff( CGContext *context, CGRect canvas)
{
   NSUInteger          color_index;
   NSUInteger          numberOfFrames;

   numberOfFrames = [context numberOfFrames];

  // MulleUICLog( "%tu canvas: %s, context: %#@", numberOfFrames,
  //                                              CGRectUTF8String( canvas),
  //                                              context);

   canvas.size.height /= 3.0;
   color_index         = numberOfFrames % 3;

   // red stripe
   CGContextBeginPath( context);
   CGContextRect( context, canvas);
   CGContextFillColor( context, first_colors[ color_index]);
   CGContextFill( context);

   // white stripe
   CGContextBeginPath( context);
   CGContextRect( context, CGRectMake(canvas.origin.x, canvas.origin.y + canvas.size.height * 1, canvas.size.width, canvas.size.height));
   CGContextFillColor( context, second_colors[ color_index]);
   CGContextFill( context);

   // blue stripe
   CGContextBeginPath( context);
   CGContextRect( context, CGRectMake(canvas.origin.x, canvas.origin.y + canvas.size.height * 2, canvas.size.width, canvas.size.height));
   CGContextFillColor( context, third_colors[ color_index]);
   CGContextFill( context);
}
static UIWindowDisplayBits   display( UIPureWindow *window,
                                      id <UIGraphicsContext> context,
                                      struct CGFrameInfo *frameInfo,
                                      UIWindowDisplayBits displayBits)
{
   drawStuff( (CGContext *) context, CGFrameInfoGetContentRect( frameInfo));
   return( 1);
}
int   main( int argc, char *argv[])
{
   UIWindow        *window;
   UIApplication   *app;

   app = [UIApplication sharedInstance];

   window = [UIWindow windowWithFrame:CGRectMake( 0.0, 0.0, 400.0, 400.0)
                      titleUTF8String:"Demo"
                            styleMask:STYLEMASK|UIWindowStyleNoView];
   assert( window);

   [window setFrameCallback:display];
   [window setFrameRate:FRAMERATE];
   [window setFrameDelegate:[MulleUIPerf instance]];
   return( [app runWindow:window]);
}

//
//                           ,╓≤æKª╨╙╙▓█D"╙╙╙*╨¥W▄╓,
//                      ╓▄ª╙└╧▓        █           ⁿ▓▓ª╦w
//                  ╓#╜^*█⌐   `╕       █           ╓▌    `╙%w
//               ╓ΦΓ      █    ╙⌐     ,█,,,Φ      ╓▌         ╙¥▄
//            ,▄▀ █▄       █µ,╓╝,╓≤╗≡≡ª╨╨╨¥≡∞╗w╓,ª█,  ,       ]▄▀V,
//          ,Φ└   ║"▀▄     ,▄▀╨"                 "╙¥▓▓       ▄▀  º▄¥,
//        ,#▌Φ▓▄╓  Φ `█Q▄M╙                           ╙¥▄ ,▄▀ ╙▄⌐`  `Φ
//       ▄▀   `V,"▀▀¼╓╩└                                 ╙¥▓╗ ,       ╙▄
//      Φ       `¥═▄▀                            ╒          ▀▄          ▓
//    .▓         ╓▓]V▄H       ▓                 ,Å            ▀,         ▀
//    █      ,-ª▓╛  `██▀½      "▄  ,╓╓╓╓;╓▄▄▄▄╗▄█,             ╙▄         ▀
//   █  `██▄   ▓. - Φ█═.~     ,≤█▄▀-      `   █└"▀▀▀▀▄╓╓╓╓       ▌    ██▄, █
//  ║⌐  " ▀   ▓╨⌐   }▀`      ,█  `           █      .█▀▄▄███▄     ▌  ` ▀    ▌
//  ▌        ▐M A   '┴      ▌                ▀        ╙█▌████▌    ╙▄        ║⌐
// ║⌐        █⌐'║▄ Γr2«    ║▀                 ▄▄▄      ╙▌▄███      █         ▌
// █]     ,▄▐H  ██████═ª  ╓` ▄█▀▀▀▀█▄        ████     ╓███` `╙╙║█  ▐H        █
// █ "% ,▄▀ ║░╠K█═╣███^   ╛╓█▀      ▐█         ,╓╓═ª╙└   █      ╙█▄▐▌▓######▌╫
// █║▄▄▄█▄▄▄║H:  "╙▀███▄╓▄,█▌╓▄,,▄∩  ██p$ΦΦ▀▀▀▀▀ΦΦΦR≡≥▄╓ ║▄       ╙j▌` ▄▀╙╗ `╫
// █"      ╙▐H-═M ▄███████¥█H "^╙    '█, ,«^``     `     ║▌        ▐M▄▀    "Φ█
// ║        !█▄▄████≤═^`╓█ █▌╓▀╦▄▀█   ╙█⌐               ╓█▌        ▓ `       █
//  ▌      ,▄██╫██ ▄█═╜" █▌▐█╣Hj⌐ █    █▌╙¥w,           ██▄       ╓▌        ▐M
//  ╢"▄▄#▀▀╙╟█Ü███▀`▀█  ║██J█▄▌jH █    ██    ╙▀W▄;    ,██  `╙w,   █▄     ,╓ █
//   █╙     ▐███▌▀█w ▀█ ╠██████j▌║█▌   ▀██▄       `╙▓██▀w,     ╙╗█'`"▀█▀╙"`║`
//   ╙▌     Φ████████▄██ ███████████    ═██▀W▄,   ╓█▀└         ╓▀ "    ╙▄ ╓▀
//    ╙▄     ╙▀███╙█▄▐██▄,╙▀█████▄▀▄▀▄   ,█M╗ ▀▄██▀╙""*ⁿ═─≈-,,▄▌,        ▄▀
//     `▌╙µ,▄Φ▀x███▄██████████▀V███▀╙└ ,▄#▌████▀`"*«,      .█▀▄▀▄,      ▄╛
//       ▀Ö█  ;▓████████▄▄█▀▄╙W "V▄██▀▀│▄███▀└ ▀╦     "*═╥▄▀ ║,  ║▀▄  ,▓
//        ╙W▀ '█████╨▀▀█████████   "▀▀████└      ╙▄   ,▄▀'   `▀▀╣H ▐▀▄▀
//          ╙▄  ▀▀Γ╓▌  ▄▀ⁿ`╙▀███      ██▌         ╓█R▀▄A█        ▀▀▄▀
//            ╙W,Φ╙  ║█        ▄╙╙ª%≡╦██≤≤╗╗≡≡╜▀▀   ╣▌   █╕     ,▄▀
//              `▀▄M█┘        ║▀▌   ╫"    *Φ▄  █       Φ` ▀▌, ▄M╙
//                 "▀╦,       M ╙▌  ▀       `█W▐▌       wæQ▄▀╙
//                     ╙▀W╥,╓╣   ╙█║        ╫M  █    ,╓▄╝╙`
//                          ╙╙▀%▄▄▄▌,≤▄_▄≡,▐▓▓▄▄#ª▀"`


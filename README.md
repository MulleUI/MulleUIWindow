# MulleUIWindow

Part of [MulleUI](https://github.com/MulleUI) — UIKit-shaped modular GUI libraries for mulle-objc.

#### 🎪 MulleUIWindow provides UIWindow and extends UIView functionality


See live on stream how it progresses: [Twitch](https://www.twitch.tv/mulle_kybernetik_tv/). Every Wednesday at 14:00-18:00 CEST.


![candycrash demo](demo/candycrash.png)

There is no actual "drawing" code in MulleUIWindow. Use "MulleGraphics" for
drawing. See "MulleUIControl" for widgets.

![mulle tiny logo](mulle-tiny-logo-255x256.png)





| Release Version                                       | Release Notes  | AI Documentation
|-------------------------------------------------------|----------------|---------------
| ![Mulle kybernetiK tag](https://img.shields.io/github/tag/MulleUI/MulleUIWindow.svg) [![Build Status](https://github.com/MulleUI/MulleUIWindow/workflows/CI/badge.svg)](//github.com/MulleUI/MulleUIWindow/actions) | [RELEASENOTES](RELEASENOTES.md) | [DeepWiki for MulleUIWindow](https://deepwiki.com/MulleUI/MulleUIWindow)




## Documentation & Guides

* [API Summary](asset/dox/api/toc)
* [Coder Guide](asset/howto/coder/mulle-ui-tracking)
* [Debugger Guide](asset/howto/debugger/mulle-ui-tracking)
* [Verifier Guide](asset/howto/verifier/mulle-ui-window)

## Usage

`UIWindow` is the top of the view hierarchy. Create one, attach it to the
application and run the event loop. All rendering happens in the `CALayer`s
that make up the window's views:

``` objc
#import <MulleUIWindow/MulleUIWindow.h>

int  main( void)
{
   UIApplication  *app;
   UIWindow       *window;

   app = [UIApplication sharedInstance];

   window = [UIWindow windowWithFrame:CGRectMake( 0.0, 0.0, 400.0, 300.0)
                      titleUTF8String:"Hello, MulleUIWindow"
                            styleMask:UIWindowStyleMaskDefault];

   [window setBackgroundColor:CGColorMakeWhite()];

   [app addWindow:window];
   return( [app runApp]);
}
```

There is no drawing code in MulleUIWindow itself: the window routes input
events through the responder chain and owns the views that make up its
content. If `UIWindowStylePlanes` is set, the window provides overlay
`UIWindowPlane`s — a `UIWindowPlane` is just a `UIView` — for content, menu,
tooltip, alert and drag-and-drop that stack on top of each other;
`contentPlane` is the window's `contentView`.

## Build the demo

The `demo/` folder is a [mulle-sde](//github.com/mulle-sde) project:

``` sh
cd demo
mulle-sde craft
```

# Introduction to MulleUIWindow Framework

The MulleUIWindow framework separates concerns between event handling
(UIWindow, UIView) and drawing (CALayer).

## UIWindow

UIWindow is the root container of an application's user interface:

- Manages the overall screen real estate
- Coordinates the display of content
- Routes events to the views below it

## UIView

UIViews form a hierarchy of interactive containers:

- Handle user interactions and respond to events
- Manage the layout of their subviews
- Update their visual representation based on user actions

A UIView does no drawing itself, that is delegated to its CALayers.

## CALayer

CALayer is solely dedicated to drawing and rendering:

- No handling of user interactions or event interpretation
- Efficient rendering and animation capabilities

## Key Architectural Points

1. **Clear Separation of Responsibilities**:
   - UIView: interaction and layout
   - CALayer: drawing and animation

2. **Process Design**:
   The animation and drawing of layers can run in a separate render thread.
   This limits callbacks to view code and keeps a clear boundary between
   visual rendering and logical operations.

## Component Hierarchy

```
UIWindow (at the top)
  |
  +-- UIView (contentPlane)
  |   |
  |   +-- CALayer 1
  |   +-- CALayer 2
  |
  +-- UIView (menuPlane)
      |
      +-- CALayer 3
      +-- CALayer 4
```

### You are here

![Overview](overview.dot.svg)





## Add

Use [mulle-sde](//github.com/mulle-sde) to add MulleUIWindow to your project:

``` sh
mulle-sde add github:MulleUI/MulleUIWindow
```

To only add the sources of MulleUIWindow with dependency
sources use [clib](https://github.com/clibs/clib):


``` sh
clib install --out src/MulleUI MulleUI/MulleUIWindow
```

Add `-isystem src/MulleUI` to your `CFLAGS` and compile all the sources that were downloaded with your project.


## Install

Use [mulle-sde](//github.com/mulle-sde) to build and install MulleUIWindow and all dependencies:

``` sh
mulle-sde install --prefix /usr/local \
   https://github.com/MulleUI/MulleUIWindow/archive/latest.tar.gz
```

### Legacy Installation

Install the requirements:

| Requirements                                 | Description
|----------------------------------------------|-----------------------
| [MulleUIPureWindow](https://github.com/MulleUI/MulleUIPureWindow)             | 🪑 MulleUIPureWindow - Windows without Views
| [MulleUIView](https://github.com/MulleUI/MulleUIView)             | ![](mulle-tiny-logo-255x256.png)
| [MulleCA](https://github.com/MulleUI/MulleCA)             | 🫧 Animate properties in real time with mulle-objc
| [mulle-objc-list](https://github.com/mulle-objc/mulle-objc-list)             | 📒 Lists mulle-objc runtime information contained in executables.

Download the latest [tar](https://github.com/MulleUI/MulleUIWindow/archive/refs/tags/latest.tar.gz) or [zip](https://github.com/MulleUI/MulleUIWindow/archive/refs/tags/latest.zip) archive and unpack it.

Install **MulleUIWindow** into `/usr/local` with [cmake](https://cmake.org):

``` sh
PREFIX_DIR="/usr/local"
cmake -B build                               \
      -DMULLE_SDK_PATH="${PREFIX_DIR}"       \
      -DCMAKE_INSTALL_PREFIX="${PREFIX_DIR}" \
      -DCMAKE_PREFIX_PATH="${PREFIX_DIR}"    \
      -DCMAKE_BUILD_TYPE=Release &&
cmake --build build --config Release &&
cmake --install build --config Release
```


## Author

[Nat!](https://mulle-kybernetik.com/weblog) for Mulle kybernetiK  




#import <MulleUIWindow/MulleUIWindow.h>

#include "../fake-ui-application-glue.inc"


int   main( void)
{
   UIWindow         *window;
   UIView           *view;
   UITrackingArea   *area1;
   UITrackingArea   *area2;
   UITrackingArea   *area3;
   UITrackingArea   *hits[8];
   NSUInteger       n;

   window = [UIWindow windowWithFrame:CGRectMake( 0, 0, 800, 600)];

   view = [[UIView new] autorelease];
   [view setFrame:CGRectMake( 0, 0, 400, 400)];
   [view setWindow:(id <UIWindow>) window];

   // area at (10,10)-(110,110)
   area1 = [UITrackingArea trackingAreaWithRect:CGRectMake( 10, 10, 100, 100)];
   [view addRetainedTrackingArea:[area1 retain]
                        toWindow:window];

   // area at (50,50)-(200,200) - overlaps area1
   area2 = [UITrackingArea trackingAreaWithRect:CGRectMake( 50, 50, 150, 150)];
   [view addRetainedTrackingArea:[area2 retain]
                        toWindow:window];

   // area at (300,300)-(380,380) - isolated
   area3 = [UITrackingArea trackingAreaWithRect:CGRectMake( 300, 300, 80, 80)];
   [view addRetainedTrackingArea:[area3 retain]
                        toWindow:window];

   // query rect that overlaps area1 and area2 but not area3
   n = [window getTrackingAreasIntersectingRect:CGRectMake( 60, 60, 20, 20)
                                          areas:hits
                                       maxAreas:8];
   mulle_printf( "query (60,60,20,20): %lu hits\n", (unsigned long) n);

   // query rect that hits only area3
   n = [window getTrackingAreasIntersectingRect:CGRectMake( 310, 310, 10, 10)
                                          areas:hits
                                       maxAreas:8];
   mulle_printf( "query (310,310,10,10): %lu hits\n", (unsigned long) n);

   // query rect that hits nothing
   n = [window getTrackingAreasIntersectingRect:CGRectMake( 200, 200, 10, 10)
                                          areas:hits
                                       maxAreas:8];
   mulle_printf( "query (200,200,10,10): %lu hits\n", (unsigned long) n);

   // query rect that hits all three
   n = [window getTrackingAreasIntersectingRect:CGRectMake( 0, 0, 400, 400)
                                          areas:hits
                                       maxAreas:8];
   mulle_printf( "query (0,0,400,400): %lu hits\n", (unsigned long) n);

   // test maxAreas limit: use buffer of 1
   n = [window getTrackingAreasIntersectingRect:CGRectMake( 0, 0, 400, 400)
                                          areas:hits
                                       maxAreas:1];
   mulle_printf( "query (0,0,400,400) maxAreas=1: %lu hits\n", (unsigned long) n);

   [view setWindow:nil];

   return( 0);
}

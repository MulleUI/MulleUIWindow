#import <MulleUIWindow/MulleUIWindow.h>

#include "../fake-ui-application-glue.inc"


int   main( void)
{
   UIWindow               *window;
   MulleInvocationQueue   *queue;
   NSInvocation           *invocation;

   window = [UIWindow instance];

   queue = [window invocationQueueForNameUTF8String:"whatevs"];
   if( ! queue)
   {
      queue = [MulleInvocationQueue invocationQueue];
      [window setInvocationQueue:queue
               forNameUTF8String:"whatevs"];
   }
   invocation = [NSInvocation instance];
   [queue addInvocation:invocation];
   [window removeInvocationQueueForNameUTF8String:"whatevs"];
   [window _doneInvocationQueues];

   return( 0);
}

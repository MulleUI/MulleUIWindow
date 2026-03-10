#import <MulleUIWindow/MulleUIWindow.h>


int   main( void)
{
   UIWindow               *window;
   MulleInvocationQueue   *queue;
   NSInvocation           *invocation;

   window = [UIWindow instance];
   [window _initInvocationQueues];

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

   return( 0);
}

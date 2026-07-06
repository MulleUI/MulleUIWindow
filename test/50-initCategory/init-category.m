#import <MulleUIWindow/MulleUIWindow.h>

#include "../fake-ui-application-glue.inc"

@interface UIWindow( TestCategoryA)
@property (dynamic, assign) int categoryAValue;
- (void) initCategory;
- (void) deallocCategory;
@end

@interface UIWindow( TestCategoryB)
@property (dynamic, assign) int categoryBValue;
- (void) initCategory;
- (void) deallocCategory;
@end

// Implementation for the first category
@implementation UIWindow( TestCategoryA)
MULLE_OBJC_DEPENDS_ON_CATEGORY( UIWindow, Render);
MULLE_OBJC_DEPENDS_ON_CATEGORY( UIWindow, Layout);

@dynamic categoryAValue;

// Instance method that will be called during UIWindow initialization
- (void) initCategory
{
   mulle_printf( "UIWindow(TestCategoryA): initCategory called\n");
   // Initialize with a default value if you want
   [self setCategoryAValue:21];
}

// Instance method that will be called during UIWindow deallocation
- (void) deallocCategory
{
   mulle_printf( "UIWindow(TestCategoryA): deallocCategory called\n");
}
@end

// Implementation for the second category with dependency on the first
@implementation UIWindow( TestCategoryB)
MULLE_OBJC_DEPENDS_ON_CATEGORY( UIWindow, TestCategoryA);
MULLE_OBJC_DEPENDS_ON_CATEGORY( UIWindow, Render);
MULLE_OBJC_DEPENDS_ON_CATEGORY( UIWindow, Layout);

@dynamic categoryBValue;

- (void) initCategory
{
   mulle_printf( "UIWindow(TestCategoryB): initCategory called\n");
   // Initialize with a default value if you want
   [self setCategoryBValue:42];
}

- (void) deallocCategory
{
   mulle_printf( "UIWindow(TestCategoryB): deallocCategory called\n");
}
@end

int main(void)
{
   mulle_printf( "=== Testing UIWindow Category Initialization ===\n");
   mulle_printf( "Creating a UIWindow to verify its automatic category initialization...\n");

   // UIWindow should automatically call -initCategory on all categories
   // during instance initialization
   UIWindow *window = [UIWindow new];
   mulle_printf( "UIWindow created\n");

   // Check if our properties have default values from initCategory
   mulle_printf( "\nDefault property values from initCategory:\n");
   mulle_printf( "Category A value: %d\n", [window categoryAValue]);
   mulle_printf( "Category B value: %d\n", [window categoryBValue]);

   // Update properties
   mulle_printf( "\nUpdating property values...\n");
   [window setCategoryAValue:84];
   [window setCategoryBValue:200];

   mulle_printf( "After modification:\n");
   mulle_printf( "Category A value: %d\n", [window categoryAValue]);
   mulle_printf( "Category B value: %d\n", [window categoryBValue]);

   mulle_printf( "\nDeallocating UIWindow...\n");
   // When UIWindow is deallocated, it should call -deallocCategory
   // on all categories automatically
   [window release];
   mulle_printf( "UIWindow deallocated\n");

   mulle_printf( "\n=== Test Complete ===\n");

   return 0;
}
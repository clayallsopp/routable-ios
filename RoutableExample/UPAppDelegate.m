//
//  UPAppDelegate.m
//  Routable
//
//  Created by Clay Allsopp on 4/3/13.
//  Copyright (c) 2013 TurboProp Inc. All rights reserved.
//

#import "UPAppDelegate.h"
#import "Routable.h"

@interface UserController : UIViewController

@end

@implementation UserController

- (id)initWithRouterParams:(NSDictionary *)params {
  if ((self = [self initWithNibName:nil bundle:nil])) {
    self.title = @"User";
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];

  UIButton *modal = [UIButton buttonWithType:UIButtonTypeRoundedRect];
  [modal setTitle:@"Modal" forState:UIControlStateNormal];
  [modal addTarget:self action:@selector(tapped:) forControlEvents:UIControlEventTouchUpInside];
  [modal sizeToFit];
  [modal setFrame:CGRectMake(0, self.view.bounds.size.height - modal.frame.size.height, modal.frame.size.width, modal.frame.size.height)];

  [self.view addSubview:modal];
}

- (void)tapped:(id)sender {
  [[Routable sharedRouter] open:@"modal"];
}

@end

@interface ModalController : UIViewController

@end

@implementation ModalController

- (id)initWithRouterParams:(NSDictionary *)params {
  if ((self = [self initWithNibName:nil bundle:nil])) {
    self.title = @"Modal";
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];

  UIButton *modal = [UIButton buttonWithType:UIButtonTypeRoundedRect];
  [modal setTitle:@"Close" forState:UIControlStateNormal];
  [modal addTarget:self action:@selector(tapped:) forControlEvents:UIControlEventTouchUpInside];
  [modal sizeToFit];
  [modal setFrame:CGRectMake(0, self.view.bounds.size.height - modal.frame.size.height, modal.frame.size.width, modal.frame.size.height)];
  [self.view addSubview:modal];

  UIButton *user = [UIButton buttonWithType:UIButtonTypeRoundedRect];
  [user setTitle:@"User" forState:UIControlStateNormal];
  [user addTarget:self action:@selector(tappedUser:) forControlEvents:UIControlEventTouchUpInside];
  [user sizeToFit];
  [user setFrame:CGRectMake(self.view.bounds.size.width - user.frame.size.width , self.view.bounds.size.height - user.frame.size.height, user.frame.size.width, user.frame.size.height)];

  [self.view addSubview:user];
}

- (void)tapped:(id)sender {
  [[Routable sharedRouter] pop];
}

- (void)tappedUser:(id)sender {
  [[Routable sharedRouter] open:@"user"];
}

@end

@implementation UPAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];

    UINavigationController *nav = [[UINavigationController alloc] initWithNibName:nil bundle:nil];
    [[Routable sharedRouter] map:@"user" toController:[UserController class]];
    [[Routable sharedRouter] map:@"modal" toController:[ModalController class] withOptions:[[UPRouterOptions modal] withPresentationStyle:UIModalPresentationFormSheet]];
    [[Routable sharedRouter] setNavigationController:nav];

    [self.window setRootViewController:nav];
    [self.window makeKeyAndVisible];

    [[Routable sharedRouter] open:@"user"];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
  // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
  // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
  // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
  // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
  // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
  // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
  // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end

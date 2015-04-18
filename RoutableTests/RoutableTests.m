//
//  RoutableTests.m
//  RoutableTests
//
//  Created by Clay Allsopp on 4/3/13.
//  Copyright (c) 2013 TurboProp Inc. All rights reserved.
//

#import "RoutableTests.h"
#import "Routable.h"

@interface UserController : UIViewController

@property (readwrite, nonatomic, copy) NSString *userId;
@property (readwrite, nonatomic, copy) NSString *userName;

- (id)initWithRouterParams:(NSDictionary *)params;
@end

@implementation UserController

- (id)initWithRouterParams:(NSDictionary *)params {
  if ((self = [self initWithNibName:nil bundle:nil])) {
    self.userId = [params objectForKey:@"user_id"];
    self.userName = [params objectForKey:@"user_name"];
  }
  return self;
}

@end

@interface StaticController : UIViewController

@property (readwrite, nonatomic, copy) NSString *userId;

+ (id)allocWithRouterParams:(NSDictionary *)params;
@end

@implementation StaticController

+ (id)allocWithRouterParams:(NSDictionary *)params {
  StaticController *instance = [[StaticController alloc] initWithNibName:nil bundle:nil];
  instance.userId = [params objectForKey:@"user_id"];

  return instance;
}

@end

@interface RoutableTests()
@property (readwrite, nonatomic, strong) UPRouter *router;
@end

#define USER_ID [(UserController *)self.router.navigationController.topViewController userId]
#define USER_NAME [(UserController *)self.router.navigationController.topViewController userName]
#define STATIC_USER_ID [(StaticController *)self.router.navigationController.topViewController userId]

@implementation RoutableTests
@synthesize router = _router;

- (void)setUp {
  [super setUp];
    
  self.router = [Routable newRouter];
  self.router.navigationController = [[UINavigationController alloc] initWithNibName: nil bundle: nil];
}

- (void)tearDown {
  // Tear-down code here.
  [self.router.navigationController setViewControllers:[NSArray array]];
  self.router = nil;
    
  [super tearDown];
}

- (void)test_basicRoute {
  [self.router map:@"users/:user_id" toController:[UserController class]];
  
  [self.router open:@"users/4"];
  
  XCTAssertTrue([USER_ID isEqualToString:@"4"], @"Should have an ID of 4");
}

- (void)test_basicRouteWithMultipleComponents {
    [self.router map:@"users/:user_id/:user_name" toController:[UserController class]];
    
    [self.router open:@"users/4/clay"];
    
    XCTAssertTrue([USER_ID isEqualToString:@"4"], @"Should have an ID of 4");
    XCTAssertTrue([USER_NAME isEqualToString:@"clay"], @"Name should be Clay");
}

- (void)test_basicRouteWithEmptyComponents {
    [self.router map:@"users/:user_id/:user_name" toController:[UserController class]];
    
    [self.router open:@"users//clay"];
    
    XCTAssertTrue([USER_ID isEqualToString:@""], @"Should have an empty ID");
    XCTAssertTrue([USER_NAME isEqualToString:@"clay"], @"Name should be Clay");

    [self.router open:@"users/ /clay"];
    XCTAssertTrue([USER_ID isEqualToString:@" "], @"Should have an empty ID");
    XCTAssertTrue([USER_NAME isEqualToString:@"clay"], @"Name should be Clay");
}

- (void)test_emptyRoute {
  [self.router map:@"users" toController:[UserController class]];
  
  [self.router open:@"users"];
  
  XCTAssertNil(USER_ID, @"The user id should be nil, not %@", USER_ID);
}

- (void)test_invalidRoute {
  XCTAssertThrows([self.router open:@"users"], @"Should throw an exception when route not mapped");
}

- (void)test_noNavigationController {
  [self.router map:@"users" toController:[UserController class]];

  self.router.navigationController = nil;
  XCTAssertThrows([self.router open:@"users"], @"Should throw an exception when there is no navigation controller");
}

- (void)test_callbacks {
  __block BOOL called = false;
  [self.router map:@"users" toCallback:^(NSDictionary *params) {
    called = true;
  }];
  
  [self.router open:@"users"];
  
  XCTAssertTrue(called, @"Callback block should have been called");
}

- (void)test_callbacksWithParams {
  __block NSString *userId = nil;
  __block BOOL called = false;
  [self.router map:@"users/:id" toCallback:^(NSDictionary *params) {
    called = true;
    userId = [params objectForKey:@"id"];
  }];
  
  [self.router open:@"users/4"];
  
  XCTAssertTrue(called, @"Callback block should have been called");
  XCTAssertTrue([userId isEqualToString:@"4"], @"Callback should have correct id param; was %@", userId);
}

- (void)test_defaultParamsWithCallback {
  __block NSString *userId = nil;
  
  [self.router map:@"users" toCallback:^(NSDictionary *params) {
    userId = [params objectForKey:@"id"];
  } withOptions: [UPRouterOptions forDefaultParams:@{@"id": @"4"}]];
  
  [self.router open:@"users"];
  
  XCTAssertTrue([userId isEqualToString:@"4"], @"Callback should have correct id param; was %@", userId);
}

- (void)test_staticRoute {  
  [self.router map:@"users/:user_id" toController:[StaticController class]];
  
  [self.router open:@"users/4"];
  
  XCTAssertTrue([self.router.navigationController.topViewController isKindOfClass:[StaticController class]], @"Should be an instance of StaticController");
  XCTAssertTrue([STATIC_USER_ID isEqualToString:@"4"], @"Should have an ID of 4");  
}

- (void)test_noInitializers {
  [self.router map:@"routable" toController:[UIViewController class]];
  
  XCTAssertThrows([self.router open:@"routable"], @"Should throw an exception when no initializer found");
}

- (void)test_openAsRoot {
    [self.router map:@"users/:user_id" toController:[UserController class] withOptions:[UPRouterOptions root]];
    
    [self.router open:@"users/4"];
    
    XCTAssertTrue([self.router.navigationController.viewControllers[0] isKindOfClass:[UserController class]], @"Should be an instance of UserController");
    XCTAssertTrue(self.router.navigationController.viewControllers.count == 1, @"Navigation controller should only have 1 view controller in its stack");
}

@end

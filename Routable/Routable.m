//
//  Routable.m
//  Routable
//
//  Created by Clay Allsopp on 4/3/13.
//  Copyright (c) 2013 TurboProp Inc. All rights reserved.
//

#import "Routable.h"

@implementation Routable

+ (UPRouter *)sharedRouter {
  static UPRouter *_sharedRouter = nil;
  static dispatch_once_t oncePredicate;
  dispatch_once(&oncePredicate, ^{
    _sharedRouter = [self newRouter];
  });
  
  return _sharedRouter;
}

+ (UPRouter *)newRouter {
  return [UPRouter new];
}

@end

@interface RouterParams : NSObject
@property (readwrite, nonatomic, strong) UPRouterOptions *routerOptions;
@property (readwrite, nonatomic, strong) NSDictionary *openParams;
@end

@implementation RouterParams
@synthesize routerOptions = _routerOptions;
@synthesize openParams = _openParams;

- (NSDictionary *)getControllerParams {
  NSMutableDictionary *controllerParams = [NSMutableDictionary new];
  
  [controllerParams addEntriesFromDictionary:self.routerOptions.defaultParams];
  [controllerParams addEntriesFromDictionary:self.openParams];
  
  return controllerParams;
}

@end

@interface UPRouterOptions ()
@property (readwrite, nonatomic, strong) Class openClass;
@property (readwrite, nonatomic, copy) RouterOpenCallback callback;
@end

@implementation UPRouterOptions

@synthesize modal = _modal;
@synthesize defaultParams = _defaultParams;
@synthesize openClass = _openClass;
@synthesize callback = _callback;

+ (UPRouterOptions *)modal {
  return [[UPRouterOptions new] modal];
}

+ (UPRouterOptions *)withPresentationStyle:(UIModalPresentationStyle)style {
  return [[UPRouterOptions new] withPresentationStyle:style];
}

+ (UPRouterOptions *)withTransitionStyle:(UIModalTransitionStyle)style {
  return [[UPRouterOptions new] withTransitionStyle:style];
}

+ (UPRouterOptions *)forDefaultParams:(NSDictionary *)defaultParams {
  return [[UPRouterOptions new] forDefaultParams:defaultParams];
}

- (UPRouterOptions *)modal {
  self.modal = true;
  return self;
}

- (UPRouterOptions *)withPresentationStyle:(UIModalPresentationStyle)style {
  self.presentationStyle = style;
  return self;
}

- (UPRouterOptions *)withTransitionStyle:(UIModalTransitionStyle)style {
  self.transitionStyle = style;
  return self;
}

- (UPRouterOptions *)forDefaultParams:(NSDictionary *)defaultParams {
  self.defaultParams = defaultParams;
  return self;
}


@end

@interface UPRouter ()

// Map of URL format NSString -> RouterOptions
// i.e. "users/:id"
@property (readwrite, nonatomic, strong) NSMutableDictionary *routes;
// Map of final URL NSStrings -> RouterParams
// i.e. "users/16"
@property (readwrite, nonatomic, strong) NSMutableDictionary *cachedRoutes;

@end

#define ROUTE_NOT_FOUND_FORMAT @"No route found for URL %@"
#define INVALID_CONTROLLER_FORMAT @"Your controller class %@ needs to implement %@"

#define CONTROLLER_SELECTOR @selector(initWithRouterParams:)

@implementation UPRouter

@synthesize navigationController = _navigationController;
@synthesize routes = _routes;
@synthesize cachedRoutes = _cachedRoutes;

- (id)init {
  if ((self = [super init])) {
    self.routes = [NSMutableDictionary new];
    self.cachedRoutes = [NSMutableDictionary new];
  }

  return self;
}

- (void)map:(NSString *)format toCallback:(RouterOpenCallback)callback {
  [self map:format toCallback:callback withOptions:nil];
}

- (void)map:(NSString *)format toCallback:(RouterOpenCallback)callback withOptions:(UPRouterOptions *)options {
  if (!options) {
    options = [UPRouterOptions new];
  }
  options.callback = callback;
  [self.routes setObject:options forKey:format];
}

- (void)map:(NSString *)format toController:(Class)controllerClass {
  [self map:format toController:controllerClass withOptions:nil];
}

- (void)map:(NSString *)format toController:(Class)controllerClass withOptions:(UPRouterOptions *)options {
  if (!options) {
    options = [UPRouterOptions new];
  }
  options.openClass = controllerClass;
  [self.routes setObject:options forKey:format];
}

- (void)openExternal:(NSString *)url {
  [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
}

- (void)open:(NSString *)url {
  [self open:url animated:YES];
}

- (void)open:(NSString *)url animated:(BOOL)animated {
  RouterParams *params = [self routerParamsForUrl:url];
  UPRouterOptions *options = params.routerOptions;
  
  if (options.callback) {
    RouterOpenCallback callback = options.callback;
    callback([params getControllerParams]);
    return;
  }
  
  if (!self.navigationController) {
    @throw [NSException exceptionWithName:@"NavigationControllerNotProvided"
                                   reason:@"Router#navigationController has not been set to a UINavigationController instance"
                                 userInfo:nil];
  }
  
  UIViewController *controller = [self controllerForRouterParams:params];
  
  if (self.navigationController.presentedViewController) {
    [self.navigationController dismissViewControllerAnimated:animated completion:nil];
  }
  
  if ([options isModal]) {
    if ([controller.class isSubclassOfClass:UINavigationController.class]) {
      [self.navigationController presentViewController:controller
                                              animated:animated
                                            completion:nil];
    }
    else {
      UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
      navigationController.modalPresentationStyle = controller.modalPresentationStyle;
      navigationController.modalTransitionStyle = controller.modalTransitionStyle;
      [self.navigationController presentViewController:navigationController
                                              animated:animated
                                            completion:nil];
    }
  }
  else {
    [self.navigationController pushViewController:controller animated:animated];
  }
}

- (void)pop {
  [self pop:YES];
}

- (void)pop:(BOOL)animated {
  if (self.navigationController.presentedViewController) {
    [self.navigationController dismissViewControllerAnimated:animated completion:nil];
  }
  else {
    [self.navigationController popViewControllerAnimated:animated];
  }
}

///////

- (RouterParams *)routerParamsForUrl:(NSString *)url {
  if ([self.cachedRoutes objectForKey:url]) {
    return [self.cachedRoutes objectForKey:url];
  }
  
  NSArray *givenParts = [url componentsSeparatedByString:@"/"];
  
  RouterParams *openParams = nil;
  for (NSString *routerUrl in self.routes.allKeys) {
    UPRouterOptions *routerOptions = (UPRouterOptions *)[self.routes objectForKey:routerUrl];
    NSArray *routerParts = [routerUrl componentsSeparatedByString:@"/"];
    
    if (routerParts.count != givenParts.count) {
      continue;
    }
    
    NSDictionary *givenParams = [self paramsForUrlComponents:givenParts withRouterUrlComponents:routerParts];
    if (!givenParams) {
      continue;
    }
    
    openParams = [RouterParams new];
    openParams.openParams = givenParams;
    openParams.routerOptions = routerOptions;
    break;
  }
  
  if (!openParams) {
    @throw [NSException exceptionWithName:@"RouteNotFoundException"
                                   reason:[NSString stringWithFormat:ROUTE_NOT_FOUND_FORMAT, url]
                                 userInfo:nil];
  }
  
  [self.cachedRoutes setObject:openParams forKey:url];
  
  return openParams;
}

- (NSDictionary *)paramsForUrlComponents:(NSArray *)givenUrlComponents
                 withRouterUrlComponents:(NSArray *)routerUrlComponents {
  NSMutableDictionary *params = [NSMutableDictionary new];
  
  for (int i = 0; i < routerUrlComponents.count; i++) {
    NSString *routerComponent = routerUrlComponents[i];
    NSString *givenComponent = givenUrlComponents[i];
    
    if ([[routerComponent substringToIndex:1] isEqualToString:@":"]) {
      NSString *key = [routerComponent substringFromIndex:1];
      [params setObject:givenComponent forKey:key];
      continue;
    }
    
    if (![routerComponent isEqualToString:givenComponent]) {
      return nil;
    }
  }
  
  return params;
}

- (UIViewController *)controllerForRouterParams:(RouterParams *)params {
  UIViewController *controller = [params.routerOptions.openClass alloc];
  
  if ([controller respondsToSelector:CONTROLLER_SELECTOR]) {
    controller = [controller performSelector:CONTROLLER_SELECTOR withObject:[params getControllerParams]];
  }
  else {
    @throw [NSException exceptionWithName:@"RoutableInitializerNotFound"
                                   reason:[NSString stringWithFormat:INVALID_CONTROLLER_FORMAT, NSStringFromClass([controller class]), NSStringFromSelector(CONTROLLER_SELECTOR)]
                                 userInfo:nil];
  }
  
  controller.modalTransitionStyle = params.routerOptions.transitionStyle;
  controller.modalPresentationStyle = params.routerOptions.presentationStyle;
  
  return controller;
}

@end

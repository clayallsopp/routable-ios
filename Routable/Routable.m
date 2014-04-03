//
//  Routable.m
//  Routable
//
//  Created by Clay Allsopp on 4/3/13.
//  Copyright (c) 2013 TurboProp Inc. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "Routable.h"

@implementation Routable

+ (instancetype)sharedRouter {
  static Routable *_sharedRouter = nil;
  static dispatch_once_t oncePredicate;
  dispatch_once(&oncePredicate, ^{
    _sharedRouter = [self newRouter];
  });
  return _sharedRouter;
}

+ (instancetype)newRouter {
  return [self new];
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

+ (instancetype)modal {
  return [[self new] modal];
}

+ (instancetype)withPresentationStyle:(UIModalPresentationStyle)style {
  return [[self new] withPresentationStyle:style];
}

+ (instancetype)withTransitionStyle:(UIModalTransitionStyle)style {
  return [[self new] withTransitionStyle:style];
}

+ (instancetype)forDefaultParams:(NSDictionary *)defaultParams {
  return [[self new] forDefaultParams:defaultParams];
}

+ (instancetype)root {
    return [[self new] root];
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

- (UPRouterOptions *)root {
    self.shouldOpenAsRootViewController = YES;
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
#define INVALID_CONTROLLER_FORMAT @"Your controller class %@ needs to implement either the static method %@ or the instance method %@"

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
    if (_ignoresExceptions) {
      return;
    }
    
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
      if (options.shouldOpenAsRootViewController) {
          [self.navigationController setViewControllers:@[controller] animated:animated];
      }
      else {
          [self.navigationController pushViewController:controller animated:animated];
      }
  }
}

- (NSDictionary*)paramsOfUrl:(NSString*)url{
    RouterParams *params = [self routerParamsForUrl:url];
    return [params getControllerParams];
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
  
  NSArray *givenParts = url.pathComponents;
  NSArray *legacyParts = [url componentsSeparatedByString:@"/"];
  if ([legacyParts count] != [givenParts count]) {
    NSLog(@"Routable Warning - your URL %@ has empty path components - this will throw an error in an upcoming release", url);
    givenParts = legacyParts;
  }
  
  RouterParams *openParams = nil;
  for (NSString *routerUrl in self.routes.allKeys) {
    UPRouterOptions *routerOptions = (UPRouterOptions *)[self.routes objectForKey:routerUrl];
    NSArray *routerParts = routerUrl.pathComponents;
    
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
    if (_ignoresExceptions) {
      return nil;
    }
    
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
  
  for (NSUInteger i = 0; i < routerUrlComponents.count; i++) {
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
  SEL CONTROLLER_CLASS_SELECTOR = sel_registerName("allocWithRouterParams:");
  SEL CONTROLLER_SELECTOR = sel_registerName("initWithRouterParams:");
  UIViewController *controller = nil;
  Class controllerClass = params.routerOptions.openClass;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
  if ([controllerClass respondsToSelector:CONTROLLER_CLASS_SELECTOR]) {
    controller = [controllerClass performSelector:CONTROLLER_CLASS_SELECTOR withObject:[params getControllerParams]];
  }
  else {
    controller = [params.routerOptions.openClass alloc];
    if ([controller respondsToSelector:CONTROLLER_SELECTOR]) {
      controller = [controller performSelector:CONTROLLER_SELECTOR withObject:[params getControllerParams]];
    }
    else {
      controller = nil;
    }
  }
#pragma clang diagnostic pop

  if (controller == nil) {
    if (_ignoresExceptions) {
      return nil;
    }
    
    @throw [NSException exceptionWithName:@"RoutableInitializerNotFound"
                                   reason:[NSString stringWithFormat:INVALID_CONTROLLER_FORMAT, NSStringFromClass(controllerClass), NSStringFromSelector(CONTROLLER_CLASS_SELECTOR),  NSStringFromSelector(CONTROLLER_SELECTOR)]
                                 userInfo:nil];
  }
  
  controller.modalTransitionStyle = params.routerOptions.transitionStyle;
  controller.modalPresentationStyle = params.routerOptions.presentationStyle;
  
  return controller;
}

@end

//
//  Routable.h
//  Routable
//
//  Created by Clay Allsopp on 4/3/13.
//  Copyright (c) 2013 TurboProp Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class UPRouter;

/**
 `Routable` is a "factory" class which gives a more pleasant syntax for dealing with routers. `Routable` probably has fewer name collisions than `Router`, which is why `UPRouter`s are given a 2-letter prefix.
 */

@interface Routable : NSObject

/**
 A singleton instance of `UPRouter` which can be accessed anywhere in the app.
 @return A singleton instance of `UPRouter`.
 */
+ (UPRouter *)sharedRouter;

/**
 A new instance of `UPRouter`, in case you want to use multiple routers in your app.
 @return A new instance of `UPRouter`.
 */
+ (UPRouter *)newRouter;

@end

typedef void (^RouterOpenCallback)(NSDictionary *params);

/**
 `UPRouterOptions` allows you to configure specific behavior for each router callback, such transition behaviors or default URL parameters.
 
 `UPRouterOptions` has a chainable factory DSL which gives a more pleasant syntax for giving specific configurations, like:
 
 ```
 UPRouterOptions *options = [[UPRouterOptions modal] withPresentationStyle: UIModalPresentationFormSheet];
 ```
 */

@interface UPRouterOptions : NSObject

///-------------------------------
/// @name Options DSL
///-------------------------------

/**
 @return A new instance of `UPRouterOptions`, setting a modal presentation format.
 */
+ (UPRouterOptions *)modal;
/**
 @return A new instance of `UPRouterOptions`, setting a `UIModalPresentationStyle` style.
 @param style The `UIModalPresentationStyle` attached to the mapped `UIViewController`
 */
+ (UPRouterOptions *)withPresentationStyle:(UIModalPresentationStyle)style;
/**
 @return A new instance of `UPRouterOptions`, setting a `UIModalTransitionStyle` style.
 @param style The `UIModalTransitionStyle` attached to the mapped `UIViewController`
 */
+ (UPRouterOptions *)withTransitionStyle:(UIModalTransitionStyle)style;
/**
 @return A new instance of `UPRouterOptions`, setting the defaultParams
 @param defaultParams The default parameters which are passed when opening the URL
 */
+ (UPRouterOptions *)forDefaultParams:(NSDictionary *)defaultParams;

/**
 @return The same instance of `UPRouterOptions`, setting a modal presentation format.
 */
- (UPRouterOptions *)modal;
/**
 @return The same instance of `UPRouterOptions`, setting a `UIModalPresentationStyle` style.
 @param style The `UIModalPresentationStyle` attached to the mapped `UIViewController`
 */
- (UPRouterOptions *)withPresentationStyle:(UIModalPresentationStyle)style;
/**
 @return The same instance of `UPRouterOptions`, setting a `UIModalTransitionStyle` style.
 @param style The `UIModalTransitionStyle` attached to the mapped `UIViewController`
 */
- (UPRouterOptions *)withTransitionStyle:(UIModalTransitionStyle)style;
/**
 @return The same instance of `UPRouterOptions`, setting the defaultParams
 @param defaultParams The default parameters which are passed when opening the URL
 */
- (UPRouterOptions *)forDefaultParams:(NSDictionary *)defaultParams;

///-------------------------------
/// @name Properties
///-------------------------------

/**
 The property determining if the mapped `UIViewController` should be opened modally or pushed in the navigation stack.
 */
@property (readwrite, nonatomic, getter=isModal) BOOL modal;
/**
 The property determining the `UIModalPresentationStyle` assigned to the mapped `UIViewController` instance. This is always assigned, regardless of whether or not `modal` is true.
 */
@property (readwrite, nonatomic) UIModalPresentationStyle presentationStyle;
/**
 The property determining the `UIModalTransitionStyle` assigned to the mapped `UIViewController` instance. This is always assigned, regardless of whether or not `modal` is true.
 */
@property (readwrite, nonatomic) UIModalTransitionStyle transitionStyle;
/**
 Default parameters sent to the `UIViewController`'s initWithRouterParams: method. This is useful if you want to pass some non-`NSString` information. These parameters will be overwritten by any parameters passed in the URL in open:.
 */
@property (readwrite, nonatomic, strong) NSDictionary *defaultParams;

@end

/**
 `UPRouter` is the main class you interact with to map URLs to either opening `UIViewController`s or running anonymous functions.
 
 For example:

     [[Routable sharedRouter] map:@"users/:id" toController:[UserController class]];
     [[Routable sharedRouter] setNavigationController: aNavigationController];
     
     // In UserController.m
     @implementation UserController
     
     // params will be non-nil
     - (id)initWithParams:(NSDictionary *)params {
       if ((self = [self initWithNibName:nil bundle:nil])) {
         self.userId = [params objectForKey:@"id"];
       }
       return self;
     }
 
 Anonymous methods can also be routed:

     [[Routable sharedRouter] map:@"logout" toCallback:^(NSDictionary *params) {
       [User logout];
     }];
     
     [[Routable sharedRouter] map:@"invalidate/:id" toCallback:^(NSDictionary *params) {
       [Cache invalidate: [params objectForKey:@"id"]]];
     }];
 
 */
@interface UPRouter : NSObject

///-------------------------------
/// @name Navigation Controller
///-------------------------------

/**
 The `UINavigationController` instance which mapped `UIViewController`s will be pushed onto.
 */
@property (readwrite, nonatomic, strong) UINavigationController *navigationController;

///-------------------------------
/// @name Mapping URLs
///-------------------------------

/**
 Map a URL format to an anonymous callback
 @param format A URL format (i.e. "users/:id" or "logout")
 @param callback The callback to run when the URL is triggered in `open:`
 */
- (void)map:(NSString *)format toCallback:(RouterOpenCallback)callback;
/**
 Map a URL format to an anonymous callback and `UPRouterOptions` options
 @param format A URL format (i.e. "users/:id" or "logout")
 @param callback The callback to run when the URL is triggered in `open:`
 @param options Configuration for the route
 */
- (void)map:(NSString *)format toCallback:(RouterOpenCallback)callback withOptions:(UPRouterOptions *)options;
/**
 Map a URL format to an anonymous callback and `UPRouterOptions` options
 @param format A URL format (i.e. "users/:id" or "logout")
 @param controllerClass The `UIViewController` `Class` which will be instanstiated when the URL is triggered in `open:`
 */
- (void)map:(NSString *)format toController:(Class)controllerClass;
/**
 Map a URL format to an anonymous callback and `UPRouterOptions` options
 @param format A URL format (i.e. "users/:id" or "logout")
 @param controllerClass The `UIViewController` `Class` which will be instanstiated when the URL is triggered in `open:`
 @param options Configuration for the route, such as modal settings
 */
- (void)map:(NSString *)format toController:(Class)controllerClass withOptions:(UPRouterOptions *)options;

///-------------------------------
/// @name Opening URLs
///-------------------------------

/**
 A convenience method for opening a URL using `UIApplication` `openURL:`.
 @param url The URL the OS will open (i.e. "http://google.com")
 */
- (void)openExternal:(NSString *)url;

/**
 Triggers the appropriate functionality for a mapped URL, such as an anonymous function or opening a `UIViewController`
 @param url The URL being opened (i.e. "users/16") 
 @exception RouteNotFoundException Thrown if url does not have a valid mapping
 @exception NavigationControllerNotProvided Thrown if url opens a `UIViewController` and navigationController has not been assigned
 @exception RoutableInitializerNotFound Thrown if the mapped `UIViewController` instance does not implement initWithParams:
 */
- (void)open:(NSString *)url;

@end

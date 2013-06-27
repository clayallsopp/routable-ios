//
//  Routable.h
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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

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
     - (id)initWithRouterParams:(NSDictionary *)params {
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
 
 If you wish to do custom allocation of a controller, you can use allocWithRouterParams:
 
     [[Routable sharedRouter] map:@"users/:id" toController:[StoryboardController class]];
 
     @implementation StoryboardController
     
     + (id)allocWithRouterParams:(NSDictionary *)params {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Storyboard" bundle:nil];
        StoryboardController *instance = [storyboard instantiateViewControllerWithIdentifier:@"sbController"];
        instance.userId = [params objectForKey:@"id"];
 
        return instance;
     }
 
 */
@interface UPRouter : NSObject

///-------------------------------
/// @name Navigation Controller
///-------------------------------

/**
 The `UINavigationController` instance which mapped `UIViewController`s will be pushed onto.
 */
@property (readwrite, nonatomic, strong) UINavigationController *navigationController;

/**
 Pop to the last `UIViewController` mapped with the router; this will either dismiss the presented `UIViewController` (i.e. modal) or pop the top view controller in the navigationController. The transition is animated.
 */
- (void)pop;

/**
 Pop to the last `UIViewController` mapped with the router; this will either dismiss the presented `UIViewController` (i.e. modal) or pop the top view controller in the navigationController.
 @param animated Whether or not the transition is animated;
 */
- (void)pop:(BOOL)animated;

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

/**
 Map a root path to a given child router.
 @param path A single path component. This will be stripped when passing the url
 to the child router to open.
 @param childRouter the child router that should attempt to open the remainder of the url.
 */
- (void)mapPath:(NSString *)path toChildRouter:(UPRouter*)childRouter;


///-------------------------------
/// @name Opening URLs
///-------------------------------

/**
 A convenience method for opening a URL using `UIApplication` `openURL:`.
 @param url The URL the OS will open (i.e. "http://google.com")
 */
- (void)openExternal:(NSString *)url;

/**
 Triggers the appropriate functionality for a mapped URL, such as an anonymous function or opening a `UIViewController`. `UIViewController` transitions will be animated;
 @param url The URL being opened (i.e. "users/16")
 @exception RouteNotFoundException Thrown if url does not have a valid mapping
 @exception NavigationControllerNotProvided Thrown if url opens a `UIViewController` and navigationController has not been assigned
 @exception RoutableInitializerNotFound Thrown if the mapped `UIViewController` instance does not implement -initWithRouterParams: or +allocWithRouterParams:
 */
- (void)open:(NSString *)url;

/**
 Triggers the appropriate functionality for a mapped URL, such as an anonymous function or opening a `UIViewController`
 @param url The URL being opened (i.e. "users/16")
 @param animated Whether or not `UIViewController` transitions are animated.
 @exception RouteNotFoundException Thrown if url does not have a valid mapping
 @exception NavigationControllerNotProvided Thrown if url opens a `UIViewController` and navigationController has not been assigned
 @exception RoutableInitializerNotFound Thrown if the mapped `UIViewController` instance does not implement -initWithRouterParams: or +allocWithRouterParams:
 */
 - (void)open:(NSString *)url animated:(BOOL)animated;

@end

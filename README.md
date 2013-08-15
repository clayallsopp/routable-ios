# Routable

Routable is an in-app native URL router, for iOS. Also available for [Android](https://github.com/usepropeller/routable-android).

## Usage

Set up your app's router and URLs (usually done in `application:didFinishLaunchingWithOptions:`):

```objective-c
[[Routable sharedRouter] map:@"users/:id" toController:[UserController class]];
// Requires an instance of UINavigationController to open UIViewControllers
[[Routable sharedRouter] setNavigationController:aNavigationController];
```

Implement `initWithRouterParams:` in your `UIViewController` subclass:

```objective-c
@implementation UserController

// params will be non-nil
- (id)initWithRouterParams:(NSDictionary *)params {
  if ((self = [self initWithNibName:nil bundle:nil])) {
    self.userId = [params objectForKey:@"id"];
  }
  return self;
}
```

Then, anywhere else in your app, open a URL:

```objective-c
NSString *aUrl = @"users/4";
[[Routable sharedRouter] open:aUrl];
```

If you wish to do custom allocation of a controller, you can use `+controllerWithRouterParams:`

```objective-c
[[Routable sharedRouter] map:@"users/:id" toController:[StoryboardController class]];

@implementation StoryboardController

+ (id)controllerWithRouterParams:(NSDictionary *)params {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Storyboard" bundle:nil];
    StoryboardController *instance = [storyboard instantiateViewControllerWithIdentifier:@"sbController"];
    instance.userId = [params objectForKey:@"id"];

    return instance;
}
```

## Installation

### [CocoaPods](http://cocoapods.org/)

```ruby
pod 'Routable', '0.0.2'
```

```objective-c
#import <Routable/Routable.h>
```

If you're not able to use CocoaPods, please install Routable as a [git submodule](http://schacon.github.com/git/user-manual.html#submodules) and add the files to your Xcode project.

## Features

### Anonymous Callbacks

You can invoke anonymous callbacks with Routable:

```objective-c
[[Routable sharedRouter] map:@"invalidate/:id" toCallback:^(NSDictionary *params) {
  [Cache invalidate: [params objectForKey:@"id"]]];
}];

[[Routable sharedRouter] open:@"invalidate/5h1b2bs"];
```

### Presentation Options

You can configure if and how a `UIViewController` is presented modally with `UPRouterOptions`:

```objective-c
UPRouterOptions *options = [[UPRouterOptions modal] withPresentationStyle: UIModalPresentationFormSheet];
[self.router map:@"info" toController:[InfoController class]
                          withOptions:options];
```

`UPRouterOptions` has the following DSL setters:
- `modal`
- `withPresentationStyle:`
- `withTransitionStyle:`
- `forDefaultParams:`

### Open External URLs

Sometimes you want to open a URL outside of your app, like a YouTube URL or open a web URL in the browser. You can use Routable to do that:

```objective-c
[[Routable sharedRouter] openExternal:@"http://www.youtube.com/watch?v=oHg5SJYRHA0"];
```

### Multiple Routers

If you need to use multiple routers, simply create new instances of `Router`:

```objective-c
UPRouter *adminRouter = [Routable newRouter];
[adminRouter map:@"profile" toController: [AdminProfile class]];

UPRouter *userRouter = [Routable newRouter];
[userRouter map:@"profile" toController: [UserProfile class]];
```

## Contact

Clay Allsopp ([http://clayallsopp.com](http://clayallsopp.com))

- [http://twitter.com/clayallsopp](http://twitter.com/clayallsopp)
- [clay@usepropeller.com](clay@usepropeller.com)

## License

Routable for iOS is available under the MIT license. See the LICENSE file for more info.

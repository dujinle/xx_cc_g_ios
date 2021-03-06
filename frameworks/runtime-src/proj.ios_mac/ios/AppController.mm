/****************************************************************************
 Copyright (c) 2010-2013 cocos2d-x.org
 Copyright (c) 2013-2017 Chukong Technologies Inc.

 http://www.cocos2d-x.org

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
****************************************************************************/

#import "AppController.h"
#import "cocos2d.h"
#import "AppDelegate.h"
#import "RootViewController.h"
#import "platform/ios/CCEAGLView-ios.h"
#import "ScriptingCore.cpp"
#import "cocos-analytics/CAAgent.h"
#import "NativeOcClass.h"
#import "Reachability.h"
using namespace cocos2d;

@implementation AppController

@synthesize window;

#pragma mark -
#pragma mark Application lifecycle

// cocos2d application instance
static AppDelegate* s_sharedApplication = nullptr;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    [CAAgent enableDebug:NO];

    if (s_sharedApplication == nullptr)
    {
        s_sharedApplication = new (std::nothrow) AppDelegate();
    }
    cocos2d::Application *app = cocos2d::Application::getInstance();

    // Initialize the GLView attributes
    app->initGLContextAttrs();
    cocos2d::GLViewImpl::convertAttrs();

    
    //注册微信SDK
    [WXApi registerApp:@"wx6c145967bc25e278"];
    // Override point for customization after application launch.
    [self startNetwork];

    // Add the view controller's view to the window and display.
    window = [[UIWindow alloc] initWithFrame: [[UIScreen mainScreen] bounds]];

    // Use RootViewController to manage CCEAGLView
    _viewController = [[RootViewController alloc]init];
    _viewController.wantsFullScreenLayout = YES;


    // Set RootViewController to window
    if ( [[UIDevice currentDevice].systemVersion floatValue] < 6.0)
    {
        // warning: addSubView doesn't work on iOS6
        [window addSubview: _viewController.view];
    }
    else
    {
        // use this method on ios6
        [window setRootViewController:_viewController];
    }

    [window makeKeyAndVisible];

    [[UIApplication sharedApplication] setStatusBarHidden:YES];

    // IMPORTANT: Setting the GLView should be done after creating the RootViewController
    cocos2d::GLView *glview = cocos2d::GLViewImpl::createWithEAGLView((__bridge void *)_viewController.view);
    cocos2d::Director::getInstance()->setOpenGLView(glview);

    //run the cocos2d-x game scene
    app->run();

    return YES;
}
-(BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url{
    return [WXApi handleOpenURL:url delegate:self];
}

-(BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options{
    NSString *str = [url.absoluteString urlDecodeString];
    
    if ([str hasPrefix:@"xinchang://"]) {
        NSDictionary *dic = [str getURLParameters];
        NSString *roomID = [dic objectForKey:@"room_num"];
        NSString *rid = [dic objectForKey:@"rid"];
        NSString *scene = [dic objectForKey:@"scene"];
        
        if (scene.length > 0 && roomID.length > 0 && rid.length > 0) {
            
            NSString *funcName = [NSString stringWithFormat:@"onGameEnterRoom(%@,%@)",roomID,rid];
            [NativeOcClass sharedManager].LoginType = 1;
            [NativeOcClass sharedManager].roomNum = roomID;
            [NativeOcClass sharedManager].scene = scene;
            [NativeOcClass sharedManager].rid = rid;
            se::ScriptEngine::getInstance()->evalString(funcName.UTF8String);
            return YES;
        }
    }
    
    return [WXApi handleOpenURL:url delegate:self];
}
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation{
    return [WXApi handleOpenURL:url delegate:self];
}
//微信sdk协议方法
//如果第三方程序向微信发送了sendReq的请求，那么onResp会被回调。sendReq请求调用后，会切到微信终端程序界面。
-(void) onResp:(BaseResp*)resp{
    if([resp isKindOfClass:[SendAuthResp class]])
    {
        SendAuthResp *auth = (SendAuthResp *)resp;
        [NativeOcClass sharedManager].wxCode = auth.code;
    }
    
}

-(void)startNetwork{
    // Allocate a reachability object
    Reachability* reach = [Reachability reachabilityWithHostname:@"www.baidu.com"];
    reach.reachabilityBlock = ^(Reachability *reachability, SCNetworkConnectionFlags flags) {
        NetworkStatus status = [reach currentReachabilityStatus];
        /*
         NotReachable = 0, 无网络连接
         ReachableViaWiFi, Wifi
         ReachableViaWWAN 2G/3G/4G/5G
         */
        if (status == NotReachable) {
            [NativeOcClass sharedManager].NetType = NotReachable;
        } else if (status == ReachableViaWiFi) {
            [NativeOcClass sharedManager].NetType = ReachableViaWiFi;
            NSLog(@"Wifi");
        } else {
            [NativeOcClass sharedManager].NetType = ReachableViaWWAN;
            NSLog(@"3G/4G/5G");
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"REACHABLE!");
        });
    };
    // Set the blocks
    reach.reachableBlock = ^(Reachability*reach)
    {
        NetworkStatus status = [reach currentReachabilityStatus];
        /*
            NotReachable = 0, 无网络连接
            ReachableViaWiFi, Wifi
            ReachableViaWWAN 2G/3G/4G/5G
         */
        if (status == NotReachable) {
            [NativeOcClass sharedManager].NetType = NotReachable;
        } else if (status == ReachableViaWiFi) {
            [NativeOcClass sharedManager].NetType = ReachableViaWiFi;
//            NSLog(@"Wifi");
        } else {
            [NativeOcClass sharedManager].NetType = ReachableViaWWAN;
//            NSLog(@"3G/4G/5G");
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
//            NSLog(@"REACHABLE!");
        });
    };
    
    reach.unreachableBlock = ^(Reachability*reach)
    {
        NetworkStatus status = [reach currentReachabilityStatus];
        if (status == NotReachable){
            [NativeOcClass sharedManager].NetType = NotReachable;
			if([NativeOcClass sharedManager].LoadStatus != 0){
				//只有在登录的状态下才可以断网重连
				dispatch_async(dispatch_get_main_queue(), ^{
					NSString *funcName = @"onReconnect()";
					se::ScriptEngine::getInstance()->evalString(funcName.UTF8String);
				});
			}
        }
    };
    
    // Start the notifier, which will cause the reachability object to retain itself!
    [reach startNotifier];
}
- (void)applicationWillResignActive:(UIApplication *)application {
    /*
      Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
      Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    */
    // We don't need to call this method any more. It will interrupt user defined game pause&resume logic
    /* cocos2d::Director::getInstance()->pause(); */
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    /*
      Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    */
    // We don't need to call this method any more. It will interrupt user defined game pause&resume logic
    /* cocos2d::Director::getInstance()->resume(); */
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    /*
      Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
      If your application supports background execution, called instead of applicationWillTerminate: when the user quits.
    */
    cocos2d::Application::getInstance()->applicationDidEnterBackground();
    if (CAAgent.isInited) {
        [CAAgent onPause];
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    /*
      Called as part of  transition from the background to the inactive state: here you can undo many of the changes made on entering the background.
    */
    auto glview = (__bridge CCEAGLView*)(Director::getInstance()->getOpenGLView()->getEAGLView());
    auto currentView = [[[[UIApplication sharedApplication] keyWindow] subviews] lastObject];
    if (glview == currentView) {
        cocos2d::Application::getInstance()->applicationWillEnterForeground();
    }
    if (CAAgent.isInited) {
        [CAAgent onResume];
    }
}

- (void)applicationWillTerminate:(UIApplication *)application {
    /*
      Called when the application is about to terminate.
      See also applicationDidEnterBackground:.
    */
    if (s_sharedApplication != nullptr)
    {
        delete s_sharedApplication;
        s_sharedApplication = nullptr;
    }
    [CAAgent onDestroy];
}


#pragma mark -
#pragma mark Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    /*
      Free up as much memory as possible by purging cached data objects that can be recreated (or reloaded from disk) later.
    */
}


#if __has_feature(objc_arc)
#else
- (void)dealloc {
    [window release];
    [_viewController release];
    [super dealloc];
}
#endif


@end

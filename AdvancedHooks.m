// 有问题,联系pxx917144686

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreFoundation/CoreFoundation.h>
#import <objc/runtime.h>

// 前向声明：早期构造器调用
static void persistLiquidGlassPrefs(void);
static void installTabBarFixHooks(void);
static void applyTabBarSingleLayer(UITabBar *tabBar);
static void hideTabBarBackgroundRecursive(UIView *view);

static void applyVolatileLiquidGlassPrefs(void) __attribute__((unused));
static void applyVolatileLiquidGlassPrefs(void) {
    @try {
        if ([[NSProcessInfo processInfo] operatingSystemVersion].majorVersion < 26) return;
        NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
        NSDictionary *volatilePrefs = @{
            @"com.apple.SwiftUI.IgnoreSolariumLinkedOnCheck": @YES,
            @"com.apple.UIKit.EnableLiquidGlass": @YES,
            @"com.apple.UIKit.ForceLiquidGlass": @YES,
            @"com.apple.UIKit.EnableSystemMaterials": @YES,
            @"com.apple.UIKit.ForceSystemMaterials": @YES,
            @"com.apple.UIKit.EnableLiquidGlassEffects": @YES,
            @"com.apple.UIKit.ForceLiquidGlassEffects": @YES,
            @"com.apple.UIKit.EnableSystemBlur": @YES,
            @"com.apple.UIKit.ForceSystemBlur": @YES,
        };
        // 使用 NSRegistrationDomain 作为只读默认值源，避免触碰全局/应用持久域
        [ud setVolatileDomain:volatilePrefs forName:NSRegistrationDomain];
    } @catch (__unused NSException *e) {
    }
}


// 持久化写入到应用域（必须，iOS26+）
static void persistLiquidGlassPrefs(void) {
    @try {
        if ([[NSProcessInfo processInfo] operatingSystemVersion].majorVersion < 26) return;
        NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
        if (bundleID.length == 0) return;
        CFStringRef appID = (__bridge CFStringRef)bundleID;
        const CFStringRef keys[] = {
            CFSTR("com.apple.SwiftUI.IgnoreSolariumLinkedOnCheck"),
            CFSTR("com.apple.UIKit.EnableLiquidGlass"),
            CFSTR("com.apple.UIKit.ForceLiquidGlass"),
            CFSTR("com.apple.UIKit.EnableSystemMaterials"),
            CFSTR("com.apple.UIKit.ForceSystemMaterials"),
            CFSTR("com.apple.UIKit.EnableLiquidGlassEffects"),
            CFSTR("com.apple.UIKit.ForceLiquidGlassEffects"),
            CFSTR("com.apple.UIKit.EnableSystemBlur"),
            CFSTR("com.apple.UIKit.ForceSystemBlur"),
        };
        for (size_t i = 0; i < sizeof(keys)/sizeof(keys[0]); i++) {
            CFPreferencesSetAppValue(keys[i], kCFBooleanTrue, appID);
        }
        CFPreferencesAppSynchronize(appID);
    } @catch (__unused NSException *e) {}
}


// 超早期构造器：写入环境变量与持久化偏好（iOS26+）
__attribute__((constructor(101)))
static void wechat_early_ctor(void) {
    @autoreleasepool {
        if ([[NSProcessInfo processInfo] operatingSystemVersion].majorVersion < 26) return;
        setenv("DYLD_FORCE_LIQUID_GLASS", "1", 1);
        setenv("UIKIT_ENABLE_LIQUID_GLASS", "1", 1);
        setenv("UIKIT_FORCE_LIQUID_GLASS", "1", 1);
        setenv("UIKIT_ENABLE_SYSTEM_MATERIALS", "1", 1);
        setenv("UIKIT_FORCE_SYSTEM_MATERIALS", "1", 1);
        setenv("UIKIT_LIQUID_GLASS_MODE", "FORCE", 1);
        setenv("UIKIT_SYSTEM_MATERIALS_MODE", "FORCE", 1);
        setenv("SWIFTUI_IGNORE_SOLARIUM_CHECK", "1", 1);
        persistLiquidGlassPrefs();
        installTabBarFixHooks();
    }
}


#pragma mark - TabBar 双层修复

static void hideTabBarBackgroundRecursive(UIView *view) {
    for (UIView *sub in view.subviews) {
        NSString *cls = NSStringFromClass([sub class]);
        BOOL looksLikeBackground = [sub isKindOfClass:[UIVisualEffectView class]] ||
                                   [cls containsString:@"BarBackground"] ||
                                   [cls containsString:@"Background"] ||
                                   [cls containsString:@"VisualEffect"] ||
                                   [cls containsString:@"UITabBarPlatter"] ||
                                   [cls containsString:@"PlatterView"] ||
                                   [cls containsString:@"ContentView"]; // _TtCC5UIKit20_UITabBarPlatterView...ContentView
        if (looksLikeBackground) {
            sub.hidden = YES;
            sub.alpha = 0.0;
            sub.userInteractionEnabled = NO;
        }
        if (sub.subviews.count > 0) hideTabBarBackgroundRecursive(sub);
    }
}

static void applyTabBarSingleLayer(UITabBar *tabBar) {
    if (!tabBar) return;
    // 统一使用系统外观：去掉任何自绘/毛玻璃叠层
    @try {
        if (@available(iOS 14.0, *)) {
            UITabBarAppearance *appearance = tabBar.standardAppearance ?: [[UITabBarAppearance alloc] init];
            appearance.backgroundEffect = nil; // 保留系统 Liquid Glass，由系统自身决定
            appearance.backgroundColor = [UIColor clearColor];
            appearance.shadowColor = [UIColor clearColor];
            appearance.shadowImage = [UIImage new];
            tabBar.standardAppearance = appearance;
            if (@available(iOS 15.0, *)) {
                tabBar.scrollEdgeAppearance = appearance;
            }
        } else {
            tabBar.backgroundImage = [UIImage new];
            tabBar.shadowImage = [UIImage new];
            tabBar.barTintColor = [UIColor clearColor];
            tabBar.translucent = YES;
        }
    } @catch (__unused NSException *e) {}

    // 直接移除/隐藏微信自定义的底板视图
    @try {
        hideTabBarBackgroundRecursive(tabBar);
    } @catch (__unused NSException *e) {}
}

static void swizzle(Class cls, SEL original, SEL replacement) {
    Method m1 = class_getInstanceMethod(cls, original);
    Method m2 = class_getInstanceMethod(cls, replacement);
    if (!m1 || !m2) return;
    BOOL added = class_addMethod(cls, original, method_getImplementation(m2), method_getTypeEncoding(m2));
    if (added) {
        class_replaceMethod(cls, replacement, method_getImplementation(m1), method_getTypeEncoding(m1));
    } else {
        method_exchangeImplementations(m1, m2);
    }
}

// UITabBarController viewDidAppear，进入主界面后统一清理一次
@interface UITabBarController (LGSingleLayer)
@end

@implementation UITabBarController (LGSingleLayer)
- (void)lg_viewDidAppear:(BOOL)animated {
    [self lg_viewDidAppear:animated];
    @try { applyTabBarSingleLayer(self.tabBar); } @catch (__unused NSException *e) {}
}
@end

// UITabBar layoutSubviews，每次布局重进都确保不被应用恢复第二层
@interface UITabBar (LGSingleLayer)
@end

@implementation UITabBar (LGSingleLayer)
- (void)lg_layoutSubviews {
    [self lg_layoutSubviews];
    @try { applyTabBarSingleLayer(self); } @catch (__unused NSException *e) {}
}
@end

static void installTabBarFixHooks(void) {
    @try {
        // 仅在微信内启用
        NSString *bid = [[NSBundle mainBundle] bundleIdentifier];
        if (![bid containsString:@"tencent"] && ![bid containsString:@"WeChat"]) return;
        swizzle([UITabBarController class], @selector(viewDidAppear:), @selector(lg_viewDidAppear:));
        swizzle([UITabBar class], @selector(layoutSubviews), @selector(lg_layoutSubviews));
        // 对已在屏幕上的 tabBar 立即应用一次
        dispatch_async(dispatch_get_main_queue(), ^{
            @try {
                NSSet *scenes = UIApplication.sharedApplication.connectedScenes;
                for (UIScene *scene in scenes) {
                    if (![scene isKindOfClass:[UIWindowScene class]]) continue;
                    UIWindowScene *ws = (UIWindowScene *)scene;
                    if (ws.activationState == UISceneActivationStateUnattached) continue;
                    for (UIWindow *win in ws.windows) {
                        for (UIView *v in win.subviews) {
                            if ([v isKindOfClass:[UITabBar class]]) {
                                applyTabBarSingleLayer((UITabBar *)v);
                            }
                        }
                    }
                }
            } @catch (__unused NSException *e) {}
        });
    } @catch (__unused NSException *e) {}
}

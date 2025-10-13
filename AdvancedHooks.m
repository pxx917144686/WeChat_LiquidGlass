// 有问题,联系pxx917144686

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreFoundation/CoreFoundation.h>
#import <objc/runtime.h>
#import <objc/message.h>

// 前向声明：早期构造器调用
static void applyOrClearLiquidGlassPrefs(BOOL enable);
static BOOL isLiquidGlassEnabled(void);
static void setLiquidGlassEnabled(BOOL enable);
static void installTabBarFixHooks(void);
static void applyTabBarSingleLayer(UITabBar *tabBar);
static void hideTabBarBackgroundRecursive(UIView *view);
static void installSettingsEntryHook(void);
static void scheduleSettingsHookRetry(void);
static void xg_swizzle(Class cls, SEL original, SEL replacement);
static void forceEnableWeChatLiquidGlass(void);

// 根据开关在应用域写入/清理偏好
static void applyOrClearLiquidGlassPrefs(BOOL enable) {
    @try {
        if ([[NSProcessInfo processInfo] operatingSystemVersion].majorVersion < 26) return;
        NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
        if (bundleID.length == 0) return;
        CFStringRef appID = (__bridge CFStringRef)bundleID;
        const CFStringRef keys[] = {
            // SwiftUI Liquid Glass 支持
            CFSTR("com.apple.SwiftUI.IgnoreSolariumLinkedOnCheck"),
            CFSTR("com.apple.SwiftUI.EnableLiquidGlass"),
            CFSTR("com.apple.SwiftUI.ForceLiquidGlass"),
            CFSTR("com.apple.SwiftUI.EnableSystemMaterials"),
            CFSTR("com.apple.SwiftUI.ForceSystemMaterials"),
            CFSTR("com.apple.SwiftUI.EnableLiquidGlassEffects"),
            CFSTR("com.apple.SwiftUI.ForceLiquidGlassEffects"),
            CFSTR("com.apple.SwiftUI.EnableSystemBlur"),
            CFSTR("com.apple.SwiftUI.ForceSystemBlur"),
            
            // UIKit Liquid Glass 支持
            CFSTR("com.apple.UIKit.EnableLiquidGlass"),
            CFSTR("com.apple.UIKit.ForceLiquidGlass"),
            CFSTR("com.apple.UIKit.EnableSystemMaterials"),
            CFSTR("com.apple.UIKit.ForceSystemMaterials"),
            CFSTR("com.apple.UIKit.EnableLiquidGlassEffects"),
            CFSTR("com.apple.UIKit.ForceLiquidGlassEffects"),
            CFSTR("com.apple.UIKit.EnableSystemBlur"),
            CFSTR("com.apple.UIKit.ForceSystemBlur"),
            
            // 微信专用 Liquid Glass 强制启用
            CFSTR("com.tencent.xin.EnableLiquidGlass"),
            CFSTR("com.tencent.xin.ForceLiquidGlass"),
            CFSTR("com.tencent.xin.EnableSystemMaterials"),
            CFSTR("com.tencent.xin.ForceSystemMaterials"),
            
            // 全局 Liquid Glass 强制启用
            CFSTR("com.apple.UIKit.ForceEnableLiquidGlass"),
            CFSTR("com.apple.UIKit.ForceEnableSystemMaterials"),
            CFSTR("com.apple.UIKit.ForceEnableSystemBlur"),
            
            // 兼容性强制启用
            CFSTR("com.apple.UIKit.EnableAdvancedRendering"),
            CFSTR("com.apple.UIKit.ForceAdvancedRendering"),
            CFSTR("com.apple.UIKit.EnableModernEffects"),
            CFSTR("com.apple.UIKit.ForceModernEffects"),
        };
        for (size_t i = 0; i < sizeof(keys)/sizeof(keys[0]); i++) {
            if (enable) {
                CFPreferencesSetAppValue(keys[i], kCFBooleanTrue, appID);
            } else {
                // 关闭时移除键，避免“永久生效”
                CFPreferencesSetAppValue(keys[i], NULL, appID);
            }
        }
        CFPreferencesAppSynchronize(appID);
    } @catch (__unused NSException *e) {}
}

static BOOL isLiquidGlassEnabled(void) {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"xg_liquid_glass_enabled"];
}

static void setLiquidGlassEnabled(BOOL enable) {
    [[NSUserDefaults standardUserDefaults] setBool:enable forKey:@"xg_liquid_glass_enabled"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    applyOrClearLiquidGlassPrefs(enable);
    
    // 微信专用：强制启用 Liquid Glass 环境变量
    if (enable) {
        setenv("UIKIT_ENABLE_LIQUID_GLASS", "1", 1);
        setenv("UIKIT_FORCE_LIQUID_GLASS", "1", 1);
        setenv("UIKIT_ENABLE_SYSTEM_MATERIALS", "1", 1);
        setenv("UIKIT_FORCE_SYSTEM_MATERIALS", "1", 1);
        setenv("SWIFTUI_ENABLE_LIQUID_GLASS", "1", 1);
        setenv("SWIFTUI_FORCE_LIQUID_GLASS", "1", 1);
    } else {
        unsetenv("UIKIT_ENABLE_LIQUID_GLASS");
        unsetenv("UIKIT_FORCE_LIQUID_GLASS");
        unsetenv("UIKIT_ENABLE_SYSTEM_MATERIALS");
        unsetenv("UIKIT_FORCE_SYSTEM_MATERIALS");
        unsetenv("SWIFTUI_ENABLE_LIQUID_GLASS");
        unsetenv("SWIFTUI_FORCE_LIQUID_GLASS");
    }
}


// 微信专用：强制启用 Liquid Glass
static void forceEnableWeChatLiquidGlass(void) {
    @try {
        // 检查是否为微信应用
        NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
        if (![bundleID containsString:@"tencent"] && ![bundleID containsString:@"WeChat"]) return;
        
        // 强制启用 Liquid Glass 环境变量
        setenv("UIKIT_ENABLE_LIQUID_GLASS", "1", 1);
        setenv("UIKIT_FORCE_LIQUID_GLASS", "1", 1);
        setenv("UIKIT_ENABLE_SYSTEM_MATERIALS", "1", 1);
        setenv("UIKIT_FORCE_SYSTEM_MATERIALS", "1", 1);
        setenv("SWIFTUI_ENABLE_LIQUID_GLASS", "1", 1);
        setenv("SWIFTUI_FORCE_LIQUID_GLASS", "1", 1);
        
        // 强制启用全局偏好设置
        NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
        [ud setBool:YES forKey:@"UIKIT_ENABLE_LIQUID_GLASS"];
        [ud setBool:YES forKey:@"UIKIT_FORCE_LIQUID_GLASS"];
        [ud setBool:YES forKey:@"UIKIT_ENABLE_SYSTEM_MATERIALS"];
        [ud setBool:YES forKey:@"UIKIT_FORCE_SYSTEM_MATERIALS"];
        [ud synchronize];
        
    } @catch (__unused NSException *e) {}
}

// 超早期构造器：写入环境变量与持久化偏好（iOS26+）
__attribute__((constructor(101)))
static void wechat_early_ctor(void) {
    @autoreleasepool {
        if ([[NSProcessInfo processInfo] operatingSystemVersion].majorVersion < 26) return;
        
        // 微信专用：强制启用 Liquid Glass
        forceEnableWeChatLiquidGlass();
        
        // 避免使用环境变量导致黑屏风险，仅使用偏好键控制
        applyOrClearLiquidGlassPrefs(isLiquidGlassEnabled());
        
        // 只有开启时才安装功能性 Hook，且延后至主线程，等窗口就绪
        if (isLiquidGlassEnabled()) {
            dispatch_async(dispatch_get_main_queue(), ^{
                installTabBarFixHooks();
            });
        }
		// 设置入口 Hook 采用重试方式，等待目标类加载完成
		scheduleSettingsHookRetry();
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
    if (!isLiquidGlassEnabled()) return; // 关闭时完全不改动 TabBar
    
    // 防抖：同一 tabBar 只应用一次，避免频繁 layout 导致卡顿
    static const void *kLGAppliedKey = &kLGAppliedKey;
    NSNumber *applied = objc_getAssociatedObject(tabBar, kLGAppliedKey);
    if ([applied boolValue]) return;
    
    // 微信专用：强制启用 Liquid Glass 效果
    @try {
        if (@available(iOS 14.0, *)) {
            UITabBarAppearance *appearance = tabBar.standardAppearance ?: [[UITabBarAppearance alloc] init];
            
            // 强制启用 Liquid Glass：透明背景，交由系统视觉效果处理
            [appearance configureWithTransparentBackground];
            appearance.backgroundEffect = nil;
            appearance.backgroundColor = [UIColor clearColor];
            appearance.shadowColor = [UIColor clearColor];
            appearance.shadowImage = [UIImage new];
            
            // 微信专用：强制启用系统材质效果
            if (@available(iOS 15.0, *)) {
                // 使用系统默认的 Liquid Glass 效果
                appearance.backgroundEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemMaterial];
                tabBar.scrollEdgeAppearance = appearance;
            }
            
            tabBar.standardAppearance = appearance;
            tabBar.translucent = YES;
            
            // 强制启用系统材质
            if (@available(iOS 15.0, *)) {
                tabBar.scrollEdgeAppearance = appearance;
            }
        } else {
            tabBar.backgroundImage = [UIImage new];
            tabBar.shadowImage = [UIImage new];
            tabBar.barTintColor = [UIColor clearColor];
            tabBar.translucent = YES;
        }
        
        // 微信专用：强制启用系统视觉效果
        tabBar.translucent = YES;
        tabBar.backgroundColor = [UIColor clearColor];
        
    } @catch (__unused NSException *e) {}

    // 直接移除/隐藏微信自定义的底板视图，让系统 Liquid Glass 生效
    @try {
        hideTabBarBackgroundRecursive(tabBar);
    } @catch (__unused NSException *e) {}

    // 标记已应用，避免重复执行
    objc_setAssociatedObject(tabBar, kLGAppliedKey, @(YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
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
        xg_swizzle([UITabBarController class], @selector(viewDidAppear:), @selector(lg_viewDidAppear:));
        xg_swizzle([UITabBar class], @selector(layoutSubviews), @selector(lg_layoutSubviews));
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

#pragma mark - 在微信设置页插入“Liquid Glass”入口

@interface WCTableViewManager : NSObject
- (id)getSectionAt:(NSInteger)index;
- (UITableView *)getTableView;
@end

@interface WCTableViewSectionManager : NSObject
- (NSArray *)cells;
- (void)setCells:(NSArray *)cells;
@end

@interface WCTableViewNormalCellManager : NSObject
+ (instancetype)normalCellForSel:(SEL)sel target:(id)target title:(NSString *)title rightValue:(id)rightValue accessoryType:(NSInteger)type;
@end

@interface MMTableView : UITableView @end

static BOOL xg_settings_hook_installed = NO;

static void xg_swizzle(Class cls, SEL original, SEL replacement) {
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

// 使用 C 函数实现，以避免对目标类产生编译期符号引用
static void xg_reloadTableData_impl(id self, SEL _cmd) {
    // 调用原始实现（已与 xg_reloadTableData 交换）
    void (*orig)(id, SEL) = (void (*)(id, SEL))objc_msgSend;
    orig(self, @selector(xg_reloadTableData));
    @try {
        id tableViewManager = [self valueForKey:@"m_tableViewMgr"];
        if (!tableViewManager) return;
        typedef id (*GetSectionAtFunc)(id, SEL, NSInteger);
        GetSectionAtFunc getSectionAt = (GetSectionAtFunc)[tableViewManager methodForSelector:@selector(getSectionAt:)];
        id firstSection = getSectionAt ? getSectionAt(tableViewManager, @selector(getSectionAt:), 0) : nil;
        if (!firstSection) return;
        BOOL alreadyAdded = NO;
        @try {
            NSArray *cells = [firstSection performSelector:@selector(cells)];
            for (id cell in cells) {
                NSString *title = nil;
                if ([cell respondsToSelector:@selector(title)]) title = [cell performSelector:@selector(title)];
                else if ([cell respondsToSelector:@selector(getTitle)]) title = [cell performSelector:@selector(getTitle)];
                if ([title isKindOfClass:[NSString class]] && [title isEqualToString:@"Liquid Glass"]) { alreadyAdded = YES; break; }
            }
        } @catch (__unused NSException *e) {}
        if (alreadyAdded) return;
        NSMutableArray *newCells = [NSMutableArray array];
        NSArray *original = nil;
        @try { original = [firstSection performSelector:@selector(cells)]; } @catch (__unused NSException *e) {}
        if (!original) original = @[];
        id xgCell = [objc_getClass("WCTableViewNormalCellManager") normalCellForSel:@selector(xg_openXiaoXueGaoSettings)
                                                                              target:self
                                                                               title:@"Liquid Glass"
                                                                           rightValue:(isLiquidGlassEnabled() ? @"开启" : @"关闭")
                                                                        accessoryType:1];
        if (!xgCell) return;
        [newCells addObject:xgCell];
        [newCells addObjectsFromArray:original];
        @try { [firstSection performSelector:@selector(setCells:) withObject:newCells]; } @catch (__unused NSException *e) {}
        dispatch_async(dispatch_get_main_queue(), ^{
            @try {
                MMTableView *tableView = [tableViewManager performSelector:@selector(getTableView)];
                [tableView reloadData];
            } @catch (__unused NSException *e) {}
        });
    } @catch (__unused NSException *e) {}
}

static void xg_openXiaoXueGaoSettings_impl(id self, SEL _cmd) {
    @try {
        Class cls = NSClassFromString(@"XGLiquidGlassSettingsViewController");
        if (!cls) return;
        UIViewController *vc = [[cls alloc] init];
        if (!vc) return;
        UINavigationController *nav = [self valueForKey:@"navigationController"];
        if (!nav) return;
        [nav pushViewController:vc animated:YES];
    } @catch (__unused NSException *e) {}
}

static void installSettingsEntryHook(void) {
    if (xg_settings_hook_installed) return;
	// 兼容不同版本/渠道的设置控制器类名
	const char *candidateClassNames[] = {
		"NewSettingViewController",
		"MMNewSettingViewController",
		"SettingViewController",
		"MoreSettingViewController",
		"WCNewSettingViewController"
	};
	Class cls = NULL;
	for (size_t i = 0; i < sizeof(candidateClassNames)/sizeof(candidateClassNames[0]); i++) {
		cls = objc_getClass(candidateClassNames[i]);
		if (cls) break;
	}
	if (!cls) return;
    // 动态注入两个方法实现，避免分类导致的链接期依赖
    class_addMethod(cls, @selector(xg_reloadTableData), (IMP)xg_reloadTableData_impl, "v@:");
    class_addMethod(cls, @selector(xg_openXiaoXueGaoSettings), (IMP)xg_openXiaoXueGaoSettings_impl, "v@:");
    // 交换实现
    xg_swizzle(cls, @selector(reloadTableData), @selector(xg_reloadTableData));
    xg_settings_hook_installed = YES;
}

// 在主线程上以退避方式重试安装设置入口 Hook，最大重试次数防止死循环
static void scheduleSettingsHookRetry(void) {
	static int retryCount = 0;
	const int kMaxRetry = 30; // 最多重试 30 次（约 15 秒）
	const double kInterval = 0.5; // 500ms 一次
	if (xg_settings_hook_installed) return;
	dispatch_async(dispatch_get_main_queue(), ^{
		installSettingsEntryHook();
		if (!xg_settings_hook_installed && retryCount < kMaxRetry) {
			retryCount++;
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
				scheduleSettingsHookRetry();
			});
		}
	});
}

#pragma mark - 设置页：控制 Liquid Glass 开关

@interface XGLiquidGlassSettingsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITableView *tableView;
@end

@implementation XGLiquidGlassSettingsViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Liquid Glass";
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleInsetGrouped];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.view addSubview:self.tableView];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return 1; }
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return 1; }
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section { return @"效果开关"; }

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cid = @"lg.switch";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cid];
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cid];
    cell.textLabel.text = @"启用 Liquid Glass";
    UISwitch *sw = [[UISwitch alloc] init];
    sw.on = isLiquidGlassEnabled();
    [sw addTarget:self action:@selector(onToggle:) forControlEvents:UIControlEventValueChanged];
    cell.accessoryView = sw;
    return cell;
}

- (void)onToggle:(UISwitch *)sw {
    BOOL enable = sw.isOn;
    setLiquidGlassEnabled(enable);
    // 立即刷新设置入口右侧值
    @try {
        Class newSettingCls = objc_getClass("NewSettingViewController");
        if (newSettingCls) {
            // 无法直接刷新外部控制器，这里尽量提示用户
        }
    } @catch (__unused NSException *e) {}
    // 环境变量只在重启 App 后生效，提示
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示"
                                                                 message:(enable ? @"已启用 Liquid Glass，部分效果需重启微信生效" : @"已禁用 Liquid Glass，需重启微信彻底生效")
                                                          preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}
@end

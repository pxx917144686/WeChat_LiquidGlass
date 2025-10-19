// 有问题,联系pxx917144686

#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <objc/runtime.h>
#import <objc/message.h>

// 前向声明UIKit类型以避免导入整个UIKit
@class UIVisualEffectView, UIBlurEffect, UIVisualEffect, UIView, UITableView, UIViewController, UISwitch, UITableViewCell, UIAlertController, UIAlertAction, UINavigationController, UIColor, UILabel, NSIndexPath;

// 定义UIKit基础类
@interface UIColor : NSObject
+ (UIColor *)systemBackgroundColor;
@end

@interface UIVisualEffect : NSObject
@end

// 定义UIKit类的基本接口
@interface UIView : NSObject
@property (nonatomic) CGRect frame;
@property (nonatomic) NSInteger tag;
@property (nonatomic, getter=isHidden) BOOL hidden;
@property (nonatomic) CGFloat alpha;
@property (nonatomic) CGRect bounds;
@property (nonatomic, strong) UIColor *backgroundColor;
- (void)addSubview:(UIView *)view;
@end

@interface UIVisualEffectView : UIView
@property (nonatomic, strong) UIVisualEffect *effect;
- (instancetype)initWithEffect:(UIVisualEffect *)effect;
@end

@interface UIBlurEffect : UIVisualEffect
@end

@interface UITableView : UIView
@property (nonatomic) NSUInteger autoresizingMask;
@property (nonatomic, weak) id dataSource;
@property (nonatomic, weak) id delegate;
- (instancetype)initWithFrame:(CGRect)frame style:(NSInteger)style;
- (void)reloadData;
- (UITableViewCell *)dequeueReusableCellWithIdentifier:(NSString *)identifier;
@end

@interface UIViewController : NSObject
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) UIView *view;
- (void)viewDidLoad;
- (void)presentViewController:(UIViewController *)viewControllerToPresent animated:(BOOL)flag completion:(void (^)(void))completion;
@end

@interface UINavigationController : UIViewController
- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated;
@end

@interface UISwitch : UIView
@property (nonatomic, getter=isOn) BOOL on;
- (void)addTarget:(id)target action:(SEL)action forControlEvents:(NSUInteger)controlEvents;
@end

@interface UITableViewCell : UIView
@property (nonatomic, strong) UILabel *textLabel;
@property (nonatomic, strong) UIView *accessoryView;
- (instancetype)initWithStyle:(NSInteger)style reuseIdentifier:(NSString *)reuseIdentifier;
@end

@interface UILabel : UIView
@property (nonatomic, strong) NSString *text;
@end

@interface UIAlertController : UIViewController
+ (instancetype)alertControllerWithTitle:(NSString *)title message:(NSString *)message preferredStyle:(NSInteger)preferredStyle;
- (void)addAction:(UIAlertAction *)action;
@end

@interface UIAlertAction : NSObject
+ (instancetype)actionWithTitle:(NSString *)title style:(NSInteger)style handler:(void (^)(UIAlertAction *action))handler;
@end

@protocol UITableViewDataSource <NSObject>
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView;
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
@end

@protocol UITableViewDelegate <NSObject>
@optional
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section;
@end

// 定义常量
#define UITableViewStyleInsetGrouped 2
#define UITableViewCellStyleValue1 1
#define UIControlEventValueChanged (1 << 12)
#define UIViewAutoresizingFlexibleWidth (1 << 1)
#define UIViewAutoresizingFlexibleHeight (1 << 4)
#define UIAlertControllerStyleAlert 1
#define UIAlertActionStyleDefault 0
#define UIAlertActionStyleCancel 1

// 前向声明：早期构造器调用
static void applyOrClearLiquidGlassPrefs(BOOL enable);
BOOL isLiquidGlassEnabled(void);
void setLiquidGlassEnabled(BOOL enable);
static void installSettingsEntryHook(void);
static void scheduleSettingsHookRetry(void);
void xg_swizzle(Class cls, SEL original, SEL replacement);

// 隐藏底部栏文字标签功能
static void installTabBarTextHideHooks(void);

// UIVisualEffectView隐藏功能
static void installVisualEffectViewHooks(void);
static BOOL isTargetVisualEffectView(UIVisualEffectView *view);

// 根据开关在应用域写入/清理偏好
static void applyOrClearLiquidGlassPrefs(BOOL enable) {
    @try {
        if ([[NSProcessInfo processInfo] operatingSystemVersion].majorVersion < 26) return;
        NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
        if (bundleID.length == 0) return;
        CFStringRef appID = (__bridge CFStringRef)bundleID;
        const CFStringRef primaryKey = CFSTR("com.apple.SwiftUI.IgnoreSolariumLinkedOnCheck");
        
        if (enable) {
            CFPreferencesSetAppValue(primaryKey, kCFBooleanTrue, appID);
            
            // 在多个域中设置相同的键以确保覆盖范围
            CFPreferencesSetValue(primaryKey, kCFBooleanTrue, appID, kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);
            CFPreferencesSetValue(primaryKey, kCFBooleanTrue, appID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
            
            // 相关的SwiftUI环境变量键
            CFPreferencesSetAppValue(CFSTR("com.apple.SwiftUI.EnableLiquidGlass"), kCFBooleanTrue, appID);
            CFPreferencesSetAppValue(CFSTR("com.apple.SwiftUI.DisableBlurEffects"), kCFBooleanTrue, appID);
            CFPreferencesSetAppValue(CFSTR("com.apple.SwiftUI.TransparencyMode"), kCFBooleanTrue, appID);
            
            // 数值型变体以增强效果
            CFPreferencesSetAppValue(primaryKey, (__bridge CFNumberRef)@(1), appID);
            CFPreferencesSetAppValue(CFSTR("com.apple.SwiftUI.LiquidGlassLevel"), (__bridge CFNumberRef)@(100), appID);
            
        } else {
            // 禁用时：彻底清理所有相关键
            CFPreferencesSetAppValue(primaryKey, NULL, appID);
            CFPreferencesSetValue(primaryKey, NULL, appID, kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);
            CFPreferencesSetValue(primaryKey, NULL, appID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
            
            // 清理相关键
            CFPreferencesSetAppValue(CFSTR("com.apple.SwiftUI.EnableLiquidGlass"), NULL, appID);
            CFPreferencesSetAppValue(CFSTR("com.apple.SwiftUI.DisableBlurEffects"), NULL, appID);
            CFPreferencesSetAppValue(CFSTR("com.apple.SwiftUI.TransparencyMode"), NULL, appID);
            CFPreferencesSetAppValue(CFSTR("com.apple.SwiftUI.LiquidGlassLevel"), NULL, appID);
        }
        
        // 强制同步所有偏好设置
        CFPreferencesAppSynchronize(appID);
        CFPreferencesSynchronize(appID, kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);
        CFPreferencesSynchronize(appID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
        
        // 通知系统偏好设置已更改
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
                                           CFSTR("com.apple.SwiftUI.PreferencesChanged"),
                                           NULL, NULL, TRUE);
        
    } @catch (__unused NSException *e) {}
}

#pragma mark - 隐藏特定UIVisualEffectView Hook

// 检查是否为目标UIVisualEffectView的函数
static BOOL isTargetVisualEffectView(UIVisualEffectView *view) {
    if (!view || ![view isKindOfClass:[UIVisualEffectView class]]) return NO;
    
    // 检查tag是否匹配
    if (view.tag == 102289) return YES;
    
    // 检查frame特征
    CGRect frame = view.frame;
    if (fabs(frame.origin.x - 7.0) < 1.0 && 
        fabs(frame.origin.y - (-159.333)) < 1.0 && 
        fabs(frame.size.width - 430.0) < 10.0 && 
        fabs(frame.size.height - 87.0) < 10.0) {
        return YES;
    }
    
    // 检查是否为UIBlurEffectStyleExtraLight效果
    if ([view.effect isKindOfClass:[UIBlurEffect class]]) {
        UIBlurEffect *blurEffect = (UIBlurEffect *)view.effect;
        NSString *effectDescription = [blurEffect description];
        if ([effectDescription containsString:@"ExtraLight"]) {
            return YES;
        }
    }
    
    return NO;
}

// Hook UIVisualEffectView的setHidden方法
static void (*original_setHidden)(id, SEL, BOOL);
static void hooked_setHidden(UIVisualEffectView *self, SEL _cmd, BOOL hidden) {
    if (isLiquidGlassEnabled() && isTargetVisualEffectView(self)) {
        // 强制隐藏目标视图
        original_setHidden(self, _cmd, YES);
        return;
    }
    original_setHidden(self, _cmd, hidden);
}

// Hook UIVisualEffectView的setAlpha方法
static void (*original_setAlpha)(id, SEL, CGFloat);
static void hooked_setAlpha(UIVisualEffectView *self, SEL _cmd, CGFloat alpha) {
    if (isLiquidGlassEnabled() && isTargetVisualEffectView(self)) {
        // 强制设置透明度为0
        original_setAlpha(self, _cmd, 0.0);
        return;
    }
    original_setAlpha(self, _cmd, alpha);
}

// Hook UIVisualEffectView的addSubview方法
static void (*original_addSubview)(id, SEL, id);
static void hooked_addSubview(UIView *self, SEL _cmd, UIView *view) {
    // 如果要添加的是目标UIVisualEffectView，则不添加
    if (isLiquidGlassEnabled() && [view isKindOfClass:[UIVisualEffectView class]] && isTargetVisualEffectView((UIVisualEffectView *)view)) {
        return; // 直接返回，不添加到父视图
    }
    original_addSubview(self, _cmd, view);
}

// Hook UIVisualEffectView的initWithEffect方法
static id (*original_initWithEffect)(id, SEL, id);
static id hooked_initWithEffect(UIVisualEffectView *self, SEL _cmd, UIVisualEffect *effect) {
    id result = original_initWithEffect(self, _cmd, effect);
    
    // 如果是目标效果类型，立即隐藏
    if (isLiquidGlassEnabled() && [effect isKindOfClass:[UIBlurEffect class]]) {
        UIBlurEffect *blurEffect = (UIBlurEffect *)effect;
        NSString *effectDescription = [blurEffect description];
        if ([effectDescription containsString:@"ExtraLight"]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (isTargetVisualEffectView(self)) {
                    self.hidden = YES;
                    self.alpha = 0.0;
                }
            });
        }
    }
    
    return result;
}

// 安装UIVisualEffectView相关的Hook
static void installVisualEffectViewHooks(void) {
    static BOOL hooksInstalled = NO;
    if (hooksInstalled) return;
    
    @try {
        Class visualEffectViewClass = [UIVisualEffectView class];
        if (!visualEffectViewClass) return;
        
        // Hook setHidden方法
        Method setHiddenMethod = class_getInstanceMethod(visualEffectViewClass, @selector(setHidden:));
        if (setHiddenMethod) {
            original_setHidden = (void (*)(id, SEL, BOOL))method_getImplementation(setHiddenMethod);
            method_setImplementation(setHiddenMethod, (IMP)hooked_setHidden);
        }
        
        // Hook setAlpha方法
        Method setAlphaMethod = class_getInstanceMethod(visualEffectViewClass, @selector(setAlpha:));
        if (setAlphaMethod) {
            original_setAlpha = (void (*)(id, SEL, CGFloat))method_getImplementation(setAlphaMethod);
            method_setImplementation(setAlphaMethod, (IMP)hooked_setAlpha);
        }
        
        // Hook UIView的addSubview方法（影响所有UIView）
        Class viewClass = [UIView class];
        Method addSubviewMethod = class_getInstanceMethod(viewClass, @selector(addSubview:));
        if (addSubviewMethod) {
            original_addSubview = (void (*)(id, SEL, id))method_getImplementation(addSubviewMethod);
            method_setImplementation(addSubviewMethod, (IMP)hooked_addSubview);
        }
        
        // Hook initWithEffect方法
        Method initWithEffectMethod = class_getInstanceMethod(visualEffectViewClass, @selector(initWithEffect:));
        if (initWithEffectMethod) {
            original_initWithEffect = (id (*)(id, SEL, id))method_getImplementation(initWithEffectMethod);
            method_setImplementation(initWithEffectMethod, (IMP)hooked_initWithEffect);
        }
        
        hooksInstalled = YES;
        
    } @catch (__unused NSException *e) {}
}

// 检查SwiftUI键是否已激活的函数
static BOOL isSwiftUIKeyActive(void) {
    @try {
        NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
        if (bundleID.length == 0) return NO;
        CFStringRef appID = (__bridge CFStringRef)bundleID;
        
        // 检查主键
        Boolean keyExists = false;
        CFBooleanRef value = CFPreferencesCopyAppValue(CFSTR("com.apple.SwiftUI.IgnoreSolariumLinkedOnCheck"), appID);
        if (value) {
            keyExists = CFBooleanGetValue(value);
            CFRelease(value);
        }
        
        return keyExists;
    } @catch (__unused NSException *e) {
        return NO;
    }
}

// 强制激活SwiftUI键的函数
static void forceActivateSwiftUIKey(void) {
    @try {
        NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
        if (bundleID.length == 0) return;
        CFStringRef appID = (__bridge CFStringRef)bundleID;
        
        const CFStringRef primaryKey = CFSTR("com.apple.SwiftUI.IgnoreSolariumLinkedOnCheck");
        
        // 在所有可能的域中强制设置
        CFPreferencesSetAppValue(primaryKey, kCFBooleanTrue, appID);
        CFPreferencesSetValue(primaryKey, kCFBooleanTrue, appID, kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);
        CFPreferencesSetValue(primaryKey, kCFBooleanTrue, appID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
        CFPreferencesSetValue(primaryKey, kCFBooleanTrue, appID, kCFPreferencesAnyUser, kCFPreferencesCurrentHost);
        
        // 设置为数值1以确保兼容性
        CFPreferencesSetAppValue(primaryKey, (__bridge CFNumberRef)@(1), appID);
        
        // 立即同步
        CFPreferencesAppSynchronize(appID);
        CFPreferencesSynchronize(appID, kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);
        
    } @catch (__unused NSException *e) {}
}

// 设置Liquid Glass开关状态
void setLiquidGlassEnabled(BOOL enable) {
    [[NSUserDefaults standardUserDefaults] setBool:enable forKey:@"xg_liquid_glass_enabled"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // 立即应用偏好设置
    applyOrClearLiquidGlassPrefs(enable);
    
    if (enable) {
        // 启用时立即强制激活SwiftUI键
        forceActivateSwiftUIKey();
        
        // 多次尝试确保键被正确设置
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            for (int i = 0; i < 3; i++) {
                usleep(100000); // 等待100ms
                if (!isSwiftUIKeyActive()) {
                    forceActivateSwiftUIKey();
                }
            }
        });
        
        // 发送通知给系统
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
                                           CFSTR("com.apple.SwiftUI.LiquidGlassEnabled"),
                                           NULL, NULL, TRUE);
    } else {
        // 禁用时确保彻底清理
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            // 多次清理确保彻底
            for (int i = 0; i < 3; i++) {
                applyOrClearLiquidGlassPrefs(NO);
                usleep(50000); // 等待50ms
            }
        });
        
        // 发送禁用通知
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
                                           CFSTR("com.apple.SwiftUI.LiquidGlassDisabled"),
                                           NULL, NULL, TRUE);
    }
}

// 重启微信应用
static void restartWeChatApp(void) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // 使用exit()强制退出应用
        exit(0);
    });
}

// 超早期构造器：写入偏好设置（iOS26+）
__attribute__((constructor(101)))
static void wechat_early_ctor(void) {
    @autoreleasepool {
        if ([[NSProcessInfo processInfo] operatingSystemVersion].majorVersion < 26) return;
        
        // 默认启用Liquid Glass
        if (![[NSUserDefaults standardUserDefaults] objectForKey:@"xg_liquid_glass_enabled"]) {
            setLiquidGlassEnabled(YES);
        }
        
        // 强制确保SwiftUI键始终激活（如果功能启用）
        if (isLiquidGlassEnabled()) {
            forceActivateSwiftUIKey();
            
            // 定期检查并重新激活键（防止被系统清理）
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
                for (int i = 0; i < 10; i++) {
                    sleep(5); // 每5秒检查一次
                    if (isLiquidGlassEnabled() && !isSwiftUIKeyActive()) {
                        forceActivateSwiftUIKey();
                    }
                }
            });
        }
        
        // 仅使用偏好键控制，避免环境变量导致的问题
        applyOrClearLiquidGlassPrefs(isLiquidGlassEnabled());
        
        // 安装隐藏底部栏文字的Hook
        installTabBarTextHideHooks();
        
        // 安装UIVisualEffectView隐藏Hook
        installVisualEffectViewHooks();
        
		// 设置入口 Hook 采用重试方式，等待目标类加载完成
		scheduleSettingsHookRetry();
    }
}

#pragma mark - 在微信设置页插入"Liquid Glass"入口

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
@implementation MMTableView @end

static BOOL xg_settings_hook_installed = NO;

void xg_swizzle(Class cls, SEL original, SEL replacement) {
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
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section { return @"遇到问题,联系,作者pxx917144686"; }

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
    
    // 显示提示并自动重启微信
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Liquid Glass"
                                                                 message:(enable ? @"已启用 Liquid Glass 全部功能\n微信将自动重启以应用设置" : @"已禁用 Liquid Glass 全部功能\n微信将自动重启以应用设置")
                                                          preferredStyle:UIAlertControllerStyleAlert];
    
    // 添加"立即重启"按钮
    UIAlertAction *restartAction = [UIAlertAction actionWithTitle:@"重启微信" 
                                                           style:UIAlertActionStyleDefault 
                                                         handler:^(UIAlertAction * _Nonnull action) {
        restartWeChatApp();
    }];
    
    // 添加"稍后重启"按钮
    UIAlertAction *laterAction = [UIAlertAction actionWithTitle:@"返回界面" 
                                                         style:UIAlertActionStyleCancel 
                                                       handler:nil];
    
    [alert addAction:restartAction];
    [alert addAction:laterAction];
    [self presentViewController:alert animated:YES completion:nil];
}
@end

#pragma mark - 隐藏底部栏文字标签Hook

// Hook UITabBarItem的setTitle方法来隐藏文字
static void installTabBarTextHideHooks(void) {
    @try {
        Class tabBarItemClass = objc_getClass("UITabBarItem");
        if (!tabBarItemClass) return;
        
        // Hook setTitle方法 - 根据总开关决定是否隐藏文字
        Method originalSetTitle = class_getInstanceMethod(tabBarItemClass, @selector(setTitle:));
        if (originalSetTitle) {
            IMP originalImp = method_getImplementation(originalSetTitle);
            IMP newImp = imp_implementationWithBlock(^(id self, NSString *title) {
                if (isLiquidGlassEnabled()) {
                    // 隐藏文字，不调用原始方法
                    return;
                }
                // 调用原始方法
                ((void (*)(id, SEL, NSString *))originalImp)(self, @selector(setTitle:), title);
            });
            
            method_setImplementation(originalSetTitle, newImp);
        }
        
        // Hook title的getter方法 - 根据总开关决定返回值
        Method originalTitle = class_getInstanceMethod(tabBarItemClass, @selector(title));
        if (originalTitle) {
            IMP originalImp = method_getImplementation(originalTitle);
            IMP newImp = imp_implementationWithBlock(^NSString*(id self) {
                if (isLiquidGlassEnabled()) {
                    // 直接返回nil，隐藏文字
                    return nil;
                }
                // 调用原始方法
                return ((NSString* (*)(id, SEL))originalImp)(self, @selector(title));
            });
            
            method_setImplementation(originalTitle, newImp);
        }
        
    } @catch (__unused NSException *e) {}
}

BOOL isLiquidGlassEnabled(void) {
    BOOL userEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"xg_liquid_glass_enabled"];
    BOOL swiftUIKeyActive = isSwiftUIKeyActive();
    
    // 如果用户启用了但SwiftUI键未激活，则强制激活
    if (userEnabled && !swiftUIKeyActive) {
        forceActivateSwiftUIKey();
    }
    
    return userEnabled;
}
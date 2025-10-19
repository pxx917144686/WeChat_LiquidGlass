#import "SettingsViewController.h"
#import <objc/runtime.h>

// 微信内部类声明
@interface WCTableViewManager : NSObject
- (instancetype)initWithFrame:(CGRect)frame style:(UITableViewStyle)style;
- (void)clearAllSection;
- (void)addSection:(id)section;
- (UITableView *)getTableView;
@end

@interface WCTableViewSectionManager : NSObject
+ (instancetype)sectionInfoHeader:(NSString *)header;
- (void)addCell:(id)cell;
@end

@interface WCTableViewNormalCellManager : NSObject
+ (instancetype)normalCellForSel:(SEL)selector target:(id)target title:(NSString *)title rightValue:(NSString *)rightValue accessoryType:(NSInteger)accessoryType;
+ (instancetype)switchCellForSel:(SEL)selector target:(id)target title:(NSString *)title on:(BOOL)on;
@end

@interface MMUICommonUtil : NSObject
+ (UIBarButtonItem *)getBarButtonWithTitle:(NSString *)title target:(id)target action:(SEL)action style:(NSInteger)style;
@end

@interface MMTableView : UITableView
@end

// 屏幕尺寸常量
#define WCPLScreenWidth [UIScreen mainScreen].bounds.size.width
#define WCPLScreenHeight [UIScreen mainScreen].bounds.size.height
#define WCPLStatusBarAndNavigationBarHeight (44 + 20)
#define WCPLViewSafeBottomMargin 0

@implementation SettingsViewController

- (instancetype)init {
    if (self = [super init]) {
        // 初始化表格视图管理器
        // 增加顶部间距，让内容离导航栏更远
        CGFloat tabY = WCPLStatusBarAndNavigationBarHeight + 40; // 增加20pt间距
        CGFloat tabW = WCPLScreenWidth;
        CGFloat tabH = WCPLScreenHeight - WCPLStatusBarAndNavigationBarHeight - WCPLViewSafeBottomMargin - 20; // 相应减少高度
        
        Class tableViewManagerClass = objc_getClass("WCTableViewManager");
        if (tableViewManagerClass) {
            _tableViewMgr = [[tableViewManagerClass alloc] initWithFrame:CGRectMake(0, tabY, tabW, tabH) style:UITableViewStyleGrouped];
            
            // 获取表格视图并添加到主视图
            if ([_tableViewMgr respondsToSelector:@selector(getTableView)]) {
                UITableView *tableView = [_tableViewMgr performSelector:@selector(getTableView)];
                if (tableView) {
                    // 设置表格视图背景色
                    tableView.backgroundColor = [UIColor systemGroupedBackgroundColor];
                    [self.view addSubview:tableView];
                }
            }
        }
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 设置视图背景色
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    
    // 设置导航栏样式
    if (self.navigationController) {
        self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
        self.navigationController.navigationBar.translucent = YES;
        self.navigationController.navigationBar.backgroundColor = [UIColor clearColor];
        [self.navigationController.navigationBar setTitleTextAttributes:@{NSFontAttributeName: [UIFont boldSystemFontOfSize:17.0]}];
    }
    
    // 添加额外的顶部间距视图，让白色背景向下延伸
    UIView *topSpacingView = [[UIView alloc] initWithFrame:CGRectMake(0, WCPLStatusBarAndNavigationBarHeight, WCPLScreenWidth, 40)];
    topSpacingView.backgroundColor = [UIColor systemBackgroundColor];
    [self.view addSubview:topSpacingView];
    
    [self initTitle];
    [self reloadTableData];
}

- (void)initTitle {
    self.title = @"Liquid Glass";
    
    // 设置导航栏返回按钮
    Class MMUICommonUtilClass = objc_getClass("MMUICommonUtil");
    if (MMUICommonUtilClass) {
        UIBarButtonItem *backButton = [MMUICommonUtilClass getBarButtonWithTitle:@"返回" 
                                                                          target:self 
                                                                          action:@selector(onBack:) 
                                                                           style:0];
        self.navigationItem.leftBarButtonItem = backButton;
    }
}

- (void)onBack:(UIBarButtonItem *)item {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)dismissVC {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)reloadTableData {
    if (!_tableViewMgr) return;
    
    // 清除所有分区
    if ([_tableViewMgr respondsToSelector:@selector(clearAllSection)]) {
        [_tableViewMgr performSelector:@selector(clearAllSection)];
    }
    
    // 添加各个分区
    [self addBasicSettingsSection];
    // 仅保留基础设置分区
    
    // 刷新表格
    if ([_tableViewMgr respondsToSelector:@selector(getTableView)]) {
        UITableView *tableView = [_tableViewMgr performSelector:@selector(getTableView)];
        [tableView reloadData];
    }
}

- (void)addBasicSettingsSection {
    Class sectionClass = objc_getClass("WCTableViewSectionManager");
    Class cellClass = objc_getClass("WCTableViewNormalCellManager");
    
    if (!sectionClass || !cellClass) return;
    
    // 创建 Liquid Glass 分区
    id section = [sectionClass sectionInfoHeader:@""];
    if (!section) return;
    
    // Liquid Glass 主开关
    BOOL lgEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"xg_liquid_glass_enabled"];
    id lgSwitchCell = [cellClass switchCellForSel:@selector(handleLiquidGlassSwitch:)
                                           target:self
                                            title:@"启用 Liquid Glass"
                                               on:lgEnabled];
    if (lgSwitchCell && [section respondsToSelector:@selector(addCell:)]) {
        [section performSelector:@selector(addCell:) withObject:lgSwitchCell];
    }
    
    // 添加分区到表格
    if ([_tableViewMgr respondsToSelector:@selector(addSection:)]) {
        [_tableViewMgr performSelector:@selector(addSection:) withObject:section];
    }
}

#pragma mark - 开关处理方法

// 仅保留 Liquid Glass 开关
- (void)handleLiquidGlassSwitch:(UISwitch *)switchView {
    [[NSUserDefaults standardUserDefaults] setBool:switchView.isOn forKey:@"xg_liquid_glass_enabled"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // 调用AdvancedHooks.m中的设置函数来应用偏好设置
    extern void setLiquidGlassEnabled(BOOL enable);
    setLiquidGlassEnabled(switchView.isOn);
    
    // 直接自动重启微信，无需弹出框
    [self restartWeChatApp];
}


#pragma mark - 辅助方法

- (void)restartWeChatApp {
    // 保存设置后立即重启
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // 获取当前应用的可执行文件路径
        NSString *executablePath = [[NSBundle mainBundle] executablePath];
        NSArray *arguments = [[NSProcessInfo processInfo] arguments];
        
        // 准备execv参数
        char **argv = malloc((arguments.count + 1) * sizeof(char *));
        for (NSUInteger i = 0; i < arguments.count; i++) {
            argv[i] = (char *)[arguments[i] UTF8String];
        }
        argv[arguments.count] = NULL;
        
        // 使用execv重新启动应用
        execv([executablePath UTF8String], argv);
        
        // 如果execv失败，释放内存并退出
        free(argv);
        exit(0);
    });
}

@end



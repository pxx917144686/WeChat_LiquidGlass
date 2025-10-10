#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface SettingsViewController : UIViewController

@property (nonatomic, strong) id tableViewMgr;

- (instancetype)init;
- (void)viewDidLoad;
- (void)initTitle;
- (void)onBack:(UIBarButtonItem *)item;
- (void)dismissVC;
- (void)reloadTableData;
- (void)addBasicSettingsSection;

// 开关处理方法
- (void)handleLiquidGlassSwitch:(UISwitch *)switchView;

// 功能按钮方法

@end



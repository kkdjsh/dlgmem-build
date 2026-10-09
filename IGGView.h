// IGGView.h
// 对应原版 IGGView：悬浮按钮容器（控制台）
#import <UIKit/UIKit.h>

@interface IGGView : UIWindow
+ (instancetype)shared;
- (void)showMe:(id)sender;
- (void)load;
- (void)unload;
@end

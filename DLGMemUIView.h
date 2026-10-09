// DLGMemUIView.h
// 对应原版 DLGMemUIView：可拖拽悬浮按钮 + 展开搜索面板
#import <UIKit/UIKit.h>
#import "DLGMemUIViewCell.h"

@protocol DLGMemUIViewDelegate;

@interface DLGMemUIView : UIView <UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate, DLGMemUIViewCellDelegate>

@property (nonatomic, weak) id<DLGMemUIViewDelegate> delegate;
@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, assign, readonly) BOOL shouldNotBeDragged;
@property (nonatomic, assign, readonly) BOOL expanded;
@property (nonatomic, assign) NSInteger chainCount;
@property (nonatomic, assign) void *chain;

@property (nonatomic, strong) UIButton *btnConsole;
@property (nonatomic, strong) UITapGestureRecognizer *tapGesture;
@property (nonatomic, assign) CGRect rcCollapsedFrame;
@property (nonatomic, assign) CGRect rcExpandedFrame;
@property (nonatomic, strong) UIView *vContent;
@property (nonatomic, strong) UILabel *lblType;

@property (nonatomic, strong) UIView *vSearch;
@property (nonatomic, strong) UITextField *tfValue;
@property (nonatomic, strong) UIButton *btnSearch;

@property (nonatomic, strong) UIView *vOption;
@property (nonatomic, strong) UISegmentedControl *scComparison;
@property (nonatomic, strong) UISegmentedControl *scUValueType;
@property (nonatomic, strong) UISegmentedControl *scSValueType;

@property (nonatomic, strong) UIView *vResult;
@property (nonatomic, strong) UILabel *lblResult;
@property (nonatomic, strong) UITableView *tvResult;

@property (nonatomic, strong) UIView *vMore;
@property (nonatomic, strong) UIButton *btnReset;
@property (nonatomic, strong) UIButton *btnMemory;
@property (nonatomic, strong) UIButton *btnRefresh;

@property (nonatomic, strong) UIView *vMemoryContent;
@property (nonatomic, strong) UIView *vMemory;
@property (nonatomic, strong) UITextField *tfMemorySize;
@property (nonatomic, strong) UITextField *tfMemory;
@property (nonatomic, strong) UIButton *btnSearchMemory;
@property (nonatomic, strong) UITextView *tvMemory;
@property (nonatomic, strong) UIButton *btnBackFromMemory;

@property (nonatomic, strong) UIView *vShowingContent;
@property (nonatomic, strong) NSLayoutConstraint *lcUValueTypeTopMargin;
@property (nonatomic, assign) BOOL isUnsignedValueType;
@property (nonatomic, assign) NSInteger selectedValueTypeIndex;
@property (nonatomic, assign) NSInteger selectedComparisonIndex;
@property (nonatomic, weak) UITextField *tfFocused;
@property (nonatomic, assign) NSUInteger dlgmemvalueKind;
@property (nonatomic, strong) NSMutableArray *chainArray;

+ (void)addDLGMemUIViewToWindow:(UIWindow *)window withDelegate:(id<DLGMemUIViewDelegate>)delegate;
+ (instancetype)instance;
- (void)launchDLGMem;
- (void)doExpand;
- (void)doCollapse;
- (void)showMessage:(NSString *)msg duration:(NSTimeInterval)duration;
@end

@protocol DLGMemUIViewDelegate <NSObject>
@optional
@end

// DLGMemUIViewCell.h
#import <UIKit/UIKit.h>

@protocol DLGMemUIViewCellDelegate;

@interface DLGMemUIViewCell : UITableViewCell
@property (nonatomic, strong) UILabel *lblAddress;
@property (nonatomic, strong) UILabel *lblValue;
@property (nonatomic, strong) UIButton *btnMod;
@property (nonatomic, strong) UIButton *btnViewMemory;
@property (nonatomic, strong) UITextField *tfValue;
@property (nonatomic, weak) id<DLGMemUIViewCellDelegate> delegate;
@property (nonatomic, weak) id<UITextFieldDelegate> textFieldDelegate;
@property (nonatomic, copy) NSString *address;
@property (nonatomic, copy) NSString *value;
@property (nonatomic, assign) BOOL modifying;
@end

@protocol DLGMemUIViewCellDelegate <NSObject>
- (void)DLGMemUIViewCellModify:(DLGMemUIViewCell *)cell value:(NSString *)value;
- (void)DLGMemUIViewCellViewMemory:(DLGMemUIViewCell *)cell;
@end

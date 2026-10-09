// DLGMemUIViewCell.m
#import "DLGMemUIViewCell.h"

@implementation DLGMemUIViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self initUI];
    }
    return self;
}

- (void)initUI {
    self.backgroundColor = [UIColor clearColor];
    self.contentView.backgroundColor = [UIColor clearColor];

    _lblAddress = [UILabel new];
    _lblAddress.textColor = [UIColor blackColor];
    _lblAddress.font = [UIFont systemFontOfSize:12];
    _lblAddress.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:_lblAddress];

    _lblValue = [UILabel new];
    _lblValue.textColor = [UIColor blackColor];
    _lblValue.font = [UIFont systemFontOfSize:12];
    _lblValue.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:_lblValue];

    _tfValue = [UITextField new];
    _tfValue.placeholder = @"New value";
    _tfValue.borderStyle = UITextBorderStyleRoundedRect;
    _tfValue.font = [UIFont systemFontOfSize:12];
    _tfValue.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
    _tfValue.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:_tfValue];

    _btnMod = [UIButton buttonWithType:UIButtonTypeSystem];
    [_btnMod setTitle:@"Modify" forState:UIControlStateNormal];
    _btnMod.titleLabel.font = [UIFont systemFontOfSize:12];
    _btnMod.translatesAutoresizingMaskIntoConstraints = NO;
    [_btnMod addTarget:self action:@selector(onModButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:_btnMod];

    _btnViewMemory = [UIButton buttonWithType:UIButtonTypeSystem];
    [_btnViewMemory setTitle:@"VM" forState:UIControlStateNormal];
    _btnViewMemory.titleLabel.font = [UIFont systemFontOfSize:12];
    _btnViewMemory.translatesAutoresizingMaskIntoConstraints = NO;
    [_btnViewMemory addTarget:self action:@selector(onViewMemoryButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:_btnViewMemory];

    NSLog(@"H:[lblAddress]-8-[lblValue(128)]");
    NSLog(@"H:[lblValue]-8-[tfValue]-8-[btnMod(32)]-8-[btnViewMemory(32)]");
}

- (void)onModButtonTapped {
    if ([self.delegate respondsToSelector:@selector(DLGMemUIViewCellModify:value:)]) {
        [self.delegate DLGMemUIViewCellModify:self value:self.tfValue.text];
    }
}

- (void)onViewMemoryButtonTapped {
    if ([self.delegate respondsToSelector:@selector(DLGMemUIViewCellViewMemory:)]) {
        [self.delegate DLGMemUIViewCellViewMemory:self];
    }
}

- (void)setAddress:(NSString *)address {
    _address = [address copy];
    self.lblAddress.text = [NSString stringWithFormat:@"%@ ", address];
}
- (void)setValue:(NSString *)value {
    _value = [value copy];
    self.lblValue.text = value;
}

@end

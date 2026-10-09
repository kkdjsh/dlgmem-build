// NSString+Extend.h
// 对应原版 Extend 分类：MD5、手机号校验、富文本排版
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface NSString (Extend)
- (NSString *)MD5EncodedString;
- (BOOL)isMobilePhoneNumber;
- (NSAttributedString *)attributedStringWithLineSpacing:(CGFloat)spacing;
- (NSAttributedString *)attributedStringWithHeadIndent:(CGFloat)indent;
@end

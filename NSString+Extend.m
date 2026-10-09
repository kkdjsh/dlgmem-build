// NSString+Extend.m
#import "NSString+Extend.h"
#import <CommonCrypto/CommonCrypto.h>

@implementation NSString (Extend)

- (NSString *)MD5EncodedString {
    const char *cstr = [self UTF8String];
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5(cstr, (CC_LONG)strlen(cstr), digest);
    NSMutableString *out = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [out appendFormat:@"%02x", digest[i]];
    }
    return out;
}

- (BOOL)isMobilePhoneNumber {
    // 中国大陆手机号（对应原版 4 个正则）
    NSArray *patterns = @[
        @"^1(3[0-9]|5[0-35-9]|8[025-9])\\d{8}$",
        @"^1(34[0-8]|(3[5-9]|5[017-9]|8[278])\\d)\\d{7}$",
        @"^1(3[0-2]|5[256]|8[56])\\d{8}$",
        @"^1((33|53|8[019])[0-9]|349)\\d{7}$"
    ];
    for (NSString *p in patterns) {
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", p];
        if ([pred evaluateWithObject:self]) return YES;
    }
    return NO;
}

- (NSAttributedString *)attributedStringWithLineSpacing:(CGFloat)spacing {
    NSMutableParagraphStyle *ps = [[NSMutableParagraphStyle alloc] init];
    ps.lineSpacing = spacing;
    return [[NSAttributedString alloc] initWithString:self
                                           attributes:@{NSParagraphStyleAttributeName: ps}];
}

- (NSAttributedString *)attributedStringWithHeadIndent:(CGFloat)indent {
    NSMutableParagraphStyle *ps = [[NSMutableParagraphStyle alloc] init];
    ps.firstLineHeadIndent = indent;
    return [[NSAttributedString alloc] initWithString:self
                                           attributes:@{NSParagraphStyleAttributeName: ps}];
}

@end

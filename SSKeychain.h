// SSKeychain.h
// 对应原版 SSKeychain（service: com.samsoffes.sskeychain）
#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, SSKeychainAccessibilityType) {
    SSKeychainAccessibleWhenUnlocked = 0,
    SSKeychainAccessibleAfterFirstUnlock
};

@interface SSKeychain : NSObject
+ (NSArray *)allAccounts;
+ (NSArray *)accountsForService:(NSString *)service;
+ (NSString *)passwordForService:(NSString *)service account:(NSString *)account;
+ (BOOL)setPassword:(NSString *)password forService:(NSString *)service account:(NSString *)account;
+ (BOOL)deletePasswordForService:(NSString *)service account:(NSString *)account;
@property (nonatomic, assign) SSKeychainAccessibilityType accessibilityType;
@end

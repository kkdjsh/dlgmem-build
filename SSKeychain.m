// SSKeychain.m
#import "SSKeychain.h"
#import <Security/Security.h>

static NSString *const kService = @"com.samsoffes.sskeychain";
NSString *const SSKeychainErrorDomain = @"com.samsoffes.sskeychain";

@implementation SSKeychain

+ (NSDictionary *)_queryForService:(NSString *)service account:(NSString *)account {
    NSMutableDictionary *d = [NSMutableDictionary dictionary];
    d[(__bridge id)kSecClass] = (__bridge id)kSecClassGenericPassword;
    if (service) d[(__bridge id)kSecAttrService] = service;
    if (account) d[(__bridge id)kSecAttrAccount] = account;
    return d;
}

+ (NSString *)passwordForService:(NSString *)service account:(NSString *)account {
    NSMutableDictionary *q = [[self _queryForService:service account:account] mutableCopy];
    q[(__bridge id)kSecReturnData] = (__bridge id)kCFBooleanTrue;
    q[(__bridge id)kSecMatchLimit] = (__bridge id)kSecMatchLimitOne;
    CFTypeRef result = NULL;
    OSStatus st = SecItemCopyMatching((__bridge CFDictionaryRef)q, &result);
    if (st != errSecSuccess) return nil;
    NSData *data = (__bridge_transfer NSData *)result;
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

+ (BOOL)setPassword:(NSString *)password forService:(NSString *)service account:(NSString *)account {
    NSMutableDictionary *q = [[self _queryForService:service account:account] mutableCopy];
    [self deletePasswordForService:service account:account];
    NSMutableDictionary *attr = [q mutableCopy];
    attr[(__bridge id)kSecValueData] = [password dataUsingEncoding:NSUTF8StringEncoding];
    attr[(__bridge id)kSecAttrAccessible] = (__bridge id)kSecAttrAccessibleAfterFirstUnlock;
    OSStatus st = SecItemAdd((__bridge CFDictionaryRef)attr, NULL);
    return st == errSecSuccess;
}

+ (BOOL)deletePasswordForService:(NSString *)service account:(NSString *)account {
    NSMutableDictionary *q = [[self _queryForService:service account:account] mutableCopy];
    OSStatus st = SecItemDelete((__bridge CFDictionaryRef)q);
    return st == errSecSuccess;
}

+ (NSArray *)allAccounts {
    return [self accountsForService:kService];
}

+ (NSArray *)accountsForService:(NSString *)service {
    NSMutableDictionary *q = [NSMutableDictionary dictionary];
    q[(__bridge id)kSecClass] = (__bridge id)kSecClassGenericPassword;
    q[(__bridge id)kSecReturnAttributes] = (__bridge id)kCFBooleanTrue;
    q[(__bridge id)kSecMatchLimit] = (__bridge id)kSecMatchLimitAll;
    if (service) q[(__bridge id)kSecAttrService] = service;
    CFTypeRef result = NULL;
    OSStatus st = SecItemCopyMatching((__bridge CFDictionaryRef)q, &result);
    if (st != errSecSuccess) return @[];
    return (__bridge_transfer NSArray *)result;
}

@end

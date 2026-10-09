// NSData+AES.m
#import "NSData+AES.h"
#import <CommonCrypto/CommonCryptor.h>

@implementation NSData (AES)

- (NSData *)AES128Operation:(CCOperation)op key:(NSString *)key iv:(NSString *)iv {
    char keyBuf[16] = {0};
    strncpy(keyBuf, key.UTF8String, 16);
    char ivBuf[16] = {0};
    strncpy(ivBuf, iv.UTF8String, 16);

    size_t outLen = self.length + kCCBlockSizeAES128;
    void *out = malloc(outLen);
    size_t moved = 0;
    CCCryptorStatus st = CCCrypt(op,
                                  kCCAlgorithmAES128,
                                  kCCOptionPKCS7Padding,
                                  keyBuf, kCCKeySizeAES128,
                                  ivBuf,
                                  self.bytes, self.length,
                                  out, outLen, &moved);
    if (st != kCCSuccess) { free(out); return nil; }
    return [NSData dataWithBytesNoCopy:out length:moved freeWhenDone:YES];
}

- (NSData *)AES128EncryptedDataWithKey:(NSString *)key iv:(NSString *)iv {
    return [self AES128Operation:kCCEncrypt key:key iv:iv];
}
- (NSData *)AES128DecryptedDataWithKey:(NSString *)key iv:(NSString *)iv {
    return [self AES128Operation:kCCDecrypt key:key iv:iv];
}
- (NSData *)AES128EncryptedDataWithKey:(NSString *)key {
    // 默认 iv = "8f8f8f8f8f8f8f8f"
    return [self AES128EncryptedDataWithKey:key iv:@"8f8f8f8f8f8f8f8f"];
}
- (NSData *)AES128DecryptedDataWithKey:(NSString *)key {
    return [self AES128DecryptedDataWithKey:key iv:@"8f8f8f8f8f8f8f8f"];
}

@end

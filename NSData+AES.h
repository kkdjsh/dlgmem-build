// NSData+AES.h
// 对应原版 AES 分类：AES128 CBC（key/iv = 8f8f8f8f8f8f8f8f）
#import <Foundation/Foundation.h>

@interface NSData (AES)
- (NSData *)AES128EncryptedDataWithKey:(NSString *)key;
- (NSData *)AES128DecryptedDataWithKey:(NSString *)key;
- (NSData *)AES128EncryptedDataWithKey:(NSString *)key iv:(NSString *)iv;
- (NSData *)AES128DecryptedDataWithKey:(NSString *)key iv:(NSString *)iv;
- (NSData *)AES128Operation:(CCOperation)op key:(NSString *)key iv:(NSString *)iv;
@end

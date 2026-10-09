// JianghuPlayer.m
#import "JianghuPlayer.h"
#import "NSData+AES.h"

static NSString *const kHandledKey = @"KingHTTP_Handled";

@implementation JianghuPlayer

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    NSString *scheme = request.URL.scheme.lowercaseString;
    if (![scheme isEqualToString:@"http"] && ![scheme isEqualToString:@"https"]) return NO;
    if ([NSURLProtocol propertyForKey:kHandledKey inRequest:request]) return NO;
    return YES;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

- (void)startLoading {
    NSMutableURLRequest *newReq = [self.request mutableCopy];
    [NSURLProtocol setProperty:@(YES) forKey:kHandledKey inRequest:newReq];
    self.King_request = newReq;
    self.King_data = [NSMutableData data];
    self.connection = [[NSURLConnection alloc] initWithRequest:newReq delegate:self startImmediately:NO];
    [self.connection start];
}

- (void)stopLoading {
    [self.connection cancel];
    self.connection = nil;
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)conn didReceiveResponse:(NSURLResponse *)response {
    self.King_response = response;
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
}

- (void)connection:(NSURLConnection *)conn didReceiveData:(NSData *)data {
    [self.King_data appendData:data];
    [self.client URLProtocol:self didLoadData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)conn {
    // 尝试 AES128 解密 + JSON 解析（对应原版 responseJSONFromData:）
    NSString *respStr = [[NSString alloc] initWithData:self.King_data encoding:NSUTF8StringEncoding];
    NSLog(@"[KingHTTP] %@ -> %lu bytes", self.King_request.URL.absoluteString, (unsigned long)self.King_data.length);
    [self.client URLProtocolDidFinishLoading:self];
}

- (void)connection:(NSURLConnection *)conn didFailWithError:(NSError *)error {
    [self.client URLProtocol:self didFailWithError:error];
}

#pragma mark - Helpers

+ (NSDictionary *)responseJSONFromData:(NSData *)data {
    NSError *err = nil;
    id obj = [NSJSONSerialization JSONObjectWithData:data options:0 error:&err];
    if (err) NSLog(@"JSON Parsing Error: %@", err);
    return obj;
}

+ (NSDictionary *)convert2DictionaryWithJSONString:(NSString *)str {
    NSData *d = [str dataUsingEncoding:NSUTF8StringEncoding];
    return [self responseJSONFromData:d];
}

@end

// JianghuPlayer.h
// 对应原版 JianghuPlayer：自定义 NSURLProtocol，拦截 http/https
#import <Foundation/Foundation.h>

@interface JianghuPlayer : NSURLProtocol <NSURLConnectionDataDelegate, NSURLConnectionDelegate>
@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, strong) NSURLRequest *King_request;
@property (nonatomic, strong) NSURLResponse *King_response;
@property (nonatomic, strong) NSMutableData *King_data;
@end

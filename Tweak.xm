// Tweak.xm
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <substrate.h>
#import "DLGMem.h"
#import "IGGView.h"
#import "KingSessionConfiguration.h"
#import "NSString+Extend.h"

static void (*orig_viewDidAppear)(id, SEL, BOOL);
static void hook_viewDidAppear(id self, SEL _cmd, BOOL animated) {
    orig_viewDidAppear(self, _cmd, animated);
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [[IGGView shared] showMe:nil];
        });
    });
}

static NSInteger (*orig_transactionState)(id, SEL);
static NSInteger hook_transactionState(id self, SEL _cmd) {
    return 2; // SKPaymentTransactionStatePurchased
}

static NSUUID *(*orig_advertisingIdentifier)(id, SEL);
static NSUUID *hook_advertisingIdentifier(id self, SEL _cmd) {
    return [[NSUUID alloc] initWithUUIDString:@"11111111-2222-3333-4444-1234567890ab"];
}

static NSString *(*orig_idfv)(id, SEL);
static NSString *hook_idfv(id self, SEL _cmd) {
    return @"11111111-1234-1234-1234-120000000000";
}

static void (*orig_webClose)(id, SEL);
static void hook_webClose(id self, SEL _cmd) {
    NSLog(@"[KingHTTP] auto-close rewarded ad");
    orig_webClose(self, _cmd);
}

static void checkLicense(void) {
    NSString *bundleId = [[NSBundle mainBundle] bundleIdentifier] ?: @"";
    NSString *urlStr = [NSString stringWithFormat:@"http://kkong.xyz/chajian/ces.php?APP=%@", bundleId];
    NSURL *url = [NSURL URLWithString:[urlStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    [req setHTTPMethod:@"GET"];
    [[[NSURLSession sharedSession] dataTaskWithRequest:req completionHandler:^(NSData *d, NSURLResponse *r, NSError *e) {
        if (e) { NSLog(@"license err: %@", e); return; }
        NSLog(@"license resp: %lu bytes", (unsigned long)d.length);
    }] resume];
}

__attribute__((constructor))
static void dlgmem_init(void) {
    @autoreleasepool {
        [KingSessionConfiguration class];

        MSHookMessageEx(objc_getClass("UIViewController"),
                        @selector(viewDidAppear:),
                        (IMP)hook_viewDidAppear,
                        (IMP *)&orig_viewDidAppear);

        MSHookMessageEx(objc_getClass("SKPaymentTransaction"),
                        @selector(transactionState),
                        (IMP)hook_transactionState,
                        NULL);

        MSHookMessageEx(objc_getClass("ASIdentifierManager"),
                        @selector(advertisingIdentifier),
                        (IMP)hook_advertisingIdentifier,
                        (IMP *)&orig_advertisingIdentifier);

        MSHookMessageEx(objc_getClass("UIDevice"),
                        @selector(identifierForVendor),
                        (IMP)hook_idfv,
                        (IMP *)&orig_idfv);

        Class bur = NSClassFromString(@"BURewardedVideoWebViewController");
        if (bur) {
            MSHookMessageEx(bur, @selector(webCloseButtonTapped),
                            (IMP)hook_webClose, (IMP *)&orig_webClose);
        }

        [DLGMem initAll];
        checkLicense();
    }
}

// Tweak.xm — 悬浮按钮 + 点击清理数据后退出 App
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <Security/Security.h>
#import <sys/sysctl.h>
#import <objc/runtime.h>
#import <substrate.h>
#include <stdlib.h>
#include <string.h>

// 进程启动时随机生成一组设备指纹
static NSUUID *fakeIDFV = nil;
static NSString *fakeMachineModel = nil;  // hw.machine 用
static NSString *fakeModelName = nil;     // model 用
static NSString *fakeDeviceName = nil;

static NSArray *iPhoneModels(void) {
    return @[
        @{@"machine": @"iPhone14,5", @"model": @"iPhone"},
        @{@"machine": @"iPhone14,6", @"model": @"iPhone"},
        @{@"machine": @"iPhone15,2", @"model": @"iPhone"},
        @{@"machine": @"iPhone15,3", @"model": @"iPhone"},
        @{@"machine": @"iPhone16,1", @"model": @"iPhone"},
        @{@"machine": @"iPhone16,2", @"model": @"iPhone"},
        @{@"machine": @"iPhone17,1", @"model": @"iPhone"},
        @{@"machine": @"iPhone17,2", @"model": @"iPhone"},
    ];
}

static NSArray *deviceNames(void) {
    return @[@"iPhone", @"Peter's iPhone", @"Admin iPhone", @"My iPhone",
             @"iPhone 15 Pro", @"工作手机", @"小李的iPhone"];
}

static void generateFakeDevice(void) {
    srand((unsigned int)time(NULL));
    fakeIDFV = [NSUUID UUID];
    NSArray *models = iPhoneModels();
    NSDictionary *m = models[rand() % models.count];
    fakeMachineModel = m[@"machine"];
    fakeModelName = m[@"model"];
    NSArray *names = deviceNames();
    fakeDeviceName = names[rand() % names.count];
}

static UIButton *flyBtn = nil;
static UIWindow *flyHUDWindow = nil;

// 悬浮按钮内嵌图片（对应原版 __cstring 开头的 base64 PNG）
static NSString *const kFlyIconBase64 =
@"iVBORw0KGgoAAAANSUhEUgAAAoAAAAKACAYAAAAMzckjAAAAAXNSR0IArs4c6QAAQABJREFUeAHsvXmwZNd933d679dvnzdvZjAzAAY7CBAgIRCACIL7JoqSLJEFiaEkU7ZjqiRFriiOs1Q2JbYrcUW2UnGpXHIqFcXJP5Fs2SnvEh1JlCzuIQkCICmAJJYZzD7z9td75/P5nXcAOKWyVTYXgHPvzH3dfe9Zfud3Tvfve3/bqaXqqDhQcaDiwCuMA3ff/Wj7urtunts780Ln3Lmz3ZRqnVqt1hmlUWfSH680m52js0ZtfVIbL3W7c4uz8WwxNdJiu9laTNPZ4ixNFyfT2cJkPO6OZ+Nmu9Vqjkfj1mw6bfZ6c800mbUGw2GzVqunNJuOU702mozG4/FkOu50u6M0m4xntTRutFv9vf3+Tq1R3643G9uD7tz29771oe07Hzi5fWGys33bvQ9srdbGFy8+8eT5x/+v398489Wzg3Pbm4PUbg0WatP+81cGg6vH+/vpiSeGrzAWV+RUHKg4cI1zoHmNj78afsWBigPfNg78Yv3Uqd9tdzqjVkq9xdEoHR9Ohuv1Wu3ItDY7Ukuc9frh2Syt9Efby3tnzy1NUlpotDvzs9m0Bzqbn03qnVm9meqtZprVZqmWwHKjSZpOp6k2TWkEauNimkw4LppqjfqqV2nO452u5VGwxFlZwnYlwCUvJ9Ytt1sNtuzKDWj3oR6jQQiTHSRAH/gw1qq1xuUpR/uWXdWryfoBSumNN4FmtLnYDIe0PvubDTe267XdtvN/s7xS2mrcd3rN2ut3kZrbulSszN/ARIv1Md7F+r12sXRqPlCSpe3B4PW6JlnflegyEiqo+JAxYGKA99aDlQA8FvL36r1igPXHAduueXhI9O5pWONWeO6VJusA7qOoFs7OZv9Pyebne6J/mB2slabrLVQy9UH9QYgrNEQXIH86rUm4EoAN0tXrm6kbrebGo1mADVwV6Kd1Gw2uFanPMgLtDeZjAMABqMBZICqBIxLNEY5wRrtcj3R/owTTWDqdjqpwzWBo2KGhu0ixKQdqfcn0uD3WG0bRutZjONLDsaRpsj0KuIs9FupsZwkvYuXwUIAhxbjQ7AtLPX3z9UJr7GmGgy+q8DXlutNu2OUrPVnAz7g0mzNhkNRp3Ls9n+6RPX339mOp6cHgz6pxeWFy/MxsOLg53+Vq7c+78+cculDar14oDFQcqDvy7cqACgP+uHKzqVxy4xjhw663v6+zNdo+0au3D4KYjmF5vHvUHt6Vm/RbUcjfuTsYrjb39JUDXUl11GegKWIZaawbwmaZOdy7t7e2lxrQBwOtgscVgC0KiYMrACs0agGlvb5fPQwBcHdDXDKA2GKBg41ADV2/Wo7zvPT0EYUC50NzlC1zjn+2O0f5N0O4JABsCQktKHodAsDc/nybQJS39fh/Q18rgkLKT2iTtYlU2E81+P4/lIYo+vYmu6kPkFsGa+5d2UzYk9OYumoPOwBM+xRwClbFqrlPNIgA0ng/iSE3GH8bEuZ5vcHyM8cD6JVvDGdSaza20mS8dePJ+zQz87Ho2+NhpNngLmfr3dnLswSv1LL/T6F9LTT2fmOKDqqDhQcaDiwL+BAxUA/DcwqLpdceBa5cDJNz46t3D1Sm93hCYvDe/G1HrX3PzcHbXa9ERjv34ClHYcLVtnggasVgN0WDhPWZYtXCaTado5wQ1vV4/vgocAuH4/a+x2d3fjutq5yVgzLhq0MLPa3ixAX70ugFJ5pql2muYBaR4f9DVbmHfBfjPMugEBAWATtXMcmoF9Vub66XWmgTISVAnTSVNlq0sb2zDb2AVOrMAVBHYAiNHmtzdjwCAxAt7w88pLLdrcC1MxEC3A6u7VzdAQthe4DzicUL8BQZCVxrTZnpsH2NXTGHfDME3Dm8kISHxAj2e+E4+RKLQ1LoSNNNhHU9lqN5q1xuqgP1jt90c3drv11znOphpQ+DWa7mN1";

static void showHUD(void) {
    if (flyHUDWindow) return;
    UIWindow *win = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    win.windowLevel = UIWindowLevelAlert + 2;
    win.backgroundColor = [UIColor clearColor];
    win.hidden = NO;
    flyHUDWindow = win;

    UIView *box = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 90)];
    box.center = CGPointMake(CGRectGetMidX(win.bounds), CGRectGetMidY(win.bounds));
    box.backgroundColor = [UIColor colorWithWhite:0.85 alpha:0.92];
    box.layer.cornerRadius = 12;
    [win addSubview:box];

    UILabel *t = [[UILabel alloc] initWithFrame:CGRectMake(0, 12, 200, 30)];
    t.text = @"Fly";
    t.textAlignment = NSTextAlignmentCenter;
    t.font = [UIFont boldSystemFontOfSize:18];
    t.textColor = [UIColor blackColor];
    [box addSubview:t];

    UILabel *m = [[UILabel alloc] initWithFrame:CGRectMake(0, 48, 200, 30)];
    m.text = @"资料清理中";
    m.textAlignment = NSTextAlignmentCenter;
    m.font = [UIFont systemFontOfSize:15];
    m.textColor = [UIColor blackColor];
    [box addSubview:m];
}

// 彻底清理 App 沙盒 + Keychain + Cookie，让下次启动等于全新安装
static void wipeAppData(void) {
    NSString *home = NSHomeDirectory();
    NSFileManager *fm = [NSFileManager defaultManager];

    // 1) 删除 Documents 下所有内容
    NSString *docs = [home stringByAppendingPathComponent:@"Documents"];
    for (NSString *f in [fm contentsOfDirectoryAtPath:docs error:nil]) {
        [fm removeItemAtPath:[docs stringByAppendingPathComponent:f] error:nil];
    }

    // 2) 删除 Library/Caches 下所有内容
    NSString *caches = [home stringByAppendingPathComponent:@"Library/Caches"];
    for (NSString *f in [fm contentsOfDirectoryAtPath:caches error:nil]) {
        [fm removeItemAtPath:[caches stringByAppendingPathComponent:f] error:nil];
    }

    // 3) 删除 Library/Preferences 下所有 .plist
    NSString *prefs = [home stringByAppendingPathComponent:@"Library/Preferences"];
    for (NSString *f in [fm contentsOfDirectoryAtPath:prefs error:nil]) {
        if ([f hasSuffix:@".plist"]) {
            [fm removeItemAtPath:[prefs stringByAppendingPathComponent:f] error:nil];
        }
    }

    // 4) 删除 Library/Application Support 下所有内容
    NSString *appSup = [home stringByAppendingPathComponent:@"Library/Application Support"];
    for (NSString *f in [fm contentsOfDirectoryAtPath:appSup error:nil]) {
        [fm removeItemAtPath:[appSup stringByAppendingPathComponent:f] error:nil];
    }

    // 5) 删除 tmp 下所有内容
    NSString *tmp = NSTemporaryDirectory();
    for (NSString *f in [fm contentsOfDirectoryAtPath:tmp error:nil]) {
        [fm removeItemAtPath:[tmp stringByAppendingPathComponent:f] error:nil];
    }

    // 6) 重置 NSUserDefaults
    NSString *bundleId = [[NSBundle mainBundle] bundleIdentifier];
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:bundleId];
    [[NSUserDefaults standardUserDefaults] synchronize];

    // 7) 清空 iCloud NSUbiquitousKeyValueStore
    NSUbiquitousKeyValueStore *icloud = [NSUbiquitousKeyValueStore defaultStore];
    for (NSString *key in [icloud dictionaryRepresentation].allKeys) {
        [icloud removeObjectForKey:key];
    }
    [icloud synchronize];

    // 8) 清空 NSHTTPCookieStorage
    NSHTTPCookieStorage *jar = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (NSHTTPCookie *c in jar.cookies) {
        [jar deleteCookie:c];
    }

    // 9) 清空 URLCache
    [[NSURLCache sharedURLCache] removeAllCachedResponses];

    // 10) 清空 Keychain（关键！设备 ID 通常存在这里，且跨重装持久）
    for (NSString *secClass in @[(__bridge id)kSecClassGenericPassword,
                                  (__bridge id)kSecClassInternetPassword,
                                  (__bridge id)kSecClassCertificate,
                                  (__bridge id)kSecClassKey,
                                  (__bridge id)kSecClassIdentity]) {
        NSDictionary *q = @{(__bridge id)kSecClass: secClass};
        SecItemDelete((__bridge CFDictionaryRef)q);
    }
}

// 按钮点击 target
@interface FlyBtnTarget : NSObject
@end
@implementation FlyBtnTarget
- (void)onTap {
    // 立刻弹 HUD
    showHUD();
    // 1.2 秒后同步清数据，然后直接退出 App
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.2 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        wipeAppData();
        // 直接杀掉进程，下次启动就是全新状态
        exit(0);
    });
}
@end
static FlyBtnTarget *flyTarget = nil;

static void addFlyButton(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (flyBtn) return;
        UIWindow *win = nil;
        for (UIWindow *w in [UIApplication sharedApplication].windows) {
            if (w.isKeyWindow) { win = w; break; }
        }
        if (!win) win = [UIApplication sharedApplication].windows.firstObject;
        if (!win) return;
        if (!flyTarget) flyTarget = [[FlyBtnTarget alloc] init];

        flyBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        CGFloat sz = 60;
        flyBtn.frame = CGRectMake(win.bounds.size.width - sz - 8,
                                  win.bounds.size.height / 2, sz, sz);
        flyBtn.layer.cornerRadius = sz / 2;
        flyBtn.clipsToBounds = YES;

        NSData *imgData = [[NSData alloc] initWithBase64EncodedString:kFlyIconBase64 options:0];
        if (imgData) {
            [flyBtn setImage:[UIImage imageWithData:imgData] forState:UIControlStateNormal];
        } else {
            [flyBtn setTitle:@"F" forState:UIControlStateNormal];
            [flyBtn setBackgroundColor:[UIColor colorWithWhite:0.3 alpha:0.8]];
        }
        [flyBtn addTarget:flyTarget action:@selector(onTap) forControlEvents:UIControlEventTouchUpInside];
        [win addSubview:flyBtn];
    });
}

static void (*orig_viewDidAppear)(id, SEL, BOOL);
static void hook_viewDidAppear(id self, SEL _cmd, BOOL animated) {
    orig_viewDidAppear(self, _cmd, animated);
    addFlyButton();
}

// --- Hook UIDevice 设备信息 ---
static NSUUID* (*orig_idfv)(id, SEL);
static NSUUID* hook_idfv(id self, SEL _cmd) {
    return fakeIDFV;
}

static NSString* (*orig_model)(id, SEL);
static NSString* hook_model(id self, SEL _cmd) {
    return fakeModelName;
}

static NSString* (*orig_devicename)(id, SEL);
static NSString* hook_devicename(id self, SEL _cmd) {
    return fakeDeviceName;
}

// hook sysctlbyname 改 hw.machine
static int (*orig_sysctlbyname)(const char*, void*, size_t*, void*, size_t);
static int hook_sysctlbyname(const char *name, void *oldp, size_t *oldlenp, void *newp, size_t newlen) {
    int r = orig_sysctlbyname(name, oldp, oldlenp, newp, newlen);
    if (r == 0 && name && strcmp(name, "hw.machine") == 0 && oldp && oldlenp) {
        const char *fake = [fakeMachineModel UTF8String];
        size_t need = strlen(fake) + 1;
        if (*oldlenp >= need) {
            strncpy(oldp, fake, *oldlenp - 1);
            ((char *)oldp)[*oldlenp - 1] = '\0';
        }
    }
    return r;
}

__attribute__((constructor))
static void fly_init(void) {
    @autoreleasepool {
        generateFakeDevice();

        MSHookMessageEx(objc_getClass("UIViewController"),
                        @selector(viewDidAppear:),
                        (IMP)hook_viewDidAppear,
                        (IMP *)&orig_viewDidAppear);

        MSHookMessageEx(objc_getClass("UIDevice"),
                        @selector(identifierForVendor),
                        (IMP)hook_idfv,
                        (IMP *)&orig_idfv);
        MSHookMessageEx(objc_getClass("UIDevice"),
                        @selector(model),
                        (IMP)hook_model,
                        (IMP *)&orig_model);
        MSHookMessageEx(objc_getClass("UIDevice"),
                        @selector(name),
                        (IMP)hook_devicename,
                        (IMP *)&orig_devicename);

        MSHookFunction((void *)sysctlbyname, (void *)hook_sysctlbyname, (void **)&orig_sysctlbyname);
    }
}

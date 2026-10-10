// Tweak.xm — Fly 一键新机插件
// 单 App 限定：仅作用于注入目标进程，Hook UIDevice/sysctl/JB检测
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <Security/Security.h>
#import <sys/sysctl.h>
#import <sys/utsname.h>
#import <objc/runtime.h>
#import <substrate.h>
#include <stdlib.h>
#include <string.h>

#pragma mark - 设备档案库（型号/系统/CPU 配套）

typedef struct {
    const char *machine;      // hw.machine  e.g. iPhone16,1
    const char *modelName;    // 展示名       e.g. iPhone 15 Pro
    const char *sysVersion;   // iOS 版本     e.g. 17.5
    const char *chipName;     // CPU 名       e.g. Apple A17 Pro
    uint64_t    cpuFreq;      // CPU 主频 Hz
} DeviceProfile;

static const DeviceProfile kProfiles[] = {
    { "iPhone15,2", "iPhone 14 Pro",     "17.5", "Apple A16 Bionic", 3460000000ULL },
    { "iPhone15,3", "iPhone 14 Pro Max",  "17.5", "Apple A16 Bionic", 3460000000ULL },
    { "iPhone16,1", "iPhone 15 Pro",     "17.5", "Apple A17 Pro",    3780000000ULL },
    { "iPhone16,2", "iPhone 15 Pro Max", "17.5", "Apple A17 Pro",    3780000000ULL },
    { "iPhone17,1", "iPhone 16 Pro",     "18.1", "Apple A18 Pro",    3940000000ULL },
    { "iPhone17,2", "iPhone 16 Pro Max","18.1", "Apple A18 Pro",    3940000000ULL },
};
static const int kProfileCount = sizeof(kProfiles)/sizeof(kProfiles[0]);

static const char *kDeviceNames[] = {
    "iPhone", "Peter's iPhone", "Admin iPhone", "My iPhone",
    "工作手机", "小李的iPhone", "iPhone 15 Pro"
};
static const int kDeviceNameCount = sizeof(kDeviceNames)/sizeof(kDeviceNames[0]);

#pragma mark - 当前伪造的设备信息

static DeviceProfile gFake;
static NSUUID *gFakeIDFV = nil;
static NSString *gFakeDevName = nil;

static void pickRandomProfile(void) {
    srand((unsigned)time(NULL) ^ (unsigned)mach_absolute_time());
    int i = rand() % kProfileCount;
    gFake = kProfiles[i];
    gFakeIDFV = [NSUUID UUID];
    gFakeDevName = [NSString stringWithUTF8String:kDeviceNames[rand() % kDeviceNameCount]];
}

#pragma mark - 悬浮按钮

static UIButton *flyBtn = nil;
static UIWindow *flyHUDWindow = nil;

static NSString *const kFlyIconBase64 =
@"iVBORw0KGgoAAAANSUhEUgAAAoAAAAKACAYAAAAMzckjAAAAAXNSR0IArs4c6QAAQABJREFUeAHsvXmwZNd933d679dvnzdvZjAzAAY7CBAgIRCACIL7JoqSLJEFiaEkU7ZjqiRFriiOs1Q2JbYrcUW2UnGpXHIqFcXJP5Fs2SnvEh1JlCzuIQkCICmAJJYZzD7z9td75/P5nXcAOKWyVTYXgHPvzH3dfe9Zfud3Tvfve3/bqaXqqDhQcaDiwCuMA3ff/Wj7urtunts780Ln3Lmz3ZRqnVqt1hmlUWfSH680m52js0ZtfVIbL3W7c4uz8WwxNdJiu9laTNPZ4ixNFyfT2cJkPO6OZ+Nmu9Vqjkfj1mw6bfZ6c800mbUGw2GzVqunNJuOU702mozG4/FkOu50u6M0m4xntTRutFv9vf3+Tq1R3643G9uD7tz29771oe07Hzi5fWGys33bvQ9srdbGFy8+8eT5x/+v398489Wzg3Pbm4PUbg0WatP+81cGg6vH+/vpiSeGrzAWV+RUHKg4cI1zoHmNj78afsWBigPfNg78Yv3Uqd9tdzqjVkq9xdEoHR9Ohuv1Wu3ItDY7Ukuc9frh2Syt9Efby3tnzy1NUlpotDvzs9m0Bzqbn03qnVm9meqtZprVZqmWwHKjSZpOp6k2TWkEauNimkw4LppqjfqqV2nO452u5VGwxFlZwnYlwCUvJ9Ytt1sNtuzKDWj3oR6jQQiTHSRAH/gw1qq1xuUpR/uWXdWryfoBSumNN4FmtLnYDIe0PvubDTe267XdtvN/s7xS2mrcd3rN2ut3kZrbulSszN/ARIv1Md7F+r12sXRqPlCSpe3B4PW6JlnflegyEiqo+JAxYGKA99aDlQA8FvL36r1igPXHAduueXhI9O5pWONWeO6VJusA7qOoFs7OZv9Pyebne6J/mB2slabrLVQy9UH9QYgrNEQXIH86rUm4EoAN0tXrm6kbrebGo1mADVwV6Kd1Gw2uFanPMgLtDeZjAMABqMBZICqBIxLNEY5wRrtcj3R/owTTWDqdjqpwzWBo2KGhu0ixKQdqfcn0uD3WG0bRutZjONLDsaRpsj0KuIs9FupsZwkvYuXwUIAhxbjQ7AtLPX3z9UJr7GmGgy+q8DXlutNu2OUrPVnAz7g0mzNhkNRp3Ls9n+6RPX339mOp6cHgz6pxeWFy/MxsOLg53+Vq7c+78+cculDar14oDFQcqDvy7cqACgP+uHKzqVxy4xjhw663v6+zNdo+0au3D4KYjmF5vHvUHt6Vm/RbUcjfuTsYrjb39JUDXUl11GegKWIZaawbwmaZOdy7t7e2lxrQBwOtgscVgC0KiYMrACs0agGlvb5fPQwBcHdDXDKA2GKBg41ADV2/Wo7zvPT0EYUC50NzlC1zjn+2O0f5N0O4JABsCQktKHodAsDc/nybQJS39fh/Q18rgkLKT2iTtYlU2E81+P4/lIYo+vYmu6kPkFsGa+5d2UzYk9OYumoPOwBM+xRwClbFqrlPNIgA0ng/iSE3GH8bEuZ5vcHyM8cD6JVvDGdSaza20mS8dePJ+zQz87Ho2+NhpNngLmfr3dnLswSv1LL/T6F9LTT2fmOKDqqDhQcaDiwL+BAxUA/DcwqLpdceBa5cDJNz46t3D1Sm93hCYvDe/G1HrX3PzcHbXa9ERjv34ClHYcLVtnggasVgN0WDhPWZYtXCaTado5wQ1vV4/vgocAuH4/a+x2d3fjutq5yVgzLhq0MLPa3ixAX70ugFJ5pql2muYBaR4f9DVbmHfBfjPMugEBAWATtXMcmoF9Vub66XWmgTISVAnTSVNlq0sb2zDb2AVOrMAVBHYAiNHmtzdjwCAxAt7w88pLLdrcC1MxEC3A6u7VzdAQthe4DzicUL8BQZCVxrTZnpsH2NXTGHfDME3Dm8kISHxAj2e+E4+RKLQ1LoSNNNhHU9lqN5q1xuqgP1jt90c3drv11znOphpQ+DWa7mN1";

static void showHUD(void) {
    if (flyHUDWindow) return;
    UIWindow *win = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    win.windowLevel = UIWindowLevelAlert + 2;
    win.backgroundColor = [UIColor clearColor];
    win.hidden = NO;
    flyHUDWindow = win;
    UIView *box = [[UIView alloc] initWithFrame:CGRectMake(0,0,200,90)];
    box.center = CGPointMake(CGRectGetMidX(win.bounds), CGRectGetMidY(win.bounds));
    box.backgroundColor = [UIColor colorWithWhite:0.85 alpha:0.92];
    box.layer.cornerRadius = 12;
    [win addSubview:box];
    UILabel *t = [[UILabel alloc] initWithFrame:CGRectMake(0,12,200,30)];
    t.text = @"GOAT新机"; t.textAlignment = NSTextAlignmentCenter;
    t.font = [UIFont boldSystemFontOfSize:18]; t.textColor = [UIColor blackColor];
    [box addSubview:t];
    UILabel *m = [[UILabel alloc] initWithFrame:CGRectMake(0,48,200,30)];
    m.text = @"施展魔法"; m.textAlignment = NSTextAlignmentCenter;
    m.font = [UIFont systemFontOfSize:15]; m.textColor = [UIColor blackColor];
    [box addSubview:m];
}

#pragma mark - 一键新机：清数据

static void wipeAppData(void) {
    NSString *home = NSHomeDirectory();
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *dirs = @[
        [home stringByAppendingPathComponent:@"Documents"],
        [home stringByAppendingPathComponent:@"Library/Caches"],
        [home stringByAppendingPathComponent:@"Library/Application Support"],
        NSTemporaryDirectory()
    ];
    for (NSString *d in dirs) {
        for (NSString *f in [fm contentsOfDirectoryAtPath:d error:nil]) {
            [fm removeItemAtPath:[d stringByAppendingPathComponent:f] error:nil];
        }
    }
    // Preferences plist
    NSString *prefs = [home stringByAppendingPathComponent:@"Library/Preferences"];
    for (NSString *f in [fm contentsOfDirectoryAtPath:prefs error:nil]) {
        if ([f hasSuffix:@".plist"]) [fm removeItemAtPath:[prefs stringByAppendingPathComponent:f] error:nil];
    }
    // NSUserDefaults
    NSString *bid = [[NSBundle mainBundle] bundleIdentifier];
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:bid];
    [[NSUserDefaults standardUserDefaults] synchronize];
    // iCloud KVS
    NSUbiquitousKeyValueStore *i = [NSUbiquitousKeyValueStore defaultStore];
    for (NSString *k in [i dictionaryRepresentation].allKeys) [i removeObjectForKey:k];
    [i synchronize];
    // Cookie / URLCache
    NSHTTPCookieStorage *jar = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (NSHTTPCookie *c in jar.cookies) [jar deleteCookie:c];
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    // Keychain 全清
    for (NSString *sc in @[(__bridge id)kSecClassGenericPassword,
                           (__bridge id)kSecClassInternetPassword,
                           (__bridge id)kSecClassCertificate,
                           (__bridge id)kSecClassKey,
                           (__bridge id)kSecClassIdentity]) {
        SecItemDelete((__bridge CFDictionaryRef)@{(__bridge id)kSecClass: sc});
    }
}

#pragma mark - 按钮 target

@interface FlyBtnTarget : NSObject <UIGestureRecognizerDelegate>
@end
@implementation FlyBtnTarget
- (void)onTap {
    showHUD();
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.2*NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        pickRandomProfile();
        wipeAppData();
        exit(0);
    });
}
- (void)onPan:(UIPanGestureRecognizer *)g {
    UIView *v = g.view;
    CGPoint p = [g translationInView:v.superview];
    CGRect f = v.frame;
    f.origin.x += p.x;
    f.origin.y += p.y;
    v.frame = f;
    [g setTranslation:CGPointZero inView:v.superview];
}
- (void)onTripleTap:(UITapGestureRecognizer *)g {
    flyBtn.hidden = !flyBtn.hidden;
}
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)g shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)o {
    return YES;
}
@end
static FlyBtnTarget *flyTarget = nil;

static void addFlyButton(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (flyBtn) return;
        UIWindow *win = nil;
        for (UIWindow *w in [UIApplication sharedApplication].windows)
            if (w.isKeyWindow) { win = w; break; }
        if (!win) win = [UIApplication sharedApplication].windows.firstObject;
        if (!win) return;
        if (!flyTarget) flyTarget = [[FlyBtnTarget alloc] init];

        CGFloat sz = 70;
        flyBtn = [[UIButton alloc] initWithFrame:CGRectMake(win.bounds.size.width - sz - 8,
                                                            win.bounds.size.height/2, sz, sz)];
        flyBtn.layer.cornerRadius = sz/2;
        flyBtn.clipsToBounds = YES;
        flyBtn.backgroundColor = [UIColor colorWithWhite:0.2 alpha:0.7];
        flyBtn.titleLabel.font = [UIFont boldSystemFontOfSize:14];
        [flyBtn setTitle:@"GOAT" forState:UIControlStateNormal];
        [flyBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];

        // 单击
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:flyTarget action:@selector(onTap)];
        [flyBtn addGestureRecognizer:tap];
        // 拖动
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:flyTarget action:@selector(onPan:)];
        pan.maximumNumberOfTouches = 1;
        [flyBtn addGestureRecognizer:pan];

        [win addSubview:flyBtn];

        // 三指点击切换显隐
        UITapGestureRecognizer *triple = [[UITapGestureRecognizer alloc] initWithTarget:flyTarget action:@selector(onTripleTap:)];
        triple.numberOfTouchesRequired = 3;
        triple.cancelsTouchesInView = NO;
        triple.delegate = flyTarget;
        [win addGestureRecognizer:triple];
    });
}

#pragma mark - UIViewController hook

static void (*orig_viewDidAppear)(id, SEL, BOOL);
static void hook_viewDidAppear(id s, SEL _c, BOOL a) {
    orig_viewDidAppear(s, _c, a);
    addFlyButton();
}

#pragma mark - UIDevice hooks

static NSUUID* (*orig_idfv)(id, SEL);
static NSUUID* hook_idfv(id s, SEL _c) { return gFakeIDFV; }

static NSString* (*orig_model)(id, SEL);
static NSString* hook_model(id s, SEL _c) {
    return [NSString stringWithUTF8String:gFake.modelName];
}

static NSString* (*orig_modelName)(id, SEL);
static NSString* hook_modelName(id s, SEL _c) { return [NSString stringWithUTF8String:gFake.modelName]; }

// hardwareMachine (私有方法，返回机器码如 iPhone15,2)
static NSString* (*orig_hwMachine)(id, SEL);
static NSString* hook_hwMachine(id s, SEL _c) {
    return [NSString stringWithUTF8String:gFake.machine];
}

static NSString* (*orig_devname)(id, SEL);
static NSString* hook_devname(id s, SEL _c) { return gFakeDevName; }

static NSString* (*orig_sysver)(id, SEL);
static NSString* hook_sysver(id s, SEL _c) { return [NSString stringWithUTF8String:gFake.sysVersion]; }

static NSString* (*orig_sysname)(id, SEL);
static NSString* hook_sysname(id s, SEL _c) { return @"iPhone OS"; }

// NSProcessInfo.operatingSystemVersionString
static NSString* (*orig_osverstr)(id, SEL);
static NSString* hook_osverstr(id s, SEL _c) {
    return [NSString stringWithFormat:@"Version %s (Build 21A355)", gFake.sysVersion];
}

// hook NSDictionary dictionaryWithContentsOfFile: 拦截 SystemVersion.plist
static NSDictionary* (*orig_dictWithFile)(id, SEL, NSString*);
static NSDictionary* hook_dictWithFile(id s, SEL _c, NSString *path) {
    NSDictionary *d = orig_dictWithFile(s, _c, path);
    if ([path isEqualToString:@"/System/Library/CoreServices/SystemVersion.plist"]) {
        NSMutableDictionary *m = [d mutableCopy] ?: [NSMutableDictionary dictionary];
        m[@"ProductVersion"] = [NSString stringWithUTF8String:gFake.sysVersion];
        return m;
    }
    return d;
}

#pragma mark - sysctl hook (hw.machine / hw.cpufrequency / hw.model)

static int (*orig_sysctlbyname)(const char*, void*, size_t*, void*, size_t);
static int hook_sysctlbyname(const char *name, void *oldp, size_t *oldlenp, void *newp, size_t newlen) {
    int r = orig_sysctlbyname(name, oldp, oldlenp, newp, newlen);
    if (r != 0 || !oldp || !oldlenp) return r;
    if (!name) return r;
    if (strcmp(name, "hw.machine") == 0 || strcmp(name, "hw.model") == 0) {
        const char *v = gFake.machine;
        size_t n = strlen(v);
        if (*oldlenp > n) { memcpy(oldp, v, n+1); *oldlenp = n+1; }
    } else if (strcmp(name, "hw.cpufrequency") == 0 || strcmp(name, "hw.cpufrequency_max") == 0) {
        if (*oldlenp >= sizeof(uint64_t)) {
            *(uint64_t *)oldp = gFake.cpuFreq;
        }
    } else if (strcmp(name, "hw.cpu64bit_capable") == 0) {
        if (*oldlenp >= sizeof(int)) *(int *)oldp = 1;
    }
    return r;
}

// uname() hook — 很多 App 用这个而不是 sysctlbyname 读机器型号
static int (*orig_uname)(struct utsname *);
static int hook_uname(struct utsname *u) {
    int r = orig_uname(u);
    if (r == 0) {
        const char *m = gFake.machine;
        size_t n = strlen(m);
        if (n < sizeof(u->machine)) {
            memcpy(u->machine, m, n+1);
        }
    }
    return r;
}

#pragma mark - MobileGestalt MGCopyAnswer hook（核心！）

#include <dlfcn.h>
typedef CFTypeRef (*MGCopyAnswer_t)(CFStringRef);
static MGCopyAnswer_t orig_MGCopyAnswer = NULL;
static CFTypeRef hook_MGCopyAnswer(CFStringRef key) {
    if (!key) return orig_MGCopyAnswer(key);
    NSString *k = (__bridge NSString *)key;
    if ([k isEqualToString:@"ProductType"]) {
        return CFBridgingRetain([NSString stringWithUTF8String:gFake.machine]);
    }
    if ([k isEqualToString:@"ProductVersion"]) {
        return CFBridgingRetain([NSString stringWithUTF8String:gFake.sysVersion]);
    }
    if ([k isEqualToString:@"MarketingName"] || [k isEqualToString:@"DeviceName"] ||
        [k isEqualToString:@"DeviceModel"] || [k isEqualToString:@"HWModelStr"] ||
        [k isEqualToString:@"Model"] || [k isEqualToString:@"ModelName"]) {
        return CFBridgingRetain([NSString stringWithUTF8String:gFake.modelName]);
    }
    if ([k isEqualToString:@"HardwareModel"]) {
        return CFBridgingRetain([NSString stringWithUTF8String:gFake.machine]);
    }
    return orig_MGCopyAnswer(key);
}

// UIDevice deviceInfoForKey: 私有方法
static id (*orig_deviceInfoForKey)(id, SEL, NSString *);
static id hook_deviceInfoForKey(id s, SEL _c, NSString *key) {
    if ([key isEqualToString:@"marketing-name"] || [key isEqualToString:@"MarketingName"]) {
        return [NSString stringWithUTF8String:gFake.modelName];
    }
    if ([key isEqualToString:@"product-type"] || [key isEqualToString:@"ProductType"] ||
        [key isEqualToString:@"HardwareModel"]) {
        return [NSString stringWithUTF8String:gFake.machine];
    }
    if ([key isEqualToString:@"product-version"] || [key isEqualToString:@"ProductVersion"]) {
        return [NSString stringWithUTF8String:gFake.sysVersion];
    }
    return orig_deviceInfoForKey(s, _c, key);
}

// sysctl() MIB 版本 (CTL_HW, HW_MACHINE = 6)
#include <sys/sysctl.h>
static int (*orig_sysctl)(int *, u_int, void *, size_t *, void *, size_t);
static int hook_sysctl_mib(int *name, u_int namelen, void *oldp, size_t *oldlenp, void *newp, size_t newlen) {
    int r = orig_sysctl(name, namelen, oldp, oldlenp, newp, newlen);
    if (r != 0 || !oldp || !oldlenp || namelen < 2) return r;
    if (name[0] == CTL_HW) {
        if (name[1] == HW_MACHINE || name[1] == HW_MODEL) {
            const char *v = gFake.machine;
            size_t n = strlen(v);
            if (*oldlenp > n) { memcpy(oldp, v, n+1); *oldlenp = n+1; }
        } else if (name[1] == HW_CPU_FREQ) {
            if (*oldlenp >= sizeof(uint64_t)) *(uint64_t *)oldp = gFake.cpuFreq;
        }
    }
    return r;
}

#pragma mark - NSProcessInfo hooks

static NSArray *jailbreakPaths(void) {
    return @[
        @"/Applications/Cydia.app",
        @"/Applications/Sileo.app",
        @"/Applications/Zebra.app",
        @"/private/var/jb",
        @"/private/var/lib/apt",
        @"/private/var/lib/cydia",
        @"/private/var/stash",
        @"/private/var/mobile/Library/SBSettings",
        @"/bin/bash",
        @"/bin/sh",
        @"/usr/sbin/sshd",
        @"/usr/bin/sshd",
        @"/usr/libexec/cydia",
        @"/etc/apt",
        @"/var/jb",
        @"/var/mobile/Library/Cydia",
        @"/var/lib/cydia",
        @"/Library/MobileSubstrate",
        @"/usr/lib/TweakInject",
        @"/usr/lib/substrate",
    ];
}

static bool isJailbreakPath(NSString *p) {
    NSArray *paths = jailbreakPaths();
    for (NSString *j in paths) {
        if ([p hasPrefix:j] || [p isEqualToString:j]) return true;
    }
    return false;
}

static BOOL (*orig_fileExists)(id, SEL, NSString *);
static BOOL hook_fileExists(id slf, SEL _c, NSString *p) {
    if (isJailbreakPath(p)) return NO;
    return orig_fileExists(slf, _c, p);
}

static BOOL (*orig_fileExistsIsDir)(id, SEL, NSString *, BOOL *);
static BOOL hook_fileExistsIsDir(id slf, SEL _c, NSString *p, BOOL *isDir) {
    if (isJailbreakPath(p)) { if (isDir) *isDir = NO; return NO; }
    return orig_fileExistsIsDir(slf, _c, p, isDir);
}

static BOOL (*orig_canOpenURL)(id, SEL, NSURL *);
static BOOL hook_canOpenURL(id slf, SEL _c, NSURL *url) {
    NSString *urlStr = url.absoluteString;
    if ([urlStr hasPrefix:@"cydia://"] || [urlStr hasPrefix:@"sileo://"] ||
        [urlStr hasPrefix:@"zbra://"] || [urlStr hasPrefix:@"filza://"]) return NO;
    return orig_canOpenURL(slf, _c, url);
}

#pragma mark - init

__attribute__((constructor))
static void fly_init(void) {
    @autoreleasepool {
        // 启动时先抽一套档案（本次进程固定，点按钮后才换新）
        pickRandomProfile();

        MSHookMessageEx(objc_getClass("UIViewController"),
                        @selector(viewDidAppear:),
                        (IMP)hook_viewDidAppear, (IMP *)&orig_viewDidAppear);

        // UIDevice
        MSHookMessageEx(objc_getClass("UIDevice"), @selector(identifierForVendor),
                        (IMP)hook_idfv, (IMP *)&orig_idfv);
        MSHookMessageEx(objc_getClass("UIDevice"), @selector(model),
                        (IMP)hook_model, (IMP *)&orig_model);
        MSHookMessageEx(objc_getClass("UIDevice"), @selector(name),
                        (IMP)hook_devname, (IMP *)&orig_devname);
        MSHookMessageEx(objc_getClass("UIDevice"), @selector(systemVersion),
                        (IMP)hook_sysver, (IMP *)&orig_sysver);
        MSHookMessageEx(objc_getClass("UIDevice"), @selector(systemName),
                        (IMP)hook_sysname, (IMP *)&orig_sysname);
        MSHookMessageEx(objc_getClass("UIDevice"), NSSelectorFromString(@"hardwareMachine"),
                        (IMP)hook_hwMachine, (IMP *)&orig_hwMachine);

        // sysctl (MIB + byname)
        MSHookFunction((void *)sysctlbyname, (void *)hook_sysctlbyname, (void **)&orig_sysctlbyname);
        MSHookFunction((void *)sysctl, (void *)hook_sysctl_mib, (void **)&orig_sysctl);

        // uname (很多 App 用这个读 machine)
        MSHookFunction((void *)uname, (void *)hook_uname, (void **)&orig_uname);

        // MobileGestalt MGCopyAnswer —— iOS 所有设备信息最终入口
        void *mgHandle = dlopen("/System/Library/PrivateFrameworks/MobileGestalt.framework/MobileGestalt", RTLD_NOW);
        if (!mgHandle) mgHandle = dlopen("/usr/lib/libMobileGestalt.dylib", RTLD_NOW);
        MGCopyAnswer_t mg = (MGCopyAnswer_t)(mgHandle ? dlsym(mgHandle, "MGCopyAnswer") : dlsym(RTLD_DEFAULT, "MGCopyAnswer"));
        if (mg) {
            MSHookFunction((void *)mg, (void *)hook_MGCopyAnswer, (void **)&orig_MGCopyAnswer);
        }

        // UIDevice deviceInfoForKey: 私有方法
        MSHookMessageEx(objc_getClass("UIDevice"), NSSelectorFromString(@"deviceInfoForKey:"),
                        (IMP)hook_deviceInfoForKey, (IMP *)&orig_deviceInfoForKey);

        // NSProcessInfo
        MSHookMessageEx(objc_getClass("NSProcessInfo"),
                        @selector(operatingSystemVersionString),
                        (IMP)hook_osverstr, (IMP *)&orig_osverstr);

        // SystemVersion.plist
        MSHookMessageEx(objc_getClass("NSDictionary"),
                        @selector(dictionaryWithContentsOfFile:),
                        (IMP)hook_dictWithFile, (IMP *)&orig_dictWithFile);

        // 越狱检测绕过
        MSHookMessageEx(objc_getClass("NSFileManager"),
                        @selector(fileExistsAtPath:),
                        (IMP)hook_fileExists, (IMP *)&orig_fileExists);
        MSHookMessageEx(objc_getClass("NSFileManager"),
                        @selector(fileExistsAtPath:isDirectory:),
                        (IMP)hook_fileExistsIsDir, (IMP *)&orig_fileExistsIsDir);
        MSHookMessageEx(objc_getClass("UIApplication"),
                        @selector(canOpenURL:),
                        (IMP)hook_canOpenURL, (IMP *)&orig_canOpenURL);
    }
}

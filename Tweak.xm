// Tweak.xm — 悬浮按钮 + 点击清理数据
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <substrate.h>

static UIButton *flyBtn = nil;
static UIWindow *flyHUDWindow = nil;

static NSString *const kFlyIconBase64 =
@"iVBORw0KGgoAAAANSUhEUgAAAoAAAAKACAYAAAAMzckjAAAAAXNSR0IArs4c6QAAQABJREFUeAHsvXmwZNd933d679dvnzdvZjAzAAY7CBAgIRCACIL7JoqSLJEFiaEkU7ZjqiRFriiOs1Q2JbYrcUW2UnGpXHIqFcXJP5Fs2SnvEh1JlCzuIQkCICmAJJYZzD7z9td75/P5nXcAOKWyVTYXgHPvzH3dfe9Zfud3Tvfve3/bqaXqqDhQcaDiwCuMA3ff/Wj7urtunts780Ln3Lmz3ZRqnVqt1hmlUWfSH680m52js0ZtfVIbL3W7c4uz8WwxNdJiu9laTNPZ4ixNFyfT2cJkPO6OZ+Nmu9Vqjkfj1mw6bfZ6c800mbUGw2GzVqunNJuOU702mozG4/FkOu50u6M0m4xntTRutFv9vf3+Tq1R3643G9uD7tz29771oe07Hzi5fWGys33bvQ9srdbGFy8+8eT5x/+v398489Wzg3Pbm4PUbg0WatP+81cGg6vH+/vpiSeGrzAWV+RUHKg4cI1zoHmNj78afsWBigPfNg78Yv3Uqd9tdzqjVkq9xdEoHR9Ohuv1Wu3ItDY7Ukuc9frh2Syt9Efby3tnzy1NUlpotDvzs9m0Bzqbn03qnVm9meqtZprVZqmWwHKjSZpOp6k2TWkEauNimkw4LppqjfqqV2nO452u5VGwxFlZwnYlwCUvJ9Ytt1sNtuzKDWj3oR6jQQiTHSRAH/gw1qq1xuUpR/uWXdWryfoBSumNN4FmtLnYDIe0PvubDTe267XdtvN/s7xS2mrcd3rN2ut3kZrbulSszN/ARIv1Md7F+r12sXRqPlCSpe3B4PW6JlnflegyEiqo+JAxYGKA99aDlQA8FvL36r1igPXHAduueXhI9O5pWONWeO6VJusA7qOoFs7OZv9Pyebne6J/mB2slabrLVQy9UH9QYgrNEQXIH86rUm4EoAN0tXrm6kbrebGo1mADVwV6Kd1Gw2uFanPMgLtDeZjAMABqMBZICqBIxLNEY5wRrtcj3R/owTTWDqdjqpwzWBo2KGhu0ixKQdqfcn0uD3WG0bRutZjONLDsaRpsj0KuIs9FupsZwkvYuXwUIAhxbjQ7AtLPX3z9UJr7GmGgy+q8DXlutNu2OUrPVnAz7g0mzNhkNRp3Ls9n+6RPX339mOp6cHgz6pxeWFy/MxsOLg53+Vq7c+78+cculDar14oDFQcqDvy7cqACgP+uHKzqVxy4xjhw663v6+zNdo+0au3D4KYjmF5vHvUHt6Vm/RbUcjfuTsYrjb39JUDXUl11GegKWIZaawbwmaZOdy7t7e2lxrQBwOtgscVgC0KiYMrACs0agGlvb5fPQwBcHdDXDKA2GKBg41ADV2/Wo7zvPT0EYUC50NzlC1zjn+2O0f5N0O4JABsCQktKHodAsDc/nybQJS39fh/Q18rgkLKT2iTtYlU2E81+P4/lIYo+vYmu6kPkFsGa+5d2UzYk9OYumoPOwBM+xRwClbFqrlPNIgA0ng/iSE3GH8bEuZ5vcHyM8cD6JVvDGdSaza20mS8dePJ+zQz87Ho2+NhpNngLmfr3dnLswSv1LL/T6F9LTT2fmOKDqqDhQcaDiwL+BAxUA/DcwqLpdceBa5cDJNz46t3D1Sm93hCYvDe/G1HrX3PzcHbXa9ERjv34ClHYcLVtnggasVgN0WDhPWZYtXCaTado5wQ1vV4/vgocAuH4/a+x2d3fjutq5yVgzLhq0MLPa3ixAX70ugFJ5pql2muYBaR4f9DVbmHfBfjPMugEBAWATtXMcmoF9Vub66XWmgTISVAnTSVNlq0sb2zDb2AVOrMAVBHYAiNHmtzdjwCAxAt7w88pLLdrcC1MxEC3A6u7VzdAQthe4DzicUL8BQZCVxrTZnpsH2NXTGHfDME3Dm8kISHxAj2e+E4+RKLQ1LoSNNNhHU9lqN5q1xuqgP1jt90c3drv11znOphpQ+DWa7mN1";

static void showHUD(NSString *title, NSString *msg) {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (flyHUDWindow) { [flyHUDWindow removeFromSuperview]; flyHUDWindow = nil; }
        UIWindow *win = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        win.windowLevel = UIWindowLevelAlert + 2;
        win.backgroundColor = [UIColor clearColor];
        win.hidden = NO;
        flyHUDWindow = win;

        UIView *box = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 220, 100)];
        box.center = CGPointMake(CGRectGetMidX(win.bounds), CGRectGetMidY(win.bounds));
        box.backgroundColor = [UIColor colorWithWhite:0.85 alpha:0.9];
        box.layer.cornerRadius = 12;
        [win addSubview:box];

        UILabel *t = [[UILabel alloc] initWithFrame:CGRectMake(0, 15, 220, 30)];
        t.text = title; t.textAlignment = NSTextAlignmentCenter;
        t.font = [UIFont boldSystemFontOfSize:18]; t.textColor = [UIColor blackColor];
        [box addSubview:t];

        UILabel *m = [[UILabel alloc] initWithFrame:CGRectMake(0, 50, 220, 30)];
        m.text = msg; m.textAlignment = NSTextAlignmentCenter;
        m.font = [UIFont systemFontOfSize:15]; m.textColor = [UIColor blackColor];
        [box addSubview:m];
    });
}

static void hideHUDAfterDelay(NSTimeInterval delay) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.3 animations:^{ flyHUDWindow.alpha = 0; }
            completion:^(BOOL f){ [flyHUDWindow removeFromSuperview]; flyHUDWindow = nil; }];
    });
}

static void cleanAppData(void) {
    NSString *home = NSHomeDirectory();
    NSArray *dirs = @[
        [home stringByAppendingPathComponent:@"Library/Caches"],
        [home stringByAppendingPathComponent:@"tmp"]
    ];
    NSFileManager *fm = [NSFileManager defaultManager];
    for (NSString *dir in dirs) {
        NSArray *files = [fm contentsOfDirectoryAtPath:dir error:nil];
        for (NSString *f in files) {
            [fm removeItemAtPath:[dir stringByAppendingPathComponent:f] error:nil];
        }
    }
    NSString *bundleId = [[NSBundle mainBundle] bundleIdentifier];
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:bundleId];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

// 静态 target 类，处理按钮点击
@interface FlyBtnTarget : NSObject
@end
@implementation FlyBtnTarget
- (void)onTap {
    showHUD(@"Fly", @"资料清理中");
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        cleanAppData();
        dispatch_async(dispatch_get_main_queue(), ^{ hideHUDAfterDelay(1.5); });
    });
}
@end
static FlyBtnTarget *flyTarget = nil;

static void addFlyButton(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (flyBtn) return;
        UIWindow *win = [UIApplication sharedApplication].keyWindow;
        if (!win) return;
        if (!flyTarget) flyTarget = [[FlyBtnTarget alloc] init];

        flyBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        CGFloat sz = 60;
        flyBtn.frame = CGRectMake(win.bounds.size.width - sz - 10,
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

__attribute__((constructor))
static void fly_init(void) {
    @autoreleasepool {
        MSHookMessageEx(objc_getClass("UIViewController"),
                        @selector(viewDidAppear:),
                        (IMP)hook_viewDidAppear,
                        (IMP *)&orig_viewDidAppear);
    }
}

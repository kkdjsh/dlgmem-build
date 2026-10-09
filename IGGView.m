// IGGView.m
#import "IGGView.h"
#import "DLGMem.h"

static IGGView *_w;

@implementation IGGView

+ (instancetype)shared {
    if (!_w) {
        _w = [[IGGView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        _w.windowLevel = UIWindowLevelAlert + 1;
        _w.backgroundColor = [UIColor clearColor];
        _w.hidden = NO;
    }
    return _w;
}

- (void)load {
    [DLGMem initAll];
    [DLGMem launchDLGMem];
}

- (void)unload {
    [DLGMemUIView removeDLGMemUIView];
}

- (void)showMe:(id)sender {
    [self load];
}

@end

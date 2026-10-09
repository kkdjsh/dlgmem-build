// DLGMemUIView.m
#import "DLGMemUIView.h"
#import "DLGMem.h"

static DLGMemUIView *_shared;

@implementation DLGMemUIView

+ (void)addDLGMemUIViewToWindow:(UIWindow *)window withDelegate:(id<DLGMemUIViewDelegate>)delegate {
    [DLGMemUIView removeDLGMemUIView];
    DLGMemUIView *v = [[DLGMemUIView alloc] initWithFrame:CGRectMake(100, 200, 60, 60)];
    v.window = window;
    v.delegate = delegate;
    [window addSubview:v];
    _shared = v;
}

+ (void)removeDLGMemUIView {
    [_shared removeFromSuperview];
    _shared = nil;
}

+ (instancetype)instance { return _shared; }

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.rcCollapsedFrame = frame;
        self.rcExpandedFrame = CGRectMake(0, 60, [UIScreen mainScreen].bounds.size.width, 400);
        self.backgroundColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:0.85];
        self.layer.cornerRadius = 8;
        self.layer.borderColor = [UIColor whiteColor].CGColor;
        self.layer.borderWidth = 1;
        self.clipsToBounds = YES;
        self.chainArray = [NSMutableArray array];

        [self initVars];
        [self initViews];
        [self initConsoleButton];
    }
    return self;
}

- (void)initVars {
    _expanded = NO;
    _shouldNotBeDragged = NO;
    _selectedValueTypeIndex = 2; // I32
    _selectedComparisonIndex = 0; // =
    _isUnsignedValueType = NO;
    _dlgmemvalueKind = DLGMemValueType_Int32;
    _chainCount = 0;
}

- (void)initConsoleButton {
    _btnConsole = [UIButton buttonWithType:UIButtonTypeSystem];
    [_btnConsole setTitle:@"M" forState:UIControlStateNormal];
    [_btnConsole setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    _btnConsole.titleLabel.font = [UIFont boldSystemFontOfSize:20];
    _btnConsole.translatesAutoresizingMaskIntoConstraints = NO;
    [_btnConsole addTarget:self action:@selector(onConsoleButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_btnConsole];

    _tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTTTapGesture:)];
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)];
    [self addGestureRecognizer:pan];
}

- (void)initViews {
    _vContent = [UIView new];
    _vContent.translatesAutoresizingMaskIntoConstraints = NO;
    _vContent.hidden = YES;
    [self addSubview:_vContent];

    // 搜索区
    _vSearch = [UIView new];
    _vSearch.translatesAutoresizingMaskIntoConstraints = NO;
    [_vContent addSubview:_vSearch];

    _tfValue = [UITextField new];
    _tfValue.placeholder = @"Search Value";
    _tfValue.backgroundColor = [UIColor whiteColor];
    _tfValue.textColor = [UIColor blackColor];
    _tfValue.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
    _tfValue.delegate = self;
    _tfValue.translatesAutoresizingMaskIntoConstraints = NO;
    [_vSearch addSubview:_tfValue];

    _btnSearch = [UIButton buttonWithType:UIButtonTypeSystem];
    [_btnSearch setTitle:@"Search" forState:UIControlStateNormal];
    [_btnSearch setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    _btnSearch.translatesAutoresizingMaskIntoConstraints = NO;
    [_btnSearch addTarget:self action:@selector(onSearch) forControlEvents:UIControlEventTouchUpInside];
    [_vSearch addSubview:_btnSearch];

    // 选项区：比较方式 + 类型
    _vOption = [UIView new];
    _vOption.translatesAutoresizingMaskIntoConstraints = NO;
    [_vContent addSubview:_vOption];

    _scComparison = [[UISegmentedControl alloc] initWithItems:@[@"=", @">", @"<", @"+", @"-", @"?", @"0"]];
    _scComparison.selectedSegmentIndex = 0;
    _scComparison.translatesAutoresizingMaskIntoConstraints = NO;
    [_vOption addSubview:_scComparison];

    _scUValueType = [[UISegmentedControl alloc] initWithItems:@[@"I8", @"I16", @"I32", @"I64", @"F32", @"F64"]];
    _scUValueType.selectedSegmentIndex = 2;
    _scUValueType.translatesAutoresizingMaskIntoConstraints = NO;
    [_scUValueType addTarget:self action:@selector(onTypeChanged:) forControlEvents:UIControlEventValueChanged];
    [_vOption addSubview:_scUValueType];

    // 结果区
    _vResult = [UIView new];
    _vResult.translatesAutoresizingMaskIntoConstraints = NO;
    [_vContent addSubview:_vResult];

    _lblResult = [UILabel new];
    _lblResult.text = @"No memory.";
    _lblResult.textColor = [UIColor whiteColor];
    _lblResult.font = [UIFont systemFontOfSize:12];
    _lblResult.translatesAutoresizingMaskIntoConstraints = NO;
    [_vResult addSubview:_lblResult];

    _tvResult = [[UITableView alloc] init];
    _tvResult.dataSource = self;
    _tvResult.delegate = self;
    _tvResult.backgroundColor = [UIColor clearColor];
    _tvResult.translatesAutoresizingMaskIntoConstraints = NO;
    [_vResult addSubview:_tvResult];

    // 更多按钮
    _vMore = [UIView new];
    _vMore.translatesAutoresizingMaskIntoConstraints = NO;
    [_vContent addSubview:_vMore];

    _btnReset = [UIButton buttonWithType:UIButtonTypeSystem];
    [_btnReset setTitle:@"Reset" forState:UIControlStateNormal];
    [_btnReset setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    _btnReset.translatesAutoresizingMaskIntoConstraints = NO;
    [_btnReset addTarget:self action:@selector(onReset) forControlEvents:UIControlEventTouchUpInside];
    [_vMore addSubview:_btnReset];

    _btnMemory = [UIButton buttonWithType:UIButtonTypeSystem];
    [_btnMemory setTitle:@"Memory" forState:UIControlStateNormal];
    [_btnMemory setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    _btnMemory.translatesAutoresizingMaskIntoConstraints = NO;
    [_btnMemory addTarget:self action:@selector(onMemory) forControlEvents:UIControlEventTouchUpInside];
    [_vMore addSubview:_btnMemory];

    _btnRefresh = [UIButton buttonWithType:UIButtonTypeSystem];
    [_btnRefresh setTitle:@"Refresh" forState:UIControlStateNormal];
    [_btnRefresh setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    _btnRefresh.translatesAutoresizingMaskIntoConstraints = NO;
    [_btnRefresh addTarget:self action:@selector(onRefresh) forControlEvents:UIControlEventTouchUpInside];
    [_vMore addSubview:_btnRefresh];

    // 内存查看器
    _vMemoryContent = [UIView new];
    _vMemoryContent.hidden = YES;
    _vMemoryContent.translatesAutoresizingMaskIntoConstraints = NO;
    [_vContent addSubview:_vMemoryContent];

    _tfMemory = [UITextField new];
    _tfMemory.placeholder = @"Address (hex)";
    _tfMemory.backgroundColor = [UIColor whiteColor];
    _tfMemory.translatesAutoresizingMaskIntoConstraints = NO;
    [_vMemoryContent addSubview:_tfMemory];

    _tfMemorySize = [UITextField new];
    _tfMemorySize.placeholder = @"Size";
    _tfMemorySize.backgroundColor = [UIColor whiteColor];
    _tfMemorySize.translatesAutoresizingMaskIntoConstraints = NO;
    [_vMemoryContent addSubview:_tfMemorySize];

    _btnSearchMemory = [UIButton buttonWithType:UIButtonTypeSystem];
    [_btnSearchMemory setTitle:@"Go" forState:UIControlStateNormal];
    [_btnSearchMemory setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    _btnSearchMemory.translatesAutoresizingMaskIntoConstraints = NO;
    [_btnSearchMemory addTarget:self action:@selector(onSearchMemory) forControlEvents:UIControlEventTouchUpInside];
    [_vMemoryContent addSubview:_btnSearchMemory];

    _tvMemory = [UITextView new];
    _tvMemory.backgroundColor = [UIColor blackColor];
    _tvMemory.textColor = [UIColor greenColor];
    _tvMemory.font = [UIFont fontWithName:@"Courier" size:10];
    _tvMemory.editable = NO;
    _tvMemory.translatesAutoresizingMaskIntoConstraints = NO;
    [_vMemoryContent addSubview:_tvMemory];

    _btnBackFromMemory = [UIButton buttonWithType:UIButtonTypeSystem];
    [_btnBackFromMemory setTitle:@"Back" forState:UIControlStateNormal];
    [_btnBackFromMemory setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    _btnBackFromMemory.translatesAutoresizingMaskIntoConstraints = NO;
    [_btnBackFromMemory addTarget:self action:@selector(onBackFromMemory) forControlEvents:UIControlEventTouchUpInside];
    [_vMemoryContent addSubview:_btnBackFromMemory];
}

#pragma mark - Actions

- (void)onConsoleButtonTapped:(UIButton *)b {
    if (_expanded) [self doCollapse]; else [self doExpand];
}

- (void)handleTTTapGesture:(UITapGestureRecognizer *)g {
    if (_expanded) [self doCollapse]; else [self doExpand];
}

- (void)handleGesture:(UIPanGestureRecognizer *)g {
    CGPoint t = [g translationInView:self.superview];
    if (g.state == UIGestureRecognizerStateBegan) {
        // remember start
    } else if (g.state == UIGestureRecognizerStateChanged) {
        if (!_expanded) {
            self.center = CGPointMake(self.center.x + t.x, self.center.y + t.y);
            [g setTranslation:CGPointZero inView:self.superview];
        }
    }
}

- (void)doExpand {
    _expanded = YES;
    self.vContent.hidden = NO;
    [UIView animateWithDuration:0.25 animations:^{
        self.frame = self.rcExpandedFrame;
    }];
}

- (void)doCollapse {
    _expanded = NO;
    self.vContent.hidden = YES;
    [UIView animateWithDuration:0.25 animations:^{
        self.frame = self.rcCollapsedFrame;
    }];
}

- (void)onTypeChanged:(UISegmentedControl *)sc {
    self.selectedValueTypeIndex = sc.selectedSegmentIndex;
    self.dlgmemvalueKind = sc.selectedSegmentIndex;
}

- (void)onSearch {
    [DLGMem searchMem:self.tfValue.text
                 type:(NSInteger)self.dlgmemvalueKind
           comparison:self.scComparison.selectedSegmentIndex];
    self.lblResult.text = [NSString stringWithFormat:@"Results: %ld", (long)self.chainCount];
    [self.tvResult reloadData];
}

- (void)onReset { [DLGMem reset]; self.chainArray = [NSMutableArray array]; [self.tvResult reloadData]; }
- (void)onRefresh { [DLGMem refresh]; [self.tvResult reloadData]; }
- (void)onMemory { self.vMemoryContent.hidden = !self.vMemoryContent.hidden; }

- (void)onSearchMemory {
    [DLGMem readMemoryAt:self.tfMemory.text size:self.tfMemorySize.text];
}
- (void)onBackFromMemory { self.vMemoryContent.hidden = YES; }

- (void)showMessage:(NSString *)msg duration:(NSTimeInterval)duration {
    NSLog(@"[DLGMem] %@", msg);
}

#pragma mark - UITableView

- (NSInteger)tableView:(UITableView *)t numberOfRowsInSection:(NSInteger)s { return self.chainArray.count; }
- (UITableViewCell *)tableView:(UITableView *)t cellForRowAtIndexPath:(NSIndexPath *)ip {
    static NSString *cid = @"cell";
    DLGMemUIViewCell *c = [t dequeueReusableCellWithIdentifier:cid];
    if (!c) c = [[DLGMemUIViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cid];
    NSDictionary *row = self.chainArray[ip.row];
    c.address = row[@"address"];
    c.value = row[@"value"];
    c.delegate = self;
    return c;
}
- (CGFloat)tableView:(UITableView *)t heightForRowAtIndexPath:(NSIndexPath *)ip { return 44; }

- (void)DLGMemUIViewCellModify:(DLGMemUIViewCell *)cell value:(NSString *)value {
    [DLGMem modifyMem:cell.address value:value type:(NSInteger)self.dlgmemvalueKind];
    [self showMessage:@"Modified successfully." duration:1];
}
- (void)DLGMemUIViewCellViewMemory:(DLGMemUIViewCell *)cell {
    self.tfMemory.text = cell.address;
    self.vMemoryContent.hidden = NO;
}

#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)tf { [tf resignFirstResponder]; return YES; }

@end

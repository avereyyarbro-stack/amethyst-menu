#import "AmethystMenuViewController.h"
#import "AmethystToggleRow.h"
#import "AmethystSettings.h"
#import "AmethystFloatingButton.h"

@interface AmethystWaveView : UIView
@end

@implementation AmethystWaveView

- (void)drawRect:(CGRect)rect {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(ctx, [UIColor colorWithWhite:1.0 alpha:0.04].CGColor);
    CGContextSetLineWidth(ctx, 1.0);

    for (CGFloat y = 0; y < rect.size.height; y += 28) {
        UIBezierPath *path = [UIBezierPath bezierPath];
        [path moveToPoint:CGPointMake(0, y)];
        for (CGFloat x = 0; x <= rect.size.width; x += 8) {
            CGFloat wave = sin((x + y) * 0.02) * 3.0;
            [path addLineToPoint:CGPointMake(x, y + wave)];
        }
        CGContextAddPath(ctx, path.CGPath);
        CGContextStrokePath(ctx);
    }
}

@end

@interface AmethystMenuViewController ()
@property (nonatomic, strong) UIView *panel;
@property (nonatomic, strong) UIView *dimView;
@property (nonatomic, strong) UILabel *terminalLabel;
@property (nonatomic, strong) NSTimer *clockTimer;
@property (nonatomic, strong) UILabel *timestampLabel;
@property (nonatomic, weak) UIWindow *hostWindow;
@property (nonatomic, assign) BOOL menuVisible;
@end

@implementation AmethystMenuViewController

+ (instancetype)sharedController {
    static AmethystMenuViewController *controller = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        controller = [[AmethystMenuViewController alloc] init];
    });
    return controller;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.clearColor;
    self.view.hidden = YES;
    self.menuVisible = NO;

    _dimView = [[UIView alloc] init];
    _dimView.translatesAutoresizingMaskIntoConstraints = NO;
    _dimView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.65];
    _dimView.userInteractionEnabled = YES;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideMenu)];
    [_dimView addGestureRecognizer:tap];
    [self.view addSubview:_dimView];

    AmethystWaveView *waves = [[AmethystWaveView alloc] initWithFrame:CGRectZero];
    waves.translatesAutoresizingMaskIntoConstraints = NO;
    waves.backgroundColor = UIColor.blackColor;
    waves.userInteractionEnabled = NO;
    [_dimView addSubview:waves];

    _panel = [[UIView alloc] init];
    _panel.translatesAutoresizingMaskIntoConstraints = NO;
    _panel.backgroundColor = [UIColor colorWithWhite:0 alpha:0.92];
    _panel.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.2].CGColor;
    _panel.layer.borderWidth = 1.0;
    [self.view addSubview:_panel];

    UILabel *statusBadge = [[UILabel alloc] init];
    statusBadge.translatesAutoresizingMaskIntoConstraints = NO;
    statusBadge.font = [UIFont fontWithName:@"Menlo" size:11] ?: [UIFont monospacedSystemFontOfSize:11 weight:UIFontWeightRegular];
    statusBadge.textColor = [UIColor colorWithRed:0.0 green:1.0 blue:0.4 alpha:1.0];
    statusBadge.text = @"● operational";
    [_panel addSubview:statusBadge];

    _timestampLabel = [[UILabel alloc] init];
    _timestampLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _timestampLabel.font = [UIFont fontWithName:@"Menlo" size:11] ?: [UIFont monospacedSystemFontOfSize:11 weight:UIFontWeightRegular];
    _timestampLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.35];
    [_panel addSubview:_timestampLabel];
    [self refreshTimestamp];

    UILabel *title = [[UILabel alloc] init];
    title.translatesAutoresizingMaskIntoConstraints = NO;
    title.text = @"Amethyst";
    title.font = [UIFont systemFontOfSize:36 weight:UIFontWeightBold];
    title.textColor = UIColor.whiteColor;
    [_panel addSubview:title];

    UILabel *subtitle = [[UILabel alloc] init];
    subtitle.translatesAutoresizingMaskIntoConstraints = NO;
    subtitle.text = @"mod menu";
    subtitle.font = [UIFont italicSystemFontOfSize:28];
    subtitle.textColor = UIColor.whiteColor;
    [_panel addSubview:subtitle];

    UILabel *sectionLabel = [[UILabel alloc] init];
    sectionLabel.translatesAutoresizingMaskIntoConstraints = NO;
    sectionLabel.font = [UIFont fontWithName:@"Menlo" size:11] ?: [UIFont monospacedSystemFontOfSize:11 weight:UIFontWeightRegular];
    sectionLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.45];
    sectionLabel.text = [[AmethystSettings shared] categoryTitle:AmethystModCategoryInformational];
    [_panel addSubview:sectionLabel];

    UIStackView *infoStack = [[UIStackView alloc] init];
    infoStack.translatesAutoresizingMaskIntoConstraints = NO;
    infoStack.axis = UILayoutConstraintAxisVertical;
    infoStack.spacing = 10;
    [_panel addSubview:infoStack];

    UILabel *layoutsLabel = [[UILabel alloc] init];
    layoutsLabel.translatesAutoresizingMaskIntoConstraints = NO;
    layoutsLabel.font = [UIFont fontWithName:@"Menlo" size:11] ?: [UIFont monospacedSystemFontOfSize:11 weight:UIFontWeightRegular];
    layoutsLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.45];
    layoutsLabel.text = [[AmethystSettings shared] categoryTitle:AmethystModCategoryLayouts];
    [_panel addSubview:layoutsLabel];

    UIStackView *layoutStack = [[UIStackView alloc] init];
    layoutStack.translatesAutoresizingMaskIntoConstraints = NO;
    layoutStack.axis = UILayoutConstraintAxisVertical;
    layoutStack.spacing = 10;
    [_panel addSubview:layoutStack];

    __weak typeof(self) weakSelf = self;
    void (^toggleHandler)(AmethystMod, BOOL) = ^(AmethystMod mod, BOOL enabled) {
        NSLog(@"[Amethyst] mod %ld -> %@", (long)mod, enabled ? @"on" : @"off");
        if ([[AmethystSettings shared] isLayoutMod:mod]) {
            [weakSelf updateTerminalForLayouts];
        }
    };

    for (NSNumber *modNum in [[AmethystSettings shared] modsForCategory:AmethystModCategoryInformational]) {
        AmethystToggleRow *row = [[AmethystToggleRow alloc] initWithMod:(AmethystMod)modNum.integerValue];
        row.onToggle = toggleHandler;
        [infoStack addArrangedSubview:row];
    }

    for (NSNumber *modNum in [[AmethystSettings shared] modsForCategory:AmethystModCategoryLayouts]) {
        AmethystToggleRow *row = [[AmethystToggleRow alloc] initWithMod:(AmethystMod)modNum.integerValue];
        row.onToggle = toggleHandler;
        [layoutStack addArrangedSubview:row];
    }

    UIButton *logBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    logBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [logBtn setTitle:@"log layouts now" forState:UIControlStateNormal];
    [logBtn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    logBtn.titleLabel.font = [UIFont fontWithName:@"Menlo" size:13] ?: [UIFont monospacedSystemFontOfSize:13 weight:UIFontWeightRegular];
    logBtn.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.5].CGColor;
    logBtn.layer.borderWidth = 1.0;
    logBtn.contentEdgeInsets = UIEdgeInsetsMake(8, 16, 8, 16);
    [logBtn addTarget:self action:@selector(logLayoutsTapped) forControlEvents:UIControlEventTouchUpInside];
    [_panel addSubview:logBtn];

    _terminalLabel = [[UILabel alloc] init];
    _terminalLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _terminalLabel.font = [UIFont fontWithName:@"Menlo" size:12] ?: [UIFont monospacedSystemFontOfSize:12 weight:UIFontWeightRegular];
    _terminalLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.7];
    _terminalLabel.text = @"$ surface check: nothing of interest reported.█";
    [_panel addSubview:_terminalLabel];

    UIStackView *footer = [[UIStackView alloc] init];
    footer.translatesAutoresizingMaskIntoConstraints = NO;
    footer.axis = UILayoutConstraintAxisHorizontal;
    footer.distribution = UIStackViewDistributionFillEqually;
    footer.spacing = 8;
    [_panel addSubview:footer];

    [footer addArrangedSubview:[self footerColumnWithLabel:@"type" value:@"info overlay"]];
    [footer addArrangedSubview:[self footerColumnWithLabel:@"platform" value:@"war robots"]];
    [footer addArrangedSubview:[self footerColumnWithLabel:@"version" value:@"1.2.0"]];
    [footer addArrangedSubview:[self footerColumnWithLabel:@"status" value:@"layouts log"]];

    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    closeBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [closeBtn setTitle:@"close" forState:UIControlStateNormal];
    [closeBtn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    closeBtn.titleLabel.font = [UIFont fontWithName:@"Menlo" size:13] ?: [UIFont monospacedSystemFontOfSize:13 weight:UIFontWeightRegular];
    closeBtn.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.5].CGColor;
    closeBtn.layer.borderWidth = 1.0;
    closeBtn.contentEdgeInsets = UIEdgeInsetsMake(8, 16, 8, 16);
    [closeBtn addTarget:self action:@selector(hideMenu) forControlEvents:UIControlEventTouchUpInside];
    [_panel addSubview:closeBtn];

    [NSLayoutConstraint activateConstraints:@[
        [_dimView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [_dimView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [_dimView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [_dimView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

        [waves.topAnchor constraintEqualToAnchor:_dimView.topAnchor],
        [waves.leadingAnchor constraintEqualToAnchor:_dimView.leadingAnchor],
        [waves.trailingAnchor constraintEqualToAnchor:_dimView.trailingAnchor],
        [waves.bottomAnchor constraintEqualToAnchor:_dimView.bottomAnchor],

        [_panel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [_panel.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        [_panel.widthAnchor constraintEqualToAnchor:self.view.widthAnchor multiplier:0.88],
        [_panel.heightAnchor constraintLessThanOrEqualToAnchor:self.view.heightAnchor multiplier:0.85],

        [statusBadge.topAnchor constraintEqualToAnchor:_panel.topAnchor constant:20],
        [statusBadge.leadingAnchor constraintEqualToAnchor:_panel.leadingAnchor constant:20],

        [_timestampLabel.centerYAnchor constraintEqualToAnchor:statusBadge.centerYAnchor],
        [_timestampLabel.leadingAnchor constraintEqualToAnchor:statusBadge.trailingAnchor constant:12],

        [title.topAnchor constraintEqualToAnchor:statusBadge.bottomAnchor constant:24],
        [title.leadingAnchor constraintEqualToAnchor:_panel.leadingAnchor constant:20],

        [subtitle.firstBaselineAnchor constraintEqualToAnchor:title.firstBaselineAnchor],
        [subtitle.leadingAnchor constraintEqualToAnchor:title.trailingAnchor constant:10],

        [sectionLabel.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:20],
        [sectionLabel.leadingAnchor constraintEqualToAnchor:_panel.leadingAnchor constant:20],

        [infoStack.topAnchor constraintEqualToAnchor:sectionLabel.bottomAnchor constant:12],
        [infoStack.leadingAnchor constraintEqualToAnchor:_panel.leadingAnchor constant:20],
        [infoStack.trailingAnchor constraintEqualToAnchor:_panel.trailingAnchor constant:-20],

        [layoutsLabel.topAnchor constraintEqualToAnchor:infoStack.bottomAnchor constant:20],
        [layoutsLabel.leadingAnchor constraintEqualToAnchor:_panel.leadingAnchor constant:20],

        [layoutStack.topAnchor constraintEqualToAnchor:layoutsLabel.bottomAnchor constant:12],
        [layoutStack.leadingAnchor constraintEqualToAnchor:_panel.leadingAnchor constant:20],
        [layoutStack.trailingAnchor constraintEqualToAnchor:_panel.trailingAnchor constant:-20],

        [logBtn.topAnchor constraintEqualToAnchor:layoutStack.bottomAnchor constant:12],
        [logBtn.centerXAnchor constraintEqualToAnchor:_panel.centerXAnchor],

        [_terminalLabel.topAnchor constraintEqualToAnchor:logBtn.bottomAnchor constant:20],
        [_terminalLabel.leadingAnchor constraintEqualToAnchor:_panel.leadingAnchor constant:20],
        [_terminalLabel.trailingAnchor constraintEqualToAnchor:_panel.trailingAnchor constant:-20],

        [footer.topAnchor constraintEqualToAnchor:_terminalLabel.bottomAnchor constant:20],
        [footer.leadingAnchor constraintEqualToAnchor:_panel.leadingAnchor constant:20],
        [footer.trailingAnchor constraintEqualToAnchor:_panel.trailingAnchor constant:-20],

        [closeBtn.topAnchor constraintEqualToAnchor:footer.bottomAnchor constant:20],
        [closeBtn.centerXAnchor constraintEqualToAnchor:_panel.centerXAnchor],
        [closeBtn.bottomAnchor constraintEqualToAnchor:_panel.bottomAnchor constant:-20],
    ]];

    _clockTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
        [self refreshTimestamp];
    }];
}

- (UIView *)footerColumnWithLabel:(NSString *)label value:(NSString *)value {
    UIStackView *col = [[UIStackView alloc] init];
    col.axis = UILayoutConstraintAxisVertical;
    col.spacing = 4;

    UILabel *lbl = [[UILabel alloc] init];
    lbl.font = [UIFont fontWithName:@"Menlo" size:10] ?: [UIFont monospacedSystemFontOfSize:10 weight:UIFontWeightRegular];
    lbl.textColor = [UIColor colorWithWhite:1.0 alpha:0.35];
    lbl.text = label;

    UILabel *val = [[UILabel alloc] init];
    val.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
    val.textColor = UIColor.whiteColor;
    val.text = value;
    val.numberOfLines = 2;

    [col addArrangedSubview:lbl];
    [col addArrangedSubview:val];
    return col;
}

- (void)logLayoutsTapped {
    NSLog(@"[Amethyst] layout log requested");
    [self updateTerminalForLayouts];
}

- (void)updateTerminalForLayouts {
    self.terminalLabel.text = @"$ layouts -> logged to console█";
}

- (void)refreshTimestamp {
    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    fmt.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    self.timestampLabel.text = [fmt stringFromDate:[NSDate date]];
}

- (void)attachToWindow:(UIWindow *)window {
    if (!window || self.hostWindow == window) return;
    self.hostWindow = window;
    self.view.frame = window.bounds;
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [window addSubview:self.view];
    [window bringSubviewToFront:self.view];
}

- (void)showMenu {
    if (!self.hostWindow) return;
    self.view.hidden = NO;
    self.menuVisible = YES;
    [self.hostWindow bringSubviewToFront:self.view];
    AmethystFloatingButton *button = [AmethystFloatingButton sharedButton];
    [self.hostWindow bringSubviewToFront:button];
}

- (void)hideMenu {
    self.menuVisible = NO;
    self.view.hidden = YES;
}

- (void)toggleVisibility {
    if (self.menuVisible) {
        [self hideMenu];
    } else {
        [self showMenu];
    }
}

- (void)dealloc {
    [self.clockTimer invalidate];
}

@end

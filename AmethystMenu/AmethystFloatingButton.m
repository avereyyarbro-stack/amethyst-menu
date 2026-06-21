#import "AmethystFloatingButton.h"
#import "AmethystMenuViewController.h"

@interface AmethystFloatingButton ()
@property (nonatomic, weak) UIWindow *hostWindow;
@end

@implementation AmethystFloatingButton

+ (instancetype)sharedButton {
    static AmethystFloatingButton *button = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        button = [[AmethystFloatingButton alloc] initWithFrame:CGRectZero];
    });
    return button;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setTitle:@"menu" forState:UIControlStateNormal];
        [self setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        self.titleLabel.font = [UIFont fontWithName:@"Menlo" size:13]
            ?: [UIFont monospacedSystemFontOfSize:13 weight:UIFontWeightRegular];
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.55];
        self.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.5].CGColor;
        self.layer.borderWidth = 1.0;
        self.contentEdgeInsets = UIEdgeInsetsMake(6, 12, 6, 12);
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.accessibilityLabel = @"Amethyst menu";
        [self addTarget:self action:@selector(openMenu) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}

- (void)attachToWindow:(UIWindow *)window {
    if (!window || self.hostWindow == window) return;

    [self removeFromSuperview];
    self.hostWindow = window;
    [window addSubview:self];
    [window bringSubviewToFront:self];

    UILayoutGuide *safe = window.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [self.topAnchor constraintEqualToAnchor:safe.topAnchor constant:8],
        [self.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-12],
    ]];
}

- (void)openMenu {
    [[AmethystMenuViewController sharedController] showMenu];
}

@end

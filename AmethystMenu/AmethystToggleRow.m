#import "AmethystToggleRow.h"

@interface AmethystToggleRow ()
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *descLabel;
@property (nonatomic, strong) UIView *indicator;
@property (nonatomic, assign) BOOL isOn;
@end

@implementation AmethystToggleRow

- (instancetype)initWithMod:(AmethystMod)mod {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _mod = mod;
        _isOn = [[AmethystSettings shared] isEnabled:mod];

        self.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.35].CGColor;
        self.layer.borderWidth = 1.0;
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.25];

        _titleLabel = [[UILabel alloc] init];
        _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _titleLabel.font = [UIFont fontWithName:@"Menlo" size:13] ?: [UIFont monospacedSystemFontOfSize:13 weight:UIFontWeightRegular];
        _titleLabel.textColor = UIColor.whiteColor;
        _titleLabel.text = [[AmethystSettings shared] titleForMod:mod];
        [self addSubview:_titleLabel];

        _descLabel = [[UILabel alloc] init];
        _descLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _descLabel.font = [UIFont fontWithName:@"Menlo" size:10] ?: [UIFont monospacedSystemFontOfSize:10 weight:UIFontWeightRegular];
        _descLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.45];
        _descLabel.text = [[AmethystSettings shared] descriptionForMod:mod];
        [self addSubview:_descLabel];

        _indicator = [[UIView alloc] init];
        _indicator.translatesAutoresizingMaskIntoConstraints = NO;
        _indicator.layer.borderColor = UIColor.whiteColor.CGColor;
        _indicator.layer.borderWidth = 1.0;
        [self addSubview:_indicator];

        [NSLayoutConstraint activateConstraints:@[
            [_titleLabel.topAnchor constraintEqualToAnchor:self.topAnchor constant:10],
            [_titleLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:12],
            [_titleLabel.trailingAnchor constraintEqualToAnchor:_indicator.leadingAnchor constant:-8],

            [_descLabel.topAnchor constraintEqualToAnchor:_titleLabel.bottomAnchor constant:4],
            [_descLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:12],
            [_descLabel.trailingAnchor constraintEqualToAnchor:_indicator.leadingAnchor constant:-8],
            [_descLabel.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-10],

            [_indicator.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-12],
            [_indicator.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
            [_indicator.widthAnchor constraintEqualToConstant:18],
            [_indicator.heightAnchor constraintEqualToConstant:18],
        ]];

        [self updateIndicator];
        [self addTarget:self action:@selector(tapped) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}

- (void)updateIndicator {
    if (self.isOn) {
        self.indicator.backgroundColor = [UIColor colorWithRed:0.0 green:1.0 blue:0.4 alpha:1.0];
    } else {
        self.indicator.backgroundColor = UIColor.clearColor;
    }
}

- (void)tapped {
    self.isOn = !self.isOn;
    [[AmethystSettings shared] setEnabled:self.isOn forMod:self.mod];
    [self updateIndicator];
    if (self.onToggle) {
        self.onToggle(self.mod, self.isOn);
    }
}

@end

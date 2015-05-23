/*
* __            __
*|__). _  _ | _|__) _  _  _ _|
*| \ ||_)|_)|(-|__)(_)(_|| (_|
*     |  |
* Created by Satori (Razzile)
* Source code is under the MIT License
* File: RipplePrefs.mm
* Description: Preference Bundle Backend
*/

#import <Preferences/Preferences.h>
#import <Preferences/PSSpecifier.h>
#import <Preferences/PSSwitchTableCell.h>
#define rippleBoardPrefPath @"/User/Library/Preferences/com.satori.rippleboard.plist"

UIImageView *rippleView; // woo nasty coding

@interface BlueSwitchTableCell : PSSwitchTableCell
@end

@interface BlueSliderTableCell : PSSliderTableCell
@end

@interface RippleCell : PSTableCell
@end

@implementation BlueSwitchTableCell

-(id)initWithStyle:(int)style reuseIdentifier:(NSString *)identifier specifier:(PSSpecifier *)spec {

    self = [super initWithStyle:style reuseIdentifier:identifier specifier:spec];
    if (self) {
        [((UISwitch *)[self control]) setOnTintColor:[UIColor colorWithRed:51.0f/255.0f green:51.0f/255.0f blue:153.0f/255.0f alpha:1.0f]];
    }

    return self;
}

@end

@implementation RippleCell

- (CGFloat)preferredHeightForWidth:(CGFloat)width {
    return 100;
}

@end

@implementation BlueSliderTableCell
-(id)initWithStyle:(int)style reuseIdentifier:(NSString *)identifier specifier:(PSSpecifier *)spec {
    self = [super initWithStyle:style reuseIdentifier:identifier specifier:spec];
    if (self) {
        [((UISlider *)[self control]) setMinimumTrackTintColor:[UIColor colorWithRed:51.0f/255.0f green:51.0f/255.0f blue:153.0f/255.0f alpha:1.0f]];
    }
    return self;
}
@end

@interface RipplePrefsListController: PSListController <UITableViewDelegate> {
}
@end

@implementation RipplePrefsListController
- (id)specifiers {
	if(_specifiers == nil) {
		_specifiers = [self loadSpecifiersFromPlistName:@"RipplePrefs" target:self];
	}
	return _specifiers;
}

-(id)readPreferenceValue:(PSSpecifier*)specifier {
	NSDictionary *exampleTweakSettings = [NSDictionary dictionaryWithContentsOfFile:rippleBoardPrefPath];
	if (!exampleTweakSettings[specifier.properties[@"key"]]) {
		return specifier.properties[@"default"];
	}
	return exampleTweakSettings[specifier.properties[@"key"]];
}

-(void)setPreferenceValue:(id)value specifier:(PSSpecifier*)specifier {
	NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
	[defaults addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:rippleBoardPrefPath]];
	[defaults setObject:value forKey:specifier.properties[@"key"]];
	[defaults writeToFile:rippleBoardPrefPath atomically:YES];
	CFStringRef toPost = (CFStringRef)specifier.properties[@"PostNotification"];
	if(toPost) CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), toPost, NULL, NULL, YES);
}

#pragma mark Custom

- (void)respring {
    system("killall backboardd");
}

- (void)twitter {
	if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tweetbot:"]]) {
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[@"tweetbot:///user_profile/" stringByAppendingString:@"Razzilient"]]];

	 } else if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitterrific:"]]) {
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[@"twitterrific://user?screen_name=" stringByAppendingString:@"Razzilient"]]];

	} else if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitter:"]]) {
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[@"twitter://user?screen_name=" stringByAppendingString:@"Razzilient"]]];
	} else {
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[@"https://mobile.twitter.com/" stringByAppendingString:@"Razzilient"]]];
	}
}

- (void)website {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://razzland.com"]];
}

- (void)github {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://github.com/Razzile/RippleBoard"]];
}

- (void)paypal {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=comfycallum%40gmail%2ecom&lc=US&item_name=RippleBoard&item_number=RIPPLEBOARDDONATION&no_note=0&currency_code=GBP&bn=PP%2dDonationsBF%3abtn_donate_LG%2egif%3aNonHostedGuest"]];
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
	if(section == [tableView numberOfSections]-3) {
		static UIView *footerView;
		if (footerView != nil)	return footerView;

		footerView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self->_table.frame.size.width, 200.0f)];
		footerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		rippleView = [[UIImageView alloc] initWithFrame:CGRectMake(40, 40, 120, 120)];
		[rippleView setImage:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/RipplePrefs.bundle/rippleboard.png"]];
		rippleView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
		rippleView.center = CGPointMake(CGRectGetMidX(footerView.frame), CGRectGetMidY(footerView.frame));
		[footerView addSubview:rippleView];
		return footerView;
	}
	return [super tableView:tableView viewForFooterInSection:section];
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
	if(section == [tableView numberOfSections]-3) {
    	return 200;
	}
	return [super tableView:tableView heightForFooterInSection:section];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	static dispatch_once_t onceToken = 0;
	dispatch_once(&onceToken, ^{
		[NSTimer scheduledTimerWithTimeInterval:3.0 target:self selector:@selector(beginRipples) userInfo:nil repeats:YES];
	});
}

- (void)beginRipples {
	NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:rippleBoardPrefPath];
	float range = [[dict objectForKey:@"range"] floatValue];
	float speed = [[dict objectForKey:@"runningSpeed"] floatValue];

	CGRect pathFrame = CGRectMake(-60, -60, rippleView.frame.size.width, rippleView.frame.size.height);
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:pathFrame cornerRadius:rippleView.frame.size.height/2];
	CGPoint shapePosition = CGPointMake(60, 60);

	CAShapeLayer *circleShape = [CAShapeLayer layer];
    circleShape.path = path.CGPath;
    circleShape.position = shapePosition;
    circleShape.strokeColor = [UIColor blueColor].CGColor;
    circleShape.opacity = 0;
    circleShape.fillColor = [UIColor colorWithRed:51.0f/255.0f green:51.0f/255.0f blue:153.0f/255.0f alpha:1.0f].CGColor;
    circleShape.lineWidth = 3;

    [rippleView.layer addSublayer:circleShape];

    CABasicAnimation *scaleAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    scaleAnimation.fromValue = [NSValue valueWithCATransform3D:CATransform3DIdentity];
    scaleAnimation.toValue = [NSValue valueWithCATransform3D:CATransform3DMakeScale(range, range, 1)];

    CABasicAnimation *alphaAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    alphaAnimation.fromValue = @1;
    alphaAnimation.toValue = @0;

    CAAnimationGroup *animation = [CAAnimationGroup animation];
	[animation setValue:circleShape forKey:@"animationLayer"];
	animation.delegate = self;
    animation.animations = @[scaleAnimation, alphaAnimation];
    animation.duration = speed;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    [circleShape addAnimation:animation forKey:@"groupAnimation"];

}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
	CALayer *layer = [anim valueForKey:@"animationLayer"];
	if (layer) {
		NSLog(@"removed %@ (%@) from superview", layer, [layer name]);
		[layer removeFromSuperlayer];
	}
 }

@end
// vim:ft=objc

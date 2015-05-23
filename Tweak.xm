/*
* __            __
*|__). _  _ | _|__) _  _  _ _|
*| \ ||_)|_)|(-|__)(_)(_|| (_|
*     |  |
* Created by Satori (Razzile)
* Source code is under the MIT License
* File: Tweak.xm
* Description: Contains the core code of rippleboard
*/

#import "Interfaces.h"
#import "mask.h"

#define rippleBoardPrefPath @"/User/Library/Preferences/com.satori.rippleboard.plist"

NSMutableArray *runningApps;

/* load settings */
static NSDictionary *settingsDict() {
    return [NSDictionary dictionaryWithContentsOfFile:rippleBoardPrefPath];
}

/* Returns a rounded version of the supplied image */
static UIImage *roundedImage(UIImage *orig)
{
    NSDictionary *dict = settingsDict();
    if (orig == nil || ![dict[@"roundicons"] boolValue]) return orig;
    UIImageView *imageView = [[UIImageView alloc] initWithImage:orig];
    CALayer *layer = [imageView layer];

    layer.masksToBounds = YES;
    CALayer *mask = [CALayer layer];
    mask.contents = (id)[[UIImage imageWithData:[NSData dataWithBytes:maskData length:sizeof(maskData)]] CGImage];
    mask.frame = imageView.frame;
    imageView.layer.mask = mask;
    imageView.layer.masksToBounds = YES;
    UIGraphicsBeginImageContextWithOptions(imageView.bounds.size, NO, 0.0);
    [layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *roundedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return (roundedImage != nil) ? roundedImage : orig;
}

/* calculates the average color in a supplied image */
static UIColor *dominantColor(UIImage *image)
{
    struct pixel {
        unsigned char r, g, b, a;
    };
    NSUInteger red = 0;
    NSUInteger green = 0;
    NSUInteger blue = 0;


    // Allocate a buffer big enough to hold all the pixels

    struct pixel* pixels = (struct pixel*) calloc(1, image.size.width * image.size.height * sizeof(struct pixel));
    if (pixels != nil)
    {

        CGContextRef context = CGBitmapContextCreate(
                                                 (void*) pixels,
                                                 image.size.width,
                                                 image.size.height,
                                                 8,
                                                 image.size.width * 4,
                                                 CGImageGetColorSpace(image.CGImage),
                                                 kCGImageAlphaPremultipliedLast
                                                 );

        if (context != NULL)
        {
            // Draw the image in the bitmap

            CGContextDrawImage(context, CGRectMake(0.0f, 0.0f, image.size.width, image.size.height), image.CGImage);

            // Now that we have the image drawn in our own buffer, we can loop over the pixels to
            // process it. This simple case simply counts all pixels that have a pure red component.

            // There are probably more efficient and interesting ways to do this. But the important
            // part is that the pixels buffer can be read directly.

            NSUInteger numberOfPixels = image.size.width * image.size.height;
            for (int i=0; i<numberOfPixels; i++) {
                red += pixels[i].r;
                green += pixels[i].g;
                blue += pixels[i].b;
            }


            red /= (numberOfPixels/2);
            green /= (numberOfPixels/2);
            blue/= (numberOfPixels/2);


            CGContextRelease(context);
        }

        free(pixels);
    }
    return [UIColor colorWithRed:red/255.0f green:green/255.0f blue:blue/255.0f alpha:1.0f];
}


/* hooked methods to allow us to round the icons */
// %hook SBIcon
//
// +(id)memoryMappedIconImageForIconImage:(id)iconImage {
//     return roundedImage(%orig);
// }
//
// %end

%group Hooks
%hook SBClockApplicationIconImageView

-(id)contentsImage {
    return roundedImage(%orig);
}

%end
/* we also want to round the overlay view that appears when an icon is pressed */
%hook SBIconImageView

-(id)_iconBasicOverlayImage {
    return roundedImage(%orig);
}

+ (CGFloat)cornerRadius {
    NSDictionary *dict = settingsDict();
    return ([[dict objectForKey:@"roundicons"] boolValue]) ? %orig*2.25 : %orig;
}

%end

%hook SBIcon

- (id)generateIconImage:(int)arg1 {
    return roundedImage(%orig);
}

- (id)getIconImage:(int)arg1 {
    return roundedImage(%orig);
}

%end

// %hook SBFolderIcon
//
// - (id)generateIconImage:(int)arg1 {
//     return roundedImage(%orig);
// }
//
// - (id)getIconImage:(int)arg1 {
//     return roundedImage(%orig);
// }
//
// - (id)getGenericIconImage:(int)arg1 {
//     return roundedImage(%orig);
// }
//
// %end

/* slight workaround to disable the image temporarily reverting to normal on launch */
%hook SBIconImageCrossfadeView

-(void)_updateCornerMask {

}

%end

// %hook SBFolderIconImageView
//
// + (float)cornerRadius {
//     NSDictionary *dict = settingsDict();
//     return ([[dict objectForKey:@"roundicons"] boolValue]) ? 22 : %orig;
// }
//
// %end
/* create a ripple effect on launch - uses a modified version of RNBRippleEffect found on github */
%hook SBIconController

-(void)_launchIcon:(id)icon {
    NSDictionary *dict = settingsDict();
    float range = [[dict objectForKey:@"range"] floatValue];
    float speed = [[dict objectForKey:@"runningSpeed"] floatValue];
    bool launch = [[dict objectForKey:@"launchripple"] boolValue];
    if (!launch) return %orig;

    UIView *iconView = [[%c(SBIconViewMap) homescreenMap] mappedIconViewForIcon:icon];
    if (iconView == nil) return %orig;
    SBIconImageView *iconImageView = MSHookIvar<SBIconImageView *>(iconView, "_iconImageView");
    CGRect pathFrame = CGRectMake(-CGRectGetMidX(iconImageView.bounds), -CGRectGetMidY(iconImageView.bounds), iconImageView.bounds.size.width, iconImageView.bounds.size.height);
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:pathFrame cornerRadius:iconImageView.bounds.size.height/2];

    UIGraphicsBeginImageContextWithOptions(iconImageView.bounds.size, iconImageView.opaque, [[UIScreen mainScreen] scale]);
    [iconImageView drawViewHierarchyInRect:iconImageView.bounds afterScreenUpdates:NO];

    UIImage *iconImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    UIColor *dominant = dominantColor(iconImage);
    CGPoint shapePosition = iconImageView.center;

    CAShapeLayer *circleShape = [CAShapeLayer layer];
    circleShape.path = path.CGPath;
    circleShape.position = shapePosition;
    circleShape.fillColor = dominant.CGColor;
    circleShape.opacity = 0;
    circleShape.strokeColor = dominant.CGColor;
    circleShape.lineWidth = 3;

    [iconImageView.layer addSublayer:circleShape];

    CABasicAnimation *scaleAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    scaleAnimation.fromValue = [NSValue valueWithCATransform3D:CATransform3DIdentity];
    scaleAnimation.toValue = [NSValue valueWithCATransform3D:CATransform3DMakeScale(range, range, 1)];

    CABasicAnimation *alphaAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    alphaAnimation.fromValue = @1;
    alphaAnimation.toValue = @0;

    CAAnimationGroup *animation = [CAAnimationGroup animation];
    animation.animations = @[scaleAnimation, alphaAnimation];
    animation.duration = speed;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    [circleShape addAnimation:animation forKey:nil];

    [UIView animateWithDuration:0.1 animations:^{
        iconImageView.alpha = 0.4;
        iconImageView.layer.borderColor = dominant.CGColor;
    }completion:^(BOOL finished) {
        [UIView animateWithDuration:0.3 animations:^{
            iconImageView.alpha = 1;
            iconImageView.layer.borderColor = dominant.CGColor;
        }completion:^(BOOL finished){
            %orig;
            [circleShape removeFromSuperlayer];
        }];

    }];
}

- (id)init {
    [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(beginRipples) userInfo:nil repeats:YES];
    return %orig;
}

%new
- (void)beginRipples {
    NSDictionary *dict = settingsDict();
    if (![dict[@"runningripple"] boolValue]) return;
    if (runningApps == nil) {
        runningApps = [[NSMutableArray alloc] init];
    }
    for (NSString *bundleID in runningApps) {
        int64_t delayInSeconds = arc4random_uniform(4);
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            SBIcon *icon = [self.model applicationIconForBundleIdentifier:bundleID];
            UIView *iconView = [[%c(SBIconViewMap) homescreenMap] mappedIconViewForIcon:icon];
            if (iconView == nil) return;
            SBIconImageView *iconImageView = MSHookIvar<SBIconImageView *>(iconView, "_iconImageView");
            if (iconImageView == nil) return;
            CGRect pathFrame = CGRectMake(-CGRectGetMidX(iconImageView.bounds), -CGRectGetMidY(iconImageView.bounds), iconImageView.bounds.size.width, iconImageView.bounds.size.height);
            UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:pathFrame cornerRadius:iconImageView.bounds.size.height/2];

            UIGraphicsBeginImageContextWithOptions(iconImageView.bounds.size, iconImageView.opaque, [[UIScreen mainScreen] scale]);
            [iconImageView drawViewHierarchyInRect:iconImageView.bounds afterScreenUpdates:NO];

            UIImage *iconImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();

            UIColor *dominant = dominantColor(iconImage);
            CGPoint shapePosition = iconImageView.center;

            CAShapeLayer *circleShape = [CAShapeLayer layer];
            circleShape.path = path.CGPath;
            circleShape.position = shapePosition;
            circleShape.fillColor = [UIColor clearColor].CGColor;
            circleShape.opacity = 0;
            circleShape.strokeColor = dominant.CGColor;
            circleShape.lineWidth = 2;

            [iconImageView.layer addSublayer:circleShape];

            CABasicAnimation *scaleAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
            scaleAnimation.fromValue = [NSValue valueWithCATransform3D:CATransform3DIdentity];
            scaleAnimation.toValue = [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.5, 1.5, 1)];

            CABasicAnimation *alphaAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
            alphaAnimation.fromValue = @1;
            alphaAnimation.toValue = @0;

            CAAnimationGroup *animation = [CAAnimationGroup animation];
            animation.animations = @[scaleAnimation, alphaAnimation];
            animation.duration = 1.0f;
            animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
            [circleShape addAnimation:animation forKey:nil];
            int64_t delayInSeconds = 1;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [circleShape removeFromSuperlayer];
            });
        });
    }
}
%end

%hook SBIconContentView

- (void)layoutSubviews {
    static UITapGestureRecognizer *rippleRecognizer;
    if (!rippleRecognizer) rippleRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapFrom:)];
    [self addGestureRecognizer:rippleRecognizer];
    [rippleRecognizer setCancelsTouchesInView:NO];
    rippleRecognizer.delegate = self;
    %orig;
}

%new
- (void)handleTapFrom:(UITapGestureRecognizer *)recognizer {
    NSDictionary *dict = settingsDict();
    if (![dict[@"touchripple"] boolValue]) return;
    CGPoint point = [recognizer locationInView:self];
    CGRect pathFrame = CGRectMake(-10, -10, 20, 20);
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:pathFrame cornerRadius:20/2];

    UIColor *tapColor = [UIColor whiteColor];
    CGPoint shapePosition = CGPointMake(point.x, point.y);

    CAShapeLayer *circleShape = [CAShapeLayer layer];
    circleShape.path = path.CGPath;
    circleShape.position = shapePosition;
    circleShape.fillColor = tapColor.CGColor;
    circleShape.opacity = 0;
    circleShape.strokeColor = tapColor.CGColor;
    circleShape.lineWidth = 2;

    [self.layer addSublayer:circleShape];

    CABasicAnimation *scaleAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    scaleAnimation.fromValue = [NSValue valueWithCATransform3D:CATransform3DIdentity];
    scaleAnimation.toValue = [NSValue valueWithCATransform3D:CATransform3DMakeScale(2.5, 2.5, 1)];

    CABasicAnimation *alphaAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    alphaAnimation.fromValue = @1;
    alphaAnimation.toValue = @0;

    CAAnimationGroup *animation = [CAAnimationGroup animation];
    animation.animations = @[scaleAnimation, alphaAnimation];
    animation.duration = 1.5f;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    [circleShape addAnimation:animation forKey:nil];
    float delayInSeconds = 1.5f;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [circleShape removeFromSuperlayer];
    });
}

%new
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    return YES;
}

%end


%hook SBWorkspace

-(void)applicationProcessDidExit:(FBProcess *)applicationProcess withContext:(id)context {
    NSLog(@"AABB: removed %@", applicationProcess.applicationInfo.bundleIdentifier);

    if (runningApps == nil) {
        runningApps = [[NSMutableArray alloc] init];
        return %orig;
    }
    if ([runningApps containsObject:applicationProcess.applicationInfo.bundleIdentifier]) {
        [runningApps removeObject:applicationProcess.applicationInfo.bundleIdentifier];
    }
    %orig;
}

-(void)applicationProcessDidLaunch:(FBProcess *)applicationProcess {
    if (runningApps == nil) {
        runningApps = [[NSMutableArray alloc] init];
    }
    [runningApps addObject:applicationProcess.applicationInfo.bundleIdentifier];
    NSLog(@"AABB: %@", applicationProcess.applicationInfo.bundleIdentifier);
    %orig;
}

%end
%end // Hooks

%ctor {
    NSDictionary *dict = settingsDict();
    if ([dict[@"enabled"] boolValue]) {
        %init(Hooks);
    }
}

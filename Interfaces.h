
/*
* __            __
*|__). _  _ | _|__) _  _  _ _|
*| \ ||_)|_)|(-|__)(_)(_|| (_|
*     |  |
* Created by Satori (Razzile)
* Source code is under the MIT License
* File: Interfaces.h
* Description: Contains makeshift class definitions for used classes
*/

@interface SBIcon
-(void)reloadIconImage;
-(id)generateIconImage:(int)arg1;
-(id)applicationBundleID;
@end

@interface SBIconImageView : UIView
@property (nonatomic,retain,readonly) SBIcon *icon;
- (id)contentsImage;
@end

@interface SBIconViewMap
+ (id)homescreenMap;
- (id)mappedIconViewForIcon:(id)icon;
@end

@interface SBFolderIconView
- (id)_folderIconImageView;
@end

@interface SBFolderIconImageView : UIView
@end

@interface SBIconContentView : UIView <UIGestureRecognizerDelegate>
@end

@interface SBIconModel
- (id)applicationIconForBundleIdentifier:(id)bundleIdentifier;
@end

@interface SBIconController
-(void)reloadIconImagePurgingImageCache:(BOOL)cache;
- (SBIconModel *)model;
@end

@interface SBUIController <UIGestureRecognizerDelegate>
- (UIView *)contentView;
@end

@interface FBBundleInfo
@property(copy) NSString * bundleIdentifier;
@end

@interface FBProcess
@property(retain,readonly) FBBundleInfo * applicationInfo;
@end

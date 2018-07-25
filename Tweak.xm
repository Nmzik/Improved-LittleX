#import <dlfcn.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <CoreGraphics/CoreGraphics.h>
#include <sys/sysctl.h>
#include <sys/utsname.h>

#import "headers/SpringBoard/SpringBoard.h"

@interface UIScreen (Priv)
- (UIEdgeInsets)_sceneSafeAreaInsets;
@end

static CGFloat screenCornerRadius = 19;

static NSDictionary *globalSettings;

@interface SBHomeGrabberSettings : NSObject
- (void)setEnabled:(BOOL)enabled;
- (void)setAutoHideOverride:(NSInteger)override;
- (NSInteger)autoHideOverride;
@end 

@interface SBHomeScreenSettings : NSObject
- (SBHomeGrabberSettings *)grabberSettings;
@end

@interface SBRootSettings : NSObject
- (SBHomeScreenSettings *)homeScreenSettings;
@end

@interface SBPrototypeController : NSObject
+ (instancetype)sharedInstance;
- (SBRootSettings *)rootSettings;
@end

%hook SBFloatingDockController
+ (BOOL)isFloatingDockSupported {
	return YES;
}

- (BOOL)_systemGestureManagerAllowsFloatingDockGesture {
	return NO;
}
%end

%hook SBIconListView
+ (NSUInteger)maxVisibleIconRowsInterfaceOrientation:(UIInterfaceOrientation)orientation {
	NSUInteger orig = %orig;
	if (UIInterfaceOrientationIsLandscape(orientation)) {
		return orig;
	} else {
		return orig-1;
	}
}

%end

%hook SBFloatingDockIconListView
+ (NSUInteger)maxIcons {
	return 10;
}
+ (NSUInteger)iconColumnsForInterfaceOrientation:(NSInteger)arg1 {
	return 10;
}
+ (NSUInteger)maxVisibleIconRowsInterfaceOrientation:(NSInteger)arg1 {
	return 1;
}
%end

%hook SBDockIconListView
+ (NSUInteger)maxIcons {
	return 6;
}
%end

%hook SBFloatingDockSuggestionsModel

- (BOOL)_shouldProcessAppSuggestion:(id)arg1 {
	return NO;
}

- (void)_setRecentsEnabled:(BOOL)enabled {
	%orig(NO);
}

- (void)setRecentsEnabled:(BOOL)enabled {
	%orig(NO);
}

- (BOOL)recentsEnabled {
	return NO;
}
%end


%hook SBAppSwitcherSettings
- (NSInteger)effectiveKillAffordanceStyle {
	return 2;
}

- (NSInteger)killAffordanceStyle {
	return 2;
}

- (void)setKillAffordanceStyle:(NSInteger)style {
	%orig(2);
}
%end

@interface SBHomeGrabberView : NSObject
@end

%hook SBHomeGrabberView
-(NSInteger)_calculatePresence {
		return 2; //Hide HomeBar
}
%end

%hook BSPlatform
- (NSInteger)homeButtonType {
	return 2; //iPhone X Gestures
}
%end

static BOOL fakeRadius = NO;

%hook SBGridSwitcherPersonality
- (BOOL)shouldShowControlCenter {
	return NO; //UNKNOWN????
}
%end

%hook SBDeckSwitcherPersonality
%property (nonatomic, retain) SBGridSwitcherPersonality *otherPersonality;
- (CGFloat)_cardCornerRadiusInAppSwitcher {
	fakeRadius = YES;
	CGFloat orig = %orig;
	fakeRadius = NO;
	return orig;
}
%end

%hook UIScreen
- (BOOL)_wantsWideContentMargins {
	return NO;
}

- (CGFloat)_displayCornerRadius {
	if (fakeRadius) return screenCornerRadius;
	else return %orig;
}
%end

%hook UITraitCollection
+ (id)traitCollectionWithDisplayCornerRadius:(CGFloat)arg1 {
	if (fakeRadius) return %orig(screenCornerRadius);
	else return %orig;
}
- (CGFloat)displayCornerRadius {
	if (fakeRadius) return screenCornerRadius;
	else return %orig;
}
- (CGFloat)_displayCornerRadius {
	if (fakeRadius) return screenCornerRadius;
	else return %orig;
}
%end

@interface _UIStatusBar
+ (void)setDefaultVisualProviderClass:(Class)classOb;
+ (void)setForceSplit:(BOOL)arg1;
@end

@interface _UIStatusBarVisualProvider_iOS : NSObject
+ (CGSize)intrinsicContentSizeForOrientation:(NSInteger)orientation;
@end

%hook _UIStatusBar
+ (BOOL)forceSplit {
	return TRUE;
}

+ (void)setForceSplit:(BOOL)arg1 {
	%orig(TRUE);
}

+ (void)setDefaultVisualProviderClass:(Class)classOb {
	%orig(NSClassFromString(@"_UIStatusBarVisualProvider_Split"));
}
+(void)initialize {
	%orig;
		[NSClassFromString(@"_UIStatusBar") setForceSplit:TRUE];
		[NSClassFromString(@"_UIStatusBar") setDefaultVisualProviderClass:NSClassFromString(@"_UIStatusBarVisualProvider_Split")];
}

-(void)_prepareVisualProviderIfNeeded {
	%orig;
		[NSClassFromString(@"_UIStatusBar") setForceSplit:TRUE];
		[NSClassFromString(@"_UIStatusBar") setDefaultVisualProviderClass:NSClassFromString(@"_UIStatusBarVisualProvider_Split")];
}

+ (CGFloat)heightForOrientation:(NSInteger)orientation {
	return [NSClassFromString(@"_UIStatusBarVisualProvider_Split") intrinsicContentSizeForOrientation:orientation].height;
}
%end

%hook _UIStatusBarVisualProvider_iOS
+ (Class)class {
	return NSClassFromString(@"_UIStatusBarVisualProvider_Split");
}
%end

%hook UIStatusBar_Base
+ (BOOL)forceModern {
	return YES;
}
+ (Class)_statusBarImplementationClass {
	return NSClassFromString(@"UIStatusBar_Modern");
}
%end

%hook UIViewController
- (BOOL)prefersHomeIndicatorAutoHidden {
	return YES; //HACK???
}
%end

%ctor {
	NSArray *args = [[NSClassFromString(@"NSProcessInfo") processInfo] arguments];
	NSUInteger count = args.count;
	if (count != 0) {
		NSString *executablePath = args[0];
		if (executablePath) {
			NSString *processName = [executablePath lastPathComponent];
			BOOL isSpringBoard = [processName isEqualToString:@"SpringBoard"];
			BOOL isApplication = [executablePath rangeOfString:@"/Application"].location != NSNotFound;
			if (isSpringBoard || isApplication) {
				%init;
				[NSClassFromString(@"_UIStatusBar") setDefaultVisualProviderClass:NSClassFromString(@"_UIStatusBarVisualProvider_Split")];
			}
		}
	}
}

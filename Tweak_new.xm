#import <dlfcn.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <CoreGraphics/CoreGraphics.h>
#include <sys/sysctl.h>
#include <sys/utsname.h>

#import "headers/SpringBoard/SpringBoard.h"

%hook SBFloatingDockController
+ (BOOL)isFloatingDockSupported {
	return YES;
}

- (BOOL)_systemGestureManagerAllowsFloatingDockGesture {
	return NO;
}
%end

%hook SBDeckSwitcherPersonality
%property (nonatomic, retain) SBGridSwitcherPersonality *otherPersonality;
- (CGFloat)_cardCornerRadiusInAppSwitcher {
	if (isActualIPhoneX || !wantsRoundedSwitcherCards) return %orig;
	fakeRadius = YES;
	CGFloat orig = %orig;
	fakeRadius = NO;
	return orig;
}
%end

%hook UIScreen

- (CGFloat)_displayCornerRadius {
	return screenCornerRadius;
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
	return orig;
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


/*%hook SBAppSwitcherSettings
- (NSInteger)effectiveKillAffordanceStyle {
	if (switcherKillStyle == 0) return %orig;
	return 2;
}

- (NSInteger)killAffordanceStyle {
	if (switcherKillStyle == 0) return %orig;
	return 2;
}

- (void)setKillAffordanceStyle:(NSInteger)style {
	if (switcherKillStyle == 0) {
		%orig;
		return;
	}
	%orig(2);
}
%end*/

@interface _UIStatusBar
+ (void)setDefaultVisualProviderClass:(Class)classOb;
+ (void)setForceSplit:(BOOL)arg1;
@end

@interface _UIStatusBarVisualProvider_iOS : NSObject
+ (CGSize)intrinsicContentSizeForOrientation:(NSInteger)orientation;
@end

%hook _UIStatusBar
+ (BOOL)forceSplit {
	return true;
}

+ (void)setForceSplit:(BOOL)arg1 { //?????
	%orig(true);
}

+ (void)setDefaultVisualProviderClass:(Class)classOb {
	%orig(NSClassFromString(@"_UIStatusBarVisualProvider_Split"));
}
+(void)initialize {
	%orig;
		[NSClassFromString(@"_UIStatusBar") setForceSplit:YES];
		[NSClassFromString(@"_UIStatusBar") setDefaultVisualProviderClass:NSClassFromString(@"_UIStatusBarVisualProvider_Split")];
}

-(void)_prepareVisualProviderIfNeeded {
	%orig;
		[NSClassFromString(@"_UIStatusBar") setForceSplit:YES];
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

%ctor {
    %init;
}

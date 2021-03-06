// QuickPredictKey
// Triple-click the shift key to toggle the Predictive Keyboard.
// MIT License
// Create by @ichitaso

// It doesn't work completely in iOS 13. It needs improvement.

#import <AudioToolbox/AudioToolbox.h>
#import <firmware.h>

#define PREF_PATH @"/var/mobile/Library/Preferences/com.ichitaso.quickpredict.plist"
#define Notify_Preferences "com.ichitaso.quickpredict.prefschanged"

#define NOTIFY_ALEART "com.ichitaso.quickpredict.showalert"
#define NOTIFY_NAME @"com.ichitaso.quickpredict.springboard"

// https://iphonedevwiki.net/index.php/UIKeyboardPreferencesController
// Reference https://github.com/PoomSmart/Predictive-Keyboard-Flipswitch
#define KeyboardPrediction "KeyboardPrediction"
#define KeyboardShowPredictionBar "KeyboardShowPredictionBar"

@interface UIKeyboardLayoutStar
- (id)keyHitTest:(CGPoint)arg1;
- (NSString *)unhashedName;// UIKBTree
@end

@interface UIKeyboardImpl
+ (id)sharedInstance;
- (void)showKeyboard;
- (void)hideKeyboard;
- (void)updateLayout;
@end

@interface TIPreferencesController : NSObject
+ (id)sharedPreferencesController;
- (void)setValue:(id)arg1 forKey:(int)arg2;
- (id)valueForKey:(int)arg1;
- (void)setValue:(id)arg1 forPreferenceKey:(id)arg2;
- (void)synchronizePreferences;
@end

// toggle
static BOOL togglePredict;
// Settings
static BOOL enabled;
static BOOL haptic;
static BOOL showAlert;
static BOOL forceEnabled;

%hook UIKeyboardLayoutStar
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    %orig;
    
    if (!enabled) return;
    
    for (UITouch *touch in [touches allObjects]) {
        id kbTree = [self keyHitTest:[touch locationInView:touch.view]];
        if ([kbTree respondsToSelector:@selector(unhashedName)]) {
            NSString *unhashedName = [kbTree unhashedName];
            //NSLog(@"QuickPredictKey:%@", [kbTree unhashedName]);
            if ([unhashedName isEqualToString:@"Shift-Key"] && touch.tapCount == 3) {
                // Haptic feedback
                if (haptic) {AudioServicesPlaySystemSound(1519);}
                // Hide Keyboard
                [[%c(UIKeyboardImpl) sharedInstance] hideKeyboard];
                // Toggle status
                togglePredict = !togglePredict;
                // Send Notification
                CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR(NOTIFY_ALEART), NULL, NULL, true);
            }
        }
    }
}
%end

%hook UIKeyboardImpl
%group iOS_13
- (BOOL)accessibilityUsesExtendedKeyboardPredictionsEnabled {
    if (!enabled) return %orig;
    
    if (togglePredict && forceEnabled) {
        return YES;
    }
    return %orig;
}
%end

%group iOS_12
- (BOOL)predictionFromPreference { // iPhone X Serise
    if (!enabled) return %orig;
    
    if (togglePredict) {
        return YES;
    }
    return %orig;
}

- (BOOL)canOfferPredictionsForTraits {
    if (!enabled) return %orig;
    
    TIPreferencesController *tc = [%c(TIPreferencesController) sharedPreferencesController];
    if (togglePredict || ![[tc valueForKey:35] boolValue]) {
        return YES;
    }
    return NO;
}
 
- (BOOL)predictionForTraitsWithForceEnable:(BOOL)arg1 {
    if (!enabled) return %orig;
    
    TIPreferencesController *tc = [%c(TIPreferencesController) sharedPreferencesController];
    if (togglePredict || ![[tc valueForKey:35] boolValue]) {
        return YES;
    }
    return NO;
}
%end
%end

%group SpringBoard
%hook SpringBoard
- (void)applicationDidFinishLaunching:(id)application {
    %orig;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showAlertView:) name:NOTIFY_NAME object:nil];
}
%new
- (void)showAlertView:(NSNotification *)notification {
    if (!showAlert) return;
    
    UIAlertController *alert =
    [UIAlertController alertControllerWithTitle:@"Predictive Keyboard"
                                        message:@"You Toggled Predictive Text"
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *cancelAction =
    [UIAlertAction actionWithTitle:@"OK"
                             style:UIAlertActionStyleCancel
                           handler:^(UIAlertAction *action) {}];
    
    [alert addAction:cancelAction];
    
    UIViewController *vc = [UIApplication sharedApplication].keyWindow.rootViewController;
    
    [vc presentViewController:alert animated:YES completion:nil];
}
%end
%end

static void showAlertNotification(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    
    TIPreferencesController *tc = [%c(TIPreferencesController) sharedPreferencesController];
    if ([[tc valueForKey:35] boolValue]) { // KeyboardPrediction
        [tc setValue:@(NO) forPreferenceKey:@(KeyboardPrediction)];
        [tc setValue:@(NO) forPreferenceKey:@(KeyboardShowPredictionBar)];
    } else {
        [tc setValue:@(YES) forPreferenceKey:@(KeyboardPrediction)];
        [tc setValue:@(YES) forPreferenceKey:@(KeyboardShowPredictionBar)];
    }
    [tc synchronizePreferences];
    
    double delayInSeconds = 0.5;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
        // Keyboard relayout
        [[%c(UIKeyboardImpl) sharedInstance] updateLayout];
        // Send Alert Notification
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFY_NAME object:nil];
        // Show Keyboard
        [[%c(UIKeyboardImpl) sharedInstance] showKeyboard];
    });
}
// Settings Sections
//================================================================================
static void settingsChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:PREF_PATH];
    
    enabled = (BOOL)[dict[@"enabled"] ?: @YES boolValue];
    haptic = (BOOL)[dict[@"haptic"] ?: @YES boolValue];
    showAlert = (BOOL)[dict[@"showAlert"] ?: @NO boolValue];
    forceEnabled = (BOOL)[dict[@"forceEnabled"] ?: @NO boolValue];
}

%ctor {
    @autoreleasepool {
        BOOL shouldLoad = NO;
        NSArray *args = [[NSClassFromString(@"NSProcessInfo") processInfo] arguments];
        NSUInteger count = args.count;
        if (count != 0) {
            NSString *executablePath = args[0];
            if (executablePath) {
                NSString *processName = [executablePath lastPathComponent];
                BOOL isSpringBoard = [processName isEqualToString:@"SpringBoard"];
                BOOL isApplication = [executablePath rangeOfString:@"/Application/"].location != NSNotFound || [executablePath rangeOfString:@"/Applications/"].location != NSNotFound;
                BOOL isFileProvider = [[processName lowercaseString] rangeOfString:@"fileprovider"].location != NSNotFound;
                BOOL skip = [processName isEqualToString:@"AdSheet"]
                         || [processName isEqualToString:@"CoreAuthUI"]
                         || [processName isEqualToString:@"InCallService"]
                         || [processName isEqualToString:@"MessagesNotificationViewService"]
                         || [executablePath rangeOfString:@".appex/"].location != NSNotFound;
                if (!isFileProvider && (isSpringBoard || isApplication) && !skip) {
                    shouldLoad = YES;
                }
            }
        }

        if (!shouldLoad) return;
        
        %init;
        
        NSString *identifier = [[NSBundle mainBundle] bundleIdentifier];
        
        if ([identifier isEqualToString:@"com.apple.springboard"]) {
            %init(SpringBoard);
        }
        
        if (kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_13_0) {
            %init(iOS_12);
        } else {
            %init(iOS_13);
        }
        
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                        NULL,
                                        showAlertNotification,
                                        CFSTR(NOTIFY_ALEART),
                                        NULL,
                                        CFNotificationSuspensionBehaviorDeliverImmediately);
        
        // Settings Notifications
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                        NULL,
                                        settingsChanged,
                                        CFSTR(Notify_Preferences),
                                        NULL,
                                        CFNotificationSuspensionBehaviorCoalesce);
        
        settingsChanged(NULL, NULL, NULL, NULL, NULL);
    }
}

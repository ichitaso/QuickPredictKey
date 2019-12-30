// QuickPredictKey
// Triple-click the shift key to toggle the Predictive Keyboard.
// MIT License
// Create by @ichitaso

// It doesn't work completely in iOS 13. It needs improvement.

#import <firmware.h>
#import <AppSupport/CPDistributedMessagingCenter.h>
#import <rocketbootstrap/rocketbootstrap.h>

#define PREF_PATH @"/var/mobile/Library/Preferences/com.ichitaso.quickpredict.plist"

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
- (BOOL)accessibilityUsesExtendedKeyboardPredictionsEnabled;//iOS 13
@end

@interface TIPreferencesController : NSObject
+ (id)sharedPreferencesController;
- (void)setValue:(id)arg1 forKey:(int)arg2;
- (id)valueForKey:(int)arg1;
- (void)setValue:(id)arg1 forPreferenceKey:(id)arg2;
- (void)synchronizePreferences;
@end

static BOOL togglePredict;
static BOOL predictStatus;

static void predictChanged(NSDictionary *dict) {
    CPDistributedMessagingCenter *c = [CPDistributedMessagingCenter centerNamed:@"com.ichitaso.quickpredict"];
    rocketbootstrap_distributedmessagingcenter_apply(c);
    [c sendMessageName:@"QuickPredictKey" userInfo:dict];
}

%hook UIKeyboardLayoutStar
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    %orig;
    
    for (UITouch *touch in [touches allObjects]) {
        id kbTree = [self keyHitTest:[touch locationInView:touch.view]];
        if ([kbTree respondsToSelector:@selector(unhashedName)]) {
            NSString *unhashedName = [kbTree unhashedName];
            //NSLog(@"QuickPredictKey:%@", [kbTree unhashedName]);
            if ([unhashedName isEqualToString:@"Shift-Key"] && touch.tapCount == 3) {
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
    if (togglePredict) {
        return YES;
    }
    return %orig;
}
%end
//- (BOOL)shouldShowCandidateBarIfReceivedCandidatesInCurrentInputMode:(BOOL)arg1 ignoreHidePredictionTrait:(BOOL)arg2 { // No display but bar is visible
//    if (togglePredict) {
//        return YES;
//    }
//    return NO;
//}
%group iOS_12
- (BOOL)predictionFromPreference { // iPhone X Serise
    if (togglePredict) {
        return YES;
    }
    return %orig;
}

- (BOOL)canOfferPredictionsForTraits {
    if (togglePredict) {
        return YES;
    }
    return NO;
}
 
- (BOOL)predictionForTraitsWithForceEnable:(BOOL)arg1 {
    if (togglePredict) {
        return YES;
    }
    return NO;
}
%end
%end

//%group iOS_13
//%hook TIPreferencesController
//- (id)valueForKey:(int)arg1 {
//    NSLog(@"valueForKey:%@ %d",%orig,arg1);
//    return %orig;
//}
//- (BOOL)predictionEnabled {
//    if (!togglePredict) {
//        return NO;
//    }
//    return %orig;
//}
//- (void)setValue:(id)arg1 forPreferenceKey:(id)arg2 {
//    NSLog(@"setValue:%@ forPreferenceKey:%@",arg1,arg2);
//    %orig;
//}
//%end
//%end

%group SpringBoard
%hook SpringBoard
- (void)applicationDidFinishLaunching:(id)application {
    %orig;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showAlertView:) name:NOTIFY_NAME object:nil];
    
    CPDistributedMessagingCenter *msgCenter = [%c(CPDistributedMessagingCenter) centerNamed:@"com.ichitaso.quickpredict"];
    rocketbootstrap_distributedmessagingcenter_apply(msgCenter);
    [msgCenter runServerOnCurrentThread];
    [msgCenter registerForMessageName:@"QuickPredictKey" target:self selector:@selector(predictKeyChanged:withUserInfo:)];
}
%new
- (void)showAlertView:(NSNotification *)notification {
    NSString *title = nil;
    
    if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_13_0) {
        TIPreferencesController *tc = [%c(TIPreferencesController) sharedPreferencesController];
        if ([[tc valueForKey:34] boolValue]) { // KeyboardShowPredictionBar
            title = @"Enabled";
        } else {
            title = @"Disabled";
        }
    } else {
        if (predictStatus) {
            title = @"Enabled";
        } else {
            title = @"Disabled";
        }
    }
    
    NSNumber *status = notification.userInfo[@"status"];
    NSLog(@"togglePredict:%d",[status boolValue]);
    if ([status boolValue]) {
        title = @"Enabled";
    } else {
        title = @"Disabled";
    }
    
    UIAlertController *alert =
    [UIAlertController alertControllerWithTitle:@"Predictive Keyboard"
                                        message:title
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *cancelAction =
    [UIAlertAction actionWithTitle:@"OK"
                             style:UIAlertActionStyleCancel
                           handler:^(UIAlertAction *action) {}];
    
    [alert addAction:cancelAction];
    
    UIViewController *vc = [UIApplication sharedApplication].keyWindow.rootViewController;
    
    [vc presentViewController:alert animated:YES completion:nil];
}
%new
- (void)predictKeyChanged:(NSString *)name withUserInfo:(NSDictionary *)d {
    if ([name isEqualToString:@"QuickPredictKey"]) {
        NSNumber *status = d[@"status"];
        
        predictStatus = [status boolValue];
        //NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:PREF_PATH];
        //NSMutableDictionary *mutableDict = dict ? [dict mutableCopy] : [NSMutableDictionary dictionary];
        //[mutableDict setValue:@(togglePredict) forKey:@"togglePredict"];
        //[mutableDict writeToFile:PREF_PATH atomically:NO];
    }
}
%end
%end

static void showAlertNotification(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    
    if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_13_0) {
        TIPreferencesController *tc = [%c(TIPreferencesController) sharedPreferencesController];
        if ([[tc valueForKey:35] boolValue]) { // KeyboardPrediction //Memo: !togglePredict
            [tc setValue:@(NO) forPreferenceKey:@(KeyboardPrediction)];
            [tc setValue:@(NO) forPreferenceKey:@(KeyboardShowPredictionBar)];
        } else {
            [tc setValue:@(YES) forPreferenceKey:@(KeyboardPrediction)];
            [tc setValue:@(YES) forPreferenceKey:@(KeyboardShowPredictionBar)];
        }
        [tc synchronizePreferences];
    }
    
    // Set boolValue
    NSDictionary *info = togglePredict ? @{@"status": @YES} : @{@"status": @NO};
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.002 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void) {
        // Send SpringBoard Notification
        predictChanged(info);
    });

    double delayInSeconds = 0.5;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
        // Keyboard relayout
        [[%c(UIKeyboardImpl) sharedInstance] updateLayout];
        // Send Alert Notification
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFY_NAME object:nil userInfo:info];
        // Show Keyboard
        [[%c(UIKeyboardImpl) sharedInstance] showKeyboard];
    });
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
    }
}

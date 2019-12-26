#import <firmware.h>

#define NOTIFY_ALEART "com.ichitaso.quickpredict.showalert"
#define NOTIFY_NAME @"com.ichitaso.quickpredict.springboard"

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

@interface UIKeyboardCache
+ (id)sharedInstance;
- (void)purge;
@end

static BOOL isOn;

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
                isOn = !isOn;
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
    if (isOn) {
        return YES;
    }
    return %orig;
}
%end

%group iOS_12
- (BOOL)canOfferPredictionsForTraits {
    if (isOn) {
        return YES;
    }
    return NO;
}
 
- (BOOL)predictionForTraitsWithForceEnable:(BOOL)arg1 {
    if (isOn) {
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
    NSString *title = nil;
    NSNumber *status = notification.userInfo[@"status"];
    //NSLog(@"[status boolValue]:%d",[status boolValue]);
    if ([status boolValue]) {
        title = @"Enabled";
    } else {
        title = @"Disabled";
    }
    
    UIAlertController *alert =
    [UIAlertController alertControllerWithTitle:@"Predict keyboards"
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
%end
%end

static void showAlertNotification(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    double delayInSeconds = 0.5;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
        // Keyboard relayout
        [[%c(UIKeyboardImpl) sharedInstance] updateLayout];
        // Set boolValue
        NSDictionary *info = isOn ? @{@"status": @YES} : @{@"status": @NO};
        // Send Alert Notification
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFY_NAME object:nil userInfo:info];
        // Show Keyboard
        [[%c(UIKeyboardImpl) sharedInstance] showKeyboard];
    });
}

%ctor {
    @autoreleasepool {
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

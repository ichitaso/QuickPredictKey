#import <UIKit/UIKit.h>
#import "Preferences.h"
#import <SafariServices/SafariServices.h>
#import <spawn.h>
#import <firmware.h>
#import <UIKit/UIImage+Private.h>

#define PREF_PATH @"/var/mobile/Library/Preferences/com.ichitaso.quickpredict.plist"
#define Notify_Preferences "com.ichitaso.quickpredict.prefschanged"

#define TWEAK_TITLE @"QuickPredictKey";
#define TWEAK_DESCRIPTION @"Easily switch between Predict keyboard";

#define SettingsColor(alphaValue) [UIColor colorWithRed:0.25 green:0.30 blue:0.39 alpha:alphaValue]
#define SettingsDark(alphaValue) [UIColor colorWithRed:0.61 green:0.72 blue:0.95 alpha:alphaValue]
#define PSTableColor(alphaValue) [UIColor colorWithRed:0.00 green:0.00 blue:0.00 alpha:alphaValue]
#define PSDarkColor(alphaValue) [UIColor colorWithRed:1.00 green:1.00 blue:1.00 alpha:alphaValue]

#define LOGO_IMAGE @"icon"

@class PSSpecifier;

@interface PSSpecifier (Private)
- (void)setIdentifier:(NSString *)identifier;
@end

@interface PSListController (Private)
- (void)loadView;
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)_returnKeyPressed:(id)arg1;
- (void)presentViewController:(id)arg1 animated:(BOOL)arg2 completion:(id)arg3;
@end

@interface PSTableCell (Private)
@property(readonly, assign, nonatomic) UILabel *textLabel;
@end

@interface CustomButtonCell : PSTableCell
@end

@implementation CustomButtonCell
- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.textLabel.textColor = PSTableColor(1.0);
    
    if (@available(iOS 13.0, *)) {
        if ([[UITraitCollection currentTraitCollection] userInterfaceStyle] == UIUserInterfaceStyleDark) {
            self.textLabel.textColor = PSDarkColor(0.8);
        }
    }
}
@end

@interface NSString (Private)
- (NSString *)stringByEncodingQueryPercentEscapes;
@end

@implementation NSString (Private)
- (NSString *)stringByEncodingQueryPercentEscapes {
    return (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)self, NULL, CFSTR(":/?&=;+!@#$()',*"), kCFStringEncodingUTF8));
}
@end

@interface CustomSafariCell : PSTableCell
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier specifier:(id)specifier;
@end

@implementation CustomSafariCell
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier specifier:(PSSpecifier *)specifier {
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier specifier:specifier];
    
    if (self) {
        self.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"safari" inBundle:[NSBundle bundleForClass:self.class]]];
    }
    return self;
}
@end

@interface CustomLinkCell : PSTableCell {
    NSString *_user;
}
@property (nonatomic, retain, readonly) UIView *avatarView;
@property (nonatomic, retain, readonly) UIImageView *avatarImageView;
@property (nonatomic, retain) UIImage *avatarImage;
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier specifier:(id)specifier;
- (BOOL)shouldShowAvatar;
@end

@implementation CustomLinkCell
- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.textLabel.textColor = PSTableColor(1.0);
    
    if (@available(iOS 13.0, *)) {
        if ([[UITraitCollection currentTraitCollection] userInterfaceStyle] == UIUserInterfaceStyleDark) {
            self.textLabel.textColor = PSDarkColor(0.8);
        }
    }
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier specifier:(PSSpecifier *)specifier {
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier specifier:specifier];
    
    if (self) {
        self.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"twitter" inBundle:[NSBundle bundleForClass:self.class]]];
        
        _user = [specifier.properties[@"user"] copy];
        NSAssert(_user, @"User name not provided");
        
        self.detailTextLabel.text = [@"@" stringByAppendingString:_user];
        self.detailTextLabel.textColor = [UIColor colorWithWhite:142.f / 255.f alpha:1];
        
        if (self.shouldShowAvatar) {
            CGFloat size = 38.f;
            
            UIGraphicsBeginImageContextWithOptions(CGSizeMake(size, size), NO, [UIScreen mainScreen].scale);
            specifier.properties[@"iconImage"] = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
            _avatarView = [[UIView alloc] initWithFrame:self.imageView.bounds];
            _avatarView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            _avatarView.backgroundColor = [UIColor colorWithWhite:0.9f alpha:1];
            _avatarView.userInteractionEnabled = NO;
            _avatarView.clipsToBounds = YES;
            _avatarView.layer.cornerRadius = size / 2;
            [self.imageView addSubview:_avatarView];
            
            if (specifier.properties[@"initials"]) {
                _avatarView.backgroundColor = [UIColor colorWithWhite:0.8f alpha:1];
                
                UILabel *label = [[UILabel alloc] initWithFrame:_avatarView.bounds];
                label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
                label.font = [UIFont systemFontOfSize:13.f];
                label.textAlignment = NSTextAlignmentCenter;
                label.textColor = [UIColor whiteColor];
                label.text = specifier.properties[@"initials"];
                [_avatarView addSubview:label];
            } else {
                _avatarImageView = [[UIImageView alloc] initWithFrame:_avatarView.bounds];
                _avatarImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
                _avatarImageView.alpha = 0;
                _avatarImageView.userInteractionEnabled = NO;
                _avatarImageView.layer.minificationFilter = kCAFilterTrilinear;
                [_avatarView addSubview:_avatarImageView];
                
                [self loadAvatarIfNeeded];
            }
        }
    }
    return self;
}

#pragma mark - Avatar

- (UIImage *)avatarImage {
    return _avatarImageView.image;
}

- (void)setAvatarImage:(UIImage *)avatarImage {
    // set the image on the image view
    _avatarImageView.image = avatarImage;
    // if we haven’t faded in yet
    if (_avatarImageView.alpha == 0) {
        // do so now
        [UIView animateWithDuration:0.15 animations:^{
            _avatarImageView.alpha = 1;
        }];
    }
}

- (BOOL)shouldShowAvatar {
    return YES;
}

- (void)loadAvatarIfNeeded {
    if (!_user) return;
    
    if (self.avatarImage) return;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *error = nil;
        NSData *data = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://twitter.com/%@/profile_image?size=bigger", _user.stringByEncodingQueryPercentEscapes]]] returningResponse:nil error:&error];
        
        if (error) return;
        
        UIImage *image = [UIImage imageWithData:data];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.avatarImage = image;
        });
    });
}
@end

static CGFloat const kHBFPHeaderTopInset = 64.f;
static CGFloat const kHBFPHeaderHeight = 160.f;

@interface QuickPredictKeySettingsController : PSListController {
    CGRect topFrame;
	UILabel *bannerTitle;
	UILabel *footerLabel;
	UILabel *titleLabel;
}
@property(retain) UIView *bannerView;
- (NSArray *)specifiers;
@end

@implementation QuickPredictKeySettingsController
- (NSArray *)specifiers {
	if (_specifiers == nil) {
        NSMutableArray *specifiers = [NSMutableArray array];
        PSSpecifier *spec;
                
        spec = [PSSpecifier preferenceSpecifierNamed:@"Settings"
                                              target:self
                                                 set:Nil
                                                 get:Nil
                                              detail:Nil
                                                cell:PSGroupCell
                                                edit:Nil];
        [specifiers addObject:spec];
        
        spec = [PSSpecifier preferenceSpecifierNamed:@"Enabled"
                                              target:self
                                                 set:@selector(setPreferenceValue:specifier:)
                                                 get:@selector(readPreferenceValue:)
                                              detail:Nil
                                                cell:PSSwitchCell
                                                edit:Nil];
        [spec setProperty:@"enabled" forKey:@"key"];
        [spec setProperty:@YES forKey:@"default"];
        [specifiers addObject:spec];
        
        spec = [PSSpecifier emptyGroupSpecifier];
        [specifiers addObject:spec];
                
        spec = [PSSpecifier preferenceSpecifierNamed:@"Haptic feedback"
                                              target:self
                                                 set:@selector(setPreferenceValue:specifier:)
                                                 get:@selector(readPreferenceValue:)
                                              detail:Nil
                                                cell:PSSwitchCell
                                                edit:Nil];
        [spec setProperty:@"haptic" forKey:@"key"];
        [spec setProperty:@YES forKey:@"default"];
        [specifiers addObject:spec];
        
        spec = [PSSpecifier preferenceSpecifierNamed:@"Show Alert View"
                                              target:self
                                                 set:@selector(setPreferenceValue:specifier:)
                                                 get:@selector(readPreferenceValue:)
                                              detail:Nil
                                                cell:PSSwitchCell
                                                edit:Nil];
        [spec setProperty:@"showAlert" forKey:@"key"];
        [spec setProperty:@NO forKey:@"default"];
        [specifiers addObject:spec];
        
        if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_13_0) {
            spec = [PSSpecifier preferenceSpecifierNamed:@"Force Enabled Predictive Keyboard"
                                                  target:self
                                                     set:@selector(setPreferenceValue:specifier:)
                                                     get:@selector(readPreferenceValue:)
                                                  detail:Nil
                                                    cell:PSSwitchCell
                                                    edit:Nil];
            [spec setProperty:@"forceEnabled" forKey:@"key"];
            [spec setProperty:@NO forKey:@"default"];
            [spec setProperty:NSClassFromString(@"PSSubtitleSwitchTableCell") forKey:@"cellClass"];
            [spec setProperty:@"For iOS 13 option. still buggy." forKey:@"cellSubtitleText"];
            [specifiers addObject:spec];
        }
        
        spec = [PSSpecifier emptyGroupSpecifier];
        [specifiers addObject:spec];
        
        spec = [PSSpecifier preferenceSpecifierNamed:@"Reset Settings"
                                              target:self
                                                 set:nil
                                                 get:nil
                                              detail:nil
                                                cell:PSButtonCell
                                                edit:nil];
        
        spec->action = @selector(resetSettings);
        [spec setProperty:@1 forKey:@"alignment"];
        [spec setProperty:NSClassFromString(@"CustomButtonCell") forKey:@"cellClass"];
        [specifiers addObject:spec];
           
        spec = [PSSpecifier preferenceSpecifierNamed:@"Credit"
                                              target:self
                                                 set:Nil
                                                 get:Nil
                                              detail:Nil
                                                cell:PSGroupCell
                                                edit:Nil];
        [specifiers addObject:spec];
        
        spec = [PSSpecifier preferenceSpecifierNamed:@"Other Tweaks"
                                              target:self
                                                 set:nil
                                                 get:nil
                                              detail:nil
                                                cell:PSLinkCell
                                                edit:nil];
        
        spec->action = @selector(openDonate);
        [spec setProperty:@1 forKey:@"alignment"];
        [spec setProperty:NSClassFromString(@"CustomSafariCell") forKey:@"cellClass"];
        [specifiers addObject:spec];
        
        spec = [PSSpecifier emptyGroupSpecifier];
        [spec setProperty:@"© 2015 - 2019 Cannathea by ichitaso" forKey:@"footerText"];
        [specifiers addObject:spec];
        
        spec = [PSSpecifier preferenceSpecifierNamed:@"Developed by ichitaso"
                                              target:self
                                                 set:nil
                                                 get:nil
                                              detail:nil
                                                cell:[PSTableCell cellTypeFromString:@"PSButtonCell"]
                                                edit:nil];
        
        spec->action = @selector(openIchitasoTwitter);
        [spec setProperty:@"ichitaso" forKey:@"user"];
        [spec setProperty:NSClassFromString(@"CustomLinkCell") forKey:@"cellClass"];
        [specifiers addObject:spec];
        
		_specifiers = [specifiers copy];
	}
	return _specifiers;
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
    @autoreleasepool {
        NSMutableDictionary *EnablePrefsCheck = [[NSMutableDictionary alloc] initWithContentsOfFile:PREF_PATH]?:[NSMutableDictionary dictionary];
        [EnablePrefsCheck setObject:value forKey:[specifier identifier]];
        [EnablePrefsCheck writeToFile:PREF_PATH atomically:YES];
        
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR(Notify_Preferences), NULL, NULL, true);
    }
}
- (id)readPreferenceValue:(PSSpecifier*)specifier {
    @autoreleasepool {
        NSDictionary *EnablePrefsCheck = [[NSDictionary alloc] initWithContentsOfFile:PREF_PATH];
        return EnablePrefsCheck[[specifier identifier]]?:[[specifier properties] objectForKey:@"default"];
    }
}
// Refresh on dark mode toggle
- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_13_0) {
        [self loadView];
        [self reloadSpecifiers];
    }
}
- (void)resetSettings {
    UIAlertController *alertController =
    [UIAlertController alertControllerWithTitle:nil
                                        message:@"Reset Settings?"
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"OK"
                                                        style:UIAlertActionStyleDestructive
                                                      handler:^(UIAlertAction *action) {
                                                          [[NSFileManager defaultManager] removeItemAtPath:PREF_PATH error:nil];
                                                          [self reloadSpecifiers];
                                                          CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR(Notify_Preferences), NULL, NULL, true);
                                                      }]];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction *action) {
                                                          
                                                      }]];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)loadView {
  	[super loadView];
    
  	UIWindow *window = [UIApplication sharedApplication].keyWindow;
  	if (window == nil) {
        window = [[UIApplication sharedApplication].windows firstObject];
    }
  	if ([window respondsToSelector:@selector(tintColor)]) {
        window.tintColor = SettingsColor(0.85);
        // Dark mode
        if (@available(iOS 13.0, *)) {
            if ([[UITraitCollection currentTraitCollection] userInterfaceStyle] == UIUserInterfaceStyleDark) {
                window.tintColor = SettingsDark(0.85);
            }
        }
    }
    // UISwitch color
    [UISwitch appearanceWhenContainedInInstancesOfClasses:@[self.class]].onTintColor = SettingsColor(0.6);
    
    UINavigationItem *navigationItem = self.navigationItem;
    // Share button
    navigationItem.rightBarButtonItem =
    [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                  target:self
                                                  action:@selector(shareTweak)];
    
    navigationItem.titleView =
    [[UIImageView alloc] initWithImage:[UIImage imageNamed:LOGO_IMAGE
                                                  inBundle:[NSBundle bundleForClass:self.class]]];
    
    //[navigationItem.titleView setAlpha:0];
    
    CGFloat headerHeight = 0 + kHBFPHeaderHeight;
    CGRect selfFrame = [self.view frame];
    
    _bannerView = [[UIView alloc] init];
    _bannerView.frame = CGRectMake(0, -kHBFPHeaderHeight, selfFrame.size.width, headerHeight);
    _bannerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    [self.table addSubview:_bannerView];
    [self.table sendSubviewToBack:_bannerView];
    
    topFrame = CGRectMake(0, -kHBFPHeaderHeight, 414, kHBFPHeaderHeight);
    
    bannerTitle = [[UILabel alloc] init];
    bannerTitle.text = TWEAK_TITLE;
    [bannerTitle setFont:[UIFont fontWithName:@"HelveticaNeue-Thin" size:40]];
    bannerTitle.textColor = SettingsColor(0.55);
    // Dark mode
    if (@available(iOS 13.0, *)) {
        if ([[UITraitCollection currentTraitCollection] userInterfaceStyle] == UIUserInterfaceStyleDark) {
            bannerTitle.textColor = SettingsDark(0.55);
        }
    }
    
    [_bannerView addSubview:bannerTitle];
    
    [bannerTitle setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_bannerView addConstraint:[NSLayoutConstraint constraintWithItem:bannerTitle attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:_bannerView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0f]];
    [_bannerView addConstraint:[NSLayoutConstraint constraintWithItem:bannerTitle attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:_bannerView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:20.0f]];
    bannerTitle.textAlignment = NSTextAlignmentCenter;
    
    footerLabel = [[UILabel alloc] init];
    footerLabel.text = TWEAK_DESCRIPTION;
    [footerLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:15]];
    footerLabel.textColor = [UIColor grayColor];
    footerLabel.alpha = 1.0;
    
    [_bannerView addSubview:footerLabel];
    
    [footerLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_bannerView addConstraint:[NSLayoutConstraint constraintWithItem:footerLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:_bannerView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0f]];
    [_bannerView addConstraint:[NSLayoutConstraint constraintWithItem:footerLabel attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:_bannerView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:60.0f]];
    footerLabel.textAlignment = NSTextAlignmentCenter;
    
    [self.table setContentInset:UIEdgeInsetsMake(kHBFPHeaderHeight-kHBFPHeaderTopInset,0,0,0)];
    [self.table setContentOffset:CGPointMake(0, -kHBFPHeaderHeight+kHBFPHeaderTopInset)];
}

//- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
//    UINavigationItem *navigationItem = self.navigationItem;
//
//    CGFloat scrollOffset = scrollView.contentOffset.y;
//    topFrame = CGRectMake(0, scrollOffset, 414, -scrollOffset);
//
//    if (scrollOffset > -167 && scrollOffset < -60 && scrollOffset != -150) {
//        float alphaDegree = -60 - scrollOffset;
//        [navigationItem.titleView setAlpha:1/alphaDegree];
//    } else if (scrollOffset >= -60) {
//        [navigationItem.titleView setAlpha:1];
//       } else if (scrollOffset < -167) {
//        [navigationItem.titleView setAlpha:0];
//    }
//}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    if (window == nil) {
        window = [[UIApplication sharedApplication].windows firstObject];
    }
    if ([window respondsToSelector:@selector(tintColor)]) {
        window.tintColor = SettingsColor(0.85);
        // Dark mode
        if (@available(iOS 13.0, *)) {
            if ([[UITraitCollection currentTraitCollection] userInterfaceStyle] == UIUserInterfaceStyleDark) {
                window.tintColor = SettingsDark(0.85);
            }
        }
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    if (window == nil) {
        window = [[UIApplication sharedApplication].windows firstObject];
    }
    if ([window respondsToSelector:@selector(tintColor)]) {
        window.tintColor = SettingsColor(0.85);
        // Dark mode
        if (@available(iOS 13.0, *)) {
            if ([[UITraitCollection currentTraitCollection] userInterfaceStyle] == UIUserInterfaceStyleDark) {
                window.tintColor = SettingsDark(0.85);
            }
        }
    }
}

- (void)_unloadBundleControllers {
    [super _unloadBundleControllers];
    
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    if ([window respondsToSelector:@selector(tintColor)]) {
        window.tintColor = nil;
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    if (window == nil)
        window = [[UIApplication sharedApplication].windows firstObject];
    
    // Should check whether the bundle is loaded.
    if ([[[self bundle] bundlePath] hasSuffix:@"QuickPredictKeySettings.bundle"]) {
        if ([window respondsToSelector:@selector(tintColor)]) {
            window.tintColor = SettingsColor(0.85);
            // Dark mode
            if (@available(iOS 13.0, *)) {
                if ([[UITraitCollection currentTraitCollection] userInterfaceStyle] == UIUserInterfaceStyleDark) {
                    window.tintColor = SettingsDark(0.85);
                }
            }
        }
    } else {
        if ([window respondsToSelector:@selector(tintColor)])
            window.tintColor = nil;
    }
}

- (void)shareTweak {
    NSString *texttoshare = @"I'm using QuickPredictKey by @ichitaso! It's a useful tweaks!";
    NSURL *urlToShare = [NSURL URLWithString:@"https://cydia.ichitaso.com/depiction/quickpredict.html"];
    
    NSArray *activityItems = @[texttoshare, urlToShare];
    
    UIActivityViewController *activityVC =
    [[UIActivityViewController alloc] initWithActivityItems:activityItems
                                      applicationActivities:nil];
    
    // Fix Crash for iPad
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        activityVC.popoverPresentationController.sourceView = self.view;
        activityVC.popoverPresentationController.sourceRect = self.view.bounds;
        activityVC.popoverPresentationController.permittedArrowDirections = 0;
    }
    
    [self presentViewController:activityVC animated:YES completion:nil];
}

- (void)openDonate {
    [self openURLInBrowser:@"https://cydia.ichitaso.com/donation.html"];
}

- (void)openIchitasoTwitter {
    NSString *twitterID = @"ichitaso";
    
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:@"Follow @ichitaso"
                                          message:nil
                                          preferredStyle:UIAlertControllerStyleActionSheet];
    
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tweetbot://"]]) {
        [alertController addAction:[UIAlertAction actionWithTitle:@"Open in Tweetbot" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"tweetbot:///user_profile/%@",twitterID]]
                                               options:@{}
                                     completionHandler:nil];
        }]];
    }
    
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitter://"]]) {
        [alertController addAction:[UIAlertAction actionWithTitle:@"Open in Twitter" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"twitter://user?screen_name=%@",twitterID]]
                                               options:@{}
                                     completionHandler:nil];
        }]];
    }
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"Open in Browser" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        double delayInSeconds = 0.8;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self openURLInBrowser:[NSString stringWithFormat:@"https://twitter.com/%@",twitterID]];
        });
    }]];
    
    // Fix Crash for iPad
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        CGRect rect = self.view.frame;
        alertController.popoverPresentationController.sourceView = self.view;
        alertController.popoverPresentationController.sourceRect = CGRectMake(CGRectGetMidX(rect)-60,rect.size.height-50, 120,50);
        alertController.popoverPresentationController.permittedArrowDirections = 0;
    } else {
        [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            
        }]];
    }
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)openURLInBrowser:(NSString *)url {
    SFSafariViewController *safari = [[SFSafariViewController alloc] initWithURL:[NSURL URLWithString:url] entersReaderIfAvailable:NO];
    [self presentViewController:safari animated:YES completion:nil];
}

@end

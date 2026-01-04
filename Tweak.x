#import <YouTubeHeader/GOOHUDManagerInternal.h>
#import <YouTubeHeader/MLCaption.h>
#import <YouTubeHeader/MLFormat3Captions.h>
#import <YouTubeHeader/YTAlertView.h>
#import <YouTubeHeader/YTFormat3CaptionViewController.h>
#import <YouTubeHeader/YTMainAppVideoPlayerOverlayViewController.h>
#import <YouTubeHeader/YTUIResources.h>
#import "../YTVideoOverlay/Header.h"
#import "../YTVideoOverlay/Init.x"

#define _LOC(b, x) [b localizedStringForKey:x value:nil table:nil]
#define LOC(x) _LOC(tweakBundle, x)

#define TweakKey @"YouGetCaption"

@interface YTInlinePlayerBarContainerView (YouGetCaption)
- (void)didPressYouGetCaption:(id)arg;
@end

@interface YTMainAppControlsOverlayView (YouGetCaption)
- (void)didPressYouGetCaption:(id)arg;
@end

static NSBundle *YouGetCaptionBundle() {
    static NSBundle *bundle = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *tweakBundlePath = [[NSBundle mainBundle] pathForResource:@"YouGetCaption" ofType:@"bundle"];
        bundle = [NSBundle bundleWithPath:tweakBundlePath ?: PS_ROOT_PATH_NS(@"/Library/Application Support/YouGetCaption.bundle")];
    });
    return bundle;
}

static void showTranscript(YTFormat3CaptionViewController *cvc) {
    NSBundle *tweakBundle = YouGetCaptionBundle();
    MLFormat3Captions *currentCaptions = [cvc valueForKey:@"_currentCaptions"];
    YTIntervalTree *tree = currentCaptions.captions;
    NSMutableString *transcript = [NSMutableString string];
    [tree enumerateAllIntervalsWithBlock:^(YTInterval *interval) {
        MLCaption *caption = (MLCaption *)interval;
        NSArray <MLCaptionSegment *> *segments = caption.segments;
        for (MLCaptionSegment *segment in segments) {
            [transcript appendString:segment.text];
        }
    }];
    if (transcript.length == 0) {
        YTAlertView *alertView = [%c(YTAlertView) infoDialog];
        alertView.title = LOC(@"CAPTIONS");
        alertView.subtitle = LOC(@"NO_CAPTIONS");
        alertView.shouldDismissOnBackgroundTap = YES;
        [alertView show];
        return;
    }
    YTAlertView *alertView = [%c(YTAlertView) confirmationDialogWithAction:^{
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        pasteboard.string = transcript;
        [[%c(GOOHUDManagerInternal) sharedInstance] showMessageMainThread:[%c(YTHUDMessage) messageWithText:LOC(@"COPIED_TO_CLIPBOARD")]];
    } actionTitle:LOC(@"COPY_TO_CLIPBOARD")];
    alertView.title = LOC(@"CAPTIONS");
    alertView.subtitle = transcript;
    alertView.shouldDismissOnBackgroundTap = YES;
    [alertView show];
}

%group Top

%hook YTMainAppControlsOverlayView

- (UIImage *)buttonImage:(NSString *)tweakId {
    return [tweakId isEqualToString:TweakKey] ? [%c(YTUIResources) outlineTextWithColor:[UIColor whiteColor]] : %orig;
}

%new(v@:@)
- (void)didPressYouGetCaption:(id)arg {
    YTMainAppVideoPlayerOverlayViewController *c = [self valueForKey:@"_eventsDelegate"];
    YTFormat3CaptionViewController *cvc = [c valueForKey:@"_captionOverlayViewController"];
    showTranscript(cvc);
}

%end

%end

%group Bottom

%hook YTInlinePlayerBarContainerView

- (UIImage *)buttonImage:(NSString *)tweakId {
    return [tweakId isEqualToString:TweakKey] ? [%c(YTUIResources) outlineTextWithColor:[UIColor whiteColor]] : %orig;
}

%new(v@:@)
- (void)didPressYouGetCaption:(id)arg {
    YTMainAppVideoPlayerOverlayViewController *c = [self.delegate valueForKey:@"_delegate"];
    YTFormat3CaptionViewController *cvc = [c valueForKey:@"_captionOverlayViewController"];
    showTranscript(cvc);
}

%end

%end

%ctor {
    initYTVideoOverlay(TweakKey, @{
        AccessibilityLabelKey: @"Caption",
        SelectorKey: @"didPressYouGetCaption:",
    });
    %init(Top);
    %init(Bottom);
}

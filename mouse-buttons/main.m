#import <Foundation/Foundation.h>
#import <IOKit/hid/IOHIDManager.h>
#import <Cocoa/Cocoa.h>
#import "Safari.h"

void GoBackPageSafari(void) {
    SafariApplication *safari = [SBApplication applicationWithBundleIdentifier:@"com.apple.Safari"];
    if (![safari isRunning]) {
        return;
    }
    
    SafariWindow *frontWindow = [[safari windows] objectAtIndex: 0];
    if (frontWindow) {
        [frontWindow currentTab].URL = @"javascript:window.history.back()";
    } else {
        return;
    }
}

void GoForwardPageSafari(void) {
    SafariApplication *safari = [SBApplication applicationWithBundleIdentifier:@"com.apple.Safari"];
    if (![safari isRunning]) {
        return;
    }
    
    SafariWindow *frontWindow = [[safari windows] objectAtIndex: 0];
    if (frontWindow) {
        [frontWindow currentTab].URL = @"javascript:window.history.forward()";
    } else {
        return;
    }
}
BOOL isCursorOverSafari(void) {
    CGPoint cursorPosition = CGEventGetLocation(CGEventCreate(NULL));
    CFArrayRef windowList = CGWindowListCopyWindowInfo(kCGWindowListOptionOnScreenOnly, kCGNullWindowID);

    NSArray *windows = CFBridgingRelease(windowList);
    for (NSDictionary *window in windows) {
        NSString *ownerName = window[(NSString *)kCGWindowOwnerName];
        if ([ownerName isEqualToString:@"Safari"]) {
            NSDictionary *boundsDict = window[(NSString *)kCGWindowBounds];
            CGRect windowRect = CGRectMake([boundsDict[@"X"] floatValue], [boundsDict[@"Y"] floatValue], [boundsDict[@"Width"] floatValue], [boundsDict[@"Height"] floatValue]);
            
            if (CGRectContainsPoint(windowRect, cursorPosition)) {
                return YES;
            }
        }
    }
    return NO;
}


static void Handle_IOHIDInputValueCallback(void *context, IOReturn result, void *sender, IOHIDValueRef value) {
    IOHIDElementRef elem = IOHIDValueGetElement(value);
    if (IOHIDElementGetUsagePage(elem) == kHIDPage_Button) {
        uint32_t usage = IOHIDElementGetUsage(elem);
        long pressed = IOHIDValueGetIntegerValue(value);

        if (pressed != 0 && isCursorOverSafari() && usage == 4) {
            GoBackPageSafari();
        }
        if (pressed != 0 && isCursorOverSafari() && usage == 5) {
            GoForwardPageSafari();
        }
    }
}




int main(int argc, const char * argv[]) {
    @autoreleasepool {
        IOHIDManagerRef hidManager = IOHIDManagerCreate(kCFAllocatorDefault, kIOHIDOptionsTypeNone);
        NSDictionary *matchDictionary = @{ @kIOHIDDeviceUsagePageKey: @(kHIDPage_GenericDesktop),
                                           @kIOHIDDeviceUsageKey: @(kHIDUsage_GD_Mouse) };
        IOHIDManagerSetDeviceMatching(hidManager, (__bridge CFDictionaryRef)matchDictionary);
        IOHIDManagerOpen(hidManager, kIOHIDOptionsTypeNone);
        IOHIDManagerScheduleWithRunLoop(hidManager, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
        IOHIDManagerRegisterInputValueCallback(hidManager, Handle_IOHIDInputValueCallback, NULL);
        CFRunLoopRun();
    }
    return 0;
}

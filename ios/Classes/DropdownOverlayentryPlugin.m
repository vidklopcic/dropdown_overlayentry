#import "DropdownOverlayentryPlugin.h"
#if __has_include(<dropdown_overlayentry/dropdown_overlayentry-Swift.h>)
#import <dropdown_overlayentry/dropdown_overlayentry-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "dropdown_overlayentry-Swift.h"
#endif

@implementation DropdownOverlayentryPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftDropdownOverlayentryPlugin registerWithRegistrar:registrar];
}
@end

#import "LoginStartup.h"
#import <ServiceManagement/ServiceManagement.h>

// Load the macOS 13+ API at runtime so older build SDKs remain usable.
@protocol CodexLoginService
+ (id)mainAppService;
+ (void)openSystemSettingsLoginItems;
- (NSInteger)status;
- (BOOL)registerAndReturnError:(NSError **)error;
- (BOOL)unregisterAndReturnError:(NSError **)error;
@end

static Class<CodexLoginService> ServiceClass(void) {
    return (Class<CodexLoginService>)NSClassFromString(@"SMAppService");
}

NSInteger CodexLoginStatus(void) {
    Class<CodexLoginService> cls = ServiceClass();
    return cls ? [[cls mainAppService] status] : -1;
}

BOOL CodexSetLoginEnabled(BOOL enabled, NSError **error) {
    Class<CodexLoginService> cls = ServiceClass();
    if (!cls) {
        if (error) *error = [NSError errorWithDomain:@"CodexUsageMonitor" code:1
            userInfo:@{NSLocalizedDescriptionKey: @"Start at Login requires macOS 13 or later."}];
        return NO;
    }
    id<CodexLoginService> service = [cls mainAppService];
    return enabled ? [service registerAndReturnError:error] : [service unregisterAndReturnError:error];
}

void CodexOpenLoginSettings(void) {
    Class<CodexLoginService> cls = ServiceClass();
    if (cls) [cls openSystemSettingsLoginItems];
}

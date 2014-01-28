#import "CDVPassbook.h"
#import <Cordova/CDV.h>
#import <PassKit/PassKit.h>

@implementation CDVPassbook

- (BOOL)shouldOverrideLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType
{
    if(PKPassLibrary.isPassLibraryAvailable && [request.URL.pathExtension isEqualToString:@"pkpass"]) {
        [self downloadPass:request.URL success:nil error:nil];
        return YES;
    }
    
    return NO;
}

- (void)available:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult *commandResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:[PKPassLibrary isPassLibraryAvailable]];
    [self.commandDelegate sendPluginResult:commandResult callbackId:command.callbackId];
}

- (void)downloadPass:(CDVInvokedUrlCommand*)command
{
    if(!PKPassLibrary.isPassLibraryAvailable) {
        CDVPluginResult *commandResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_INVALID_ACTION messageAsString:@"Passbook is not available on this device"];
        [self.commandDelegate sendPluginResult:commandResult callbackId:command.callbackId];
        return;
    }
    
    NSString *urlStr = [command argumentAtIndex:0];
    NSURL *url = [NSURL URLWithString:urlStr];
    if(!url) {
        CDVPluginResult *commandResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_MALFORMED_URL_EXCEPTION];
        [self.commandDelegate sendPluginResult:commandResult callbackId:command.callbackId];
        return;
    }
    [self downloadPass:url success:^{
        CDVPluginResult *commandResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self.commandDelegate sendPluginResult:commandResult callbackId:command.callbackId];
    } error:^(NSError *error) {
        CDVPluginResult *commandResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
        [self.commandDelegate sendPluginResult:commandResult callbackId:command.callbackId];
    }];
}

- (void)tryAddPass:(NSData*)data success:(void (^)(void))successBlock error:(void (^)(NSError *error))errorBlock
{
    NSError *error = nil;
    PKPass *pass = [[PKPass alloc] initWithData:data error:&error];
    if(!pass) {
        if(errorBlock) {
            errorBlock(error);
        }
        return;
    }
    
    PKAddPassesViewController *c = [[PKAddPassesViewController alloc] initWithPass:pass];
    
    [self.viewController presentViewController:c animated:YES completion:^{
        if(successBlock) {
            successBlock();
        }
    }];
}

- (void)downloadPass:(NSURL*) url success:(void (^)(void))successBlock error:(void (^)(NSError *error))errorBlock
{
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:NSURLCacheStorageNotAllowed timeoutInterval:20.0];
    // Fake User-Agent to be recognized as Passbook app, so that we directly get the pkpass file (when possible)
    [request addValue:@"Passbook/1.0 CFNetwork/672.0.2 Darwin/14.0.0" forHTTPHeaderField:@"User-Agent"];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        [self tryAddPass:data success:successBlock error:errorBlock];
    }];
}

@end

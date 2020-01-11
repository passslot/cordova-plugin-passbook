#import "CDVPassbook.h"
#import <Cordova/CDV.h>
#import <PassKit/PassKit.h>
#import <WebKit/WebKit.h>

NSString * const UserAgentHeader = @"User-Agent";
NSString * const PasskitAgentHeader = @"Passbook/1.0 CFNetwork/672.0.2 Darwin/14.0.0";

typedef void (^AddPassResultBlock)(PKPass *pass, BOOL added);
typedef void (^AddPassesResultBlock)(NSArray<PKPass *> *passes, BOOL added);

@interface CDVPassbook()<PKAddPassesViewControllerDelegate, WKNavigationDelegate>

@property (nonatomic, retain) PKPass *lastPass;
@property (nonatomic, retain) NSArray<PKPass *> *lastPasses;
@property (nonatomic, retain) id<WKNavigationDelegate> navigationDelegate;
@property (nonatomic, copy) AddPassResultBlock lastAddPassCallback;
@property (nonatomic, copy) AddPassesResultBlock lastAddPassesCallback;

- (BOOL)ensureAvailability:(CDVInvokedUrlCommand*)command;
- (void)sendPassResult:(PKPass*)pass added:(BOOL)added command:(CDVInvokedUrlCommand*)command;
- (void)sendPassesResult:(NSArray<PKPass*>*)pass added:(BOOL)added command:(CDVInvokedUrlCommand*)command;
- (void)sendError:(NSError*)error command:(CDVInvokedUrlCommand*)command;
- (void)downloadPass:(NSURL*) url
             headers:(NSDictionary * _Nullable)headers
             success:(AddPassResultBlock)successBlock
               error:(void (^)(NSError *error))errorBlock;
- (void)downloadPasses:(NSArray<NSURL*>*) urls
               headers:(NSDictionary * _Nullable)headers
               success:(AddPassesResultBlock)successBlock
                 error:(void (^)(NSError *error))errorBlock;
- (void)tryAddPass:(NSData*)data success:(AddPassResultBlock)successBlock error:(void (^)(NSError *error))errorBlock;
- (UIViewController*) getTopMostViewController;

@end

@implementation CDVPassbook

@synthesize lastPass;
@synthesize lastPasses;
@synthesize lastAddPassCallback;
@synthesize lastAddPassesCallback;
@synthesize navigationDelegate;

- (void)pluginInitialize
{
    if ([self.webView isKindOfClass:[WKWebView class]]) {
        WKWebView * webView = (WKWebView*)self.webView;
        self.navigationDelegate = webView.navigationDelegate;
        webView.navigationDelegate = self;
    }
}

+ (BOOL)available
{
    BOOL available = [PKPassLibrary isPassLibraryAvailable];
    if ([PKAddPassesViewController respondsToSelector:@selector(canAddPasses)]) {
        available = available && [PKAddPassesViewController performSelector:@selector(canAddPasses)];
    }
    return available;
}

- (void)available:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult *commandResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:[CDVPassbook available]];
    [self.commandDelegate sendPluginResult:commandResult callbackId:command.callbackId];
}

- (void)downloadPass:(CDVInvokedUrlCommand*)command
{
    if(![self ensureAvailability:command]) {
        return;
    }
    
    id callData = [command argumentAtIndex:0];
    
    NSURL *url;
    NSDictionary *headers;
    
    if ([callData isKindOfClass:[NSDictionary class]]) {
        
        url     = [NSURL URLWithString:callData[@"url"] ];
        headers = callData[@"headers"];
    }
    else { // let assume that is a string
        NSString *urlStr = [command argumentAtIndex:0];
        url = [NSURL URLWithString:urlStr];
    }
    if(!url) {
        CDVPluginResult *commandResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_MALFORMED_URL_EXCEPTION];
        [self.commandDelegate sendPluginResult:commandResult callbackId:command.callbackId];
        return;
    }
    [self downloadPass:url headers:headers success:^(PKPass *pass, BOOL added){
        [self sendPassResult:pass added:added command:command];
    } error:^(NSError *error) {
        [self sendError:error command:command];
    }];
}

- (void)downloadPasses:(CDVInvokedUrlCommand*)command
{
    if(![self ensureAvailability:command]) {
        return;
    }
    
    id callData = [command argumentAtIndex:0];
    
    NSArray<NSString*> *urlStrings;
    NSDictionary *headers;
    
    if ([callData isKindOfClass:[NSDictionary class]]) {
        urlStrings = callData[@"urls"];
        headers = callData[@"headers"];
    } else if ([callData isKindOfClass:[NSArray class]]) {
        urlStrings = callData;
    }
    
    if(!urlStrings || [urlStrings count] == 0) {
        CDVPluginResult *commandResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"requires single argument of array of url strings or array of objects with 'urls' property"];
        [self.commandDelegate sendPluginResult:commandResult callbackId:command.callbackId];
        return;
    }
    
    NSMutableArray<NSURL*> *urls = [NSMutableArray arrayWithCapacity:[urlStrings count]];
    for (NSString* urlString in urlStrings) {
        NSURL* url = [NSURL URLWithString:urlString];
        if(!url) {
            CDVPluginResult *commandResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_MALFORMED_URL_EXCEPTION messageAsString:[NSString stringWithFormat:@"malformed url: %@", urlString]];
            [self.commandDelegate sendPluginResult:commandResult callbackId:command.callbackId];
            return;
        }
        [urls addObject: url];
    }
    
    [self downloadPasses:urls headers:headers success:^(NSArray<PKPass*> *passes, BOOL added){
        [self sendPassesResult:passes added:added command:command];
    } error:^(NSError *error) {
        [self sendError:error command:command];
    }];
}

- (void)addPass:(CDVInvokedUrlCommand*)command
{
    if(![self ensureAvailability:command]) {
        return;
    }
    
    NSString *fileStr = [command argumentAtIndex:0];
    if (!fileStr) {
        CDVPluginResult *commandResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"no file provided"];
        [self.commandDelegate sendPluginResult:commandResult callbackId:command.callbackId];
        return;
    }
    
    NSURL *url = [NSURL URLWithString:fileStr];
    if (!url) {
        CDVPluginResult *commandResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"no valid file provided"];
        [self.commandDelegate sendPluginResult:commandResult callbackId:command.callbackId];
        return;
    }
    
    NSData *data = [NSData dataWithContentsOfURL:url];
    if (!data) {
        CDVPluginResult *commandResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_IO_EXCEPTION];
        [self.commandDelegate sendPluginResult:commandResult callbackId:command.callbackId];
        return;
    }
    
    [self tryAddPass:data success:^(PKPass *pass, BOOL added) {
        [self sendPassResult:pass added:added command:command];
    } error:^(NSError *error) {
        [self sendError:error command:command];
    }];
}

- (void)addPasses:(CDVInvokedUrlCommand*)command
{
    if(![self ensureAvailability:command]) {
        return;
    }
    NSArray<NSString*> *fileStrings = [command argumentAtIndex:0];
    if (!fileStrings || [fileStrings count] == 0) {
        CDVPluginResult *commandResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"requires single argument of an array of filenames"];
        [self.commandDelegate sendPluginResult:commandResult callbackId:command.callbackId];
        return;
    }
    
    NSMutableArray<NSData*> *passesData = [[NSMutableArray alloc] initWithCapacity:[fileStrings count]];
    for (NSString *fileStr in fileStrings) {
        if (!fileStr) {
            CDVPluginResult *commandResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"empty array element"];
            [self.commandDelegate sendPluginResult:commandResult callbackId:command.callbackId];
            return;
        }
        
        NSURL *url = [NSURL URLWithString:fileStr];
        if (!url) {
            CDVPluginResult *commandResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[NSString stringWithFormat:@"invalid file provided: %@", fileStr]];
            [self.commandDelegate sendPluginResult:commandResult callbackId:command.callbackId];
            return;
        }
        
        NSData *data = [NSData dataWithContentsOfURL:url];
        if (!data) {
            CDVPluginResult *commandResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_IO_EXCEPTION messageAsString:[NSString stringWithFormat:@"error reading file: %@", fileStr]];
            [self.commandDelegate sendPluginResult:commandResult callbackId:command.callbackId];
            return;
        }
        
        [passesData addObject: data];
    }
    [self tryAddPasses:passesData success:^(NSArray<PKPass*>* passes, BOOL added) {
        [self sendPassesResult:passes added:added command:command];
    } error:^(NSError *error) {
        [self sendError: error command:command];
    }];
}

- (void)openPass:(CDVInvokedUrlCommand *)command
{
    if(![self ensureAvailability:command]) {
        return;
    }
    
    NSURL *url = nil;
    id argument = [command argumentAtIndex:0];
    if ([argument isKindOfClass:NSDictionary.class]) {
        url = [NSURL URLWithString:argument[@"passURL"]];
    } else if ([argument isKindOfClass:NSString.class]) {
        url = [NSURL URLWithString:argument];
    } else {
        CDVPluginResult *commandResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"No Pass URL provided"];
        [self.commandDelegate sendPluginResult:commandResult callbackId:command.callbackId];
        return;
    }
    
    if (!url) {
        CDVPluginResult *commandResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_MALFORMED_URL_EXCEPTION];
        [self.commandDelegate sendPluginResult:commandResult callbackId:command.callbackId];
        return;
    }
    
    [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:^(BOOL opened) {
        if (opened) {
            CDVPluginResult *commandResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
            [self.commandDelegate sendPluginResult:commandResult callbackId:command.callbackId];
        } else {
            CDVPluginResult *commandResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Could not open Pass"];
            [self.commandDelegate sendPluginResult:commandResult callbackId:command.callbackId];
        }
    }];
}

- (BOOL)ensureAvailability:(CDVInvokedUrlCommand*)command
{
    if(![CDVPassbook available]) {
        CDVPluginResult *commandResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_INVALID_ACTION messageAsString:@"Passbook is not available on this device"];
        [self.commandDelegate sendPluginResult:commandResult callbackId:command.callbackId];
        return NO;
    }
    return YES;
}

- (void)sendPassResult:(PKPass*)pass added:(BOOL)added command:(CDVInvokedUrlCommand*)command
{
    NSDictionary *data = @{@"added": [NSNumber numberWithBool:added],
                           @"pass":@{
                                   @"passTypeIdentifier": pass.passTypeIdentifier,
                                   @"serialNumber": pass.serialNumber,
                                   @"passURL": pass.passURL.absoluteString
                           }
    };
    CDVPluginResult *commandResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:data];
    [self.commandDelegate sendPluginResult:commandResult callbackId:command.callbackId];
}

- (void)sendPassesResult:(NSArray<PKPass *> *)passes added:(BOOL)added command:(CDVInvokedUrlCommand*)command
{
    NSMutableArray* passesData = [NSMutableArray arrayWithCapacity:[passes count]];
    for (PKPass* pass in passes) {
        NSDictionary *passData = @{
            @"passTypeIdentifier": pass.passTypeIdentifier,
            @"serialNumber": pass.serialNumber,
            @"passURL": pass.passURL.absoluteString
        };
        [passesData addObject:passData];
    }
    NSDictionary *data = @{@"added": [NSNumber numberWithBool:added],
                           @"passes": [passesData copy]};
    CDVPluginResult *commandResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:data];
    [self.commandDelegate sendPluginResult:commandResult callbackId:command.callbackId];
}

- (void)sendError:(NSError*)error command:(CDVInvokedUrlCommand*)command{
    CDVPluginResult *commandResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
    [self.commandDelegate sendPluginResult:commandResult callbackId:command.callbackId];
}

- (void)tryAddPass:(NSData*)data success:(AddPassResultBlock)successBlock error:(void (^)(NSError *error))errorBlock
{
    NSError *error = nil;
    PKPass *pass = [[PKPass alloc] initWithData:data error:&error];
    if(!pass) {
        if(errorBlock) {
            errorBlock(error);
        }
        return;
    }
    
    self.lastPass = pass;
    self.lastAddPassCallback = successBlock;
    
    PKAddPassesViewController *c = [[PKAddPassesViewController alloc] initWithPass:pass];
    c.delegate = self;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[self getTopMostViewController] presentViewController:c animated:YES completion:nil];
    });
}

-(void)tryAddPasses:(NSArray<NSData *> *)passesData success:(AddPassesResultBlock)successBlock error:(void (^)(NSError *error))errorBlock
{
    NSError *error = nil;
    NSMutableArray<PKPass *> *passes = [NSMutableArray arrayWithCapacity:[passesData count]];
    for (NSData* data in passesData) {
        PKPass *pass = [[PKPass alloc] initWithData:data error:&error];
        [passes addObject:pass];
        if(!pass) {
            if(errorBlock) {
                errorBlock(error);
            }
            return;
        }
    }
    
    self.lastPasses = passes;
    self.lastAddPassesCallback = successBlock;
    
    PKAddPassesViewController *c = [[PKAddPassesViewController alloc] initWithPasses:passes];
    c.delegate = self;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[self getTopMostViewController] presentViewController:c animated:YES completion:nil];
    });
}

- (UIViewController*) getTopMostViewController {
    UIViewController *presentingViewController = [[UIApplication sharedApplication] keyWindow].rootViewController;
    while (presentingViewController.presentedViewController != nil) {
        presentingViewController = presentingViewController.presentedViewController;
    }
    return presentingViewController;
}

- (void)downloadPass:(NSURL*) url headers:(NSDictionary * _Nullable)headers success:(AddPassResultBlock)successBlock error:(void (^)(NSError *error))errorBlock
{
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    if (headers) {
        configuration.HTTPAdditionalHeaders = [NSDictionary dictionaryWithDictionary: headers];
        [configuration.HTTPAdditionalHeaders setValue:PasskitAgentHeader forKey:UserAgentHeader];
    } else {
        configuration.HTTPAdditionalHeaders = @{
            UserAgentHeader: PasskitAgentHeader
        };
    }
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
    
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:20.0];
    NSURLSessionDataTask* task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError *error) {
        if (error) {
            if (errorBlock) {
                errorBlock(error);
            }
        } else {
            [self tryAddPass:data success:successBlock error:errorBlock];
        }
    }];
    
    [task resume];
}

- (void)downloadPasses:(NSArray<NSURL*> *)urls headers:(NSDictionary * _Nullable)headers success:(AddPassesResultBlock)successBlock error:(void (^)(NSError *error))errorBlock
{
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    if (headers) {
        configuration.HTTPAdditionalHeaders = [NSDictionary dictionaryWithDictionary: headers];
        [configuration.HTTPAdditionalHeaders setValue:PasskitAgentHeader forKey:UserAgentHeader];
    } else {
        configuration.HTTPAdditionalHeaders = @{
            UserAgentHeader: PasskitAgentHeader
        };
    }
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    queue.maxConcurrentOperationCount = 4;
    
    NSLock *arrayLock = [[NSLock alloc] init];
    NSMutableArray<NSData*> *passes = [NSMutableArray arrayWithCapacity:[urls count]];
    NSBlockOperation *completionOperation = [NSBlockOperation blockOperationWithBlock:^{
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self tryAddPasses:passes success: successBlock error:errorBlock];
        }];
    }];
    
    for (NSURL *url in urls) {
        NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
            NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:20.0];
            NSURLSessionDataTask* task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                if (error) {
                    if (errorBlock) {
                        errorBlock(error);
                    }
                    [queue cancelAllOperations];
                } else {
                    [arrayLock lock];
                    [passes addObject:data];
                    [arrayLock unlock];
                };
            }];
            [task resume];
        }];
        [completionOperation addDependency:operation];
    }
    [queue addOperations:completionOperation.dependencies waitUntilFinished:NO];
    [queue addOperation:completionOperation];
}

#pragma mark - PKAddPassesViewControllerDelegate

-(void)addPassesViewControllerDidFinish:(PKAddPassesViewController *)controller
{
    [controller dismissViewControllerAnimated:YES completion:^{
        if (self.lastAddPassCallback && self.lastPass) {
            BOOL passAdded = [[[PKPassLibrary alloc] init] containsPass:self.lastPass];
            self.lastAddPassCallback(self.lastPass, passAdded);
        } else if (self.lastAddPassesCallback && self.lastPasses) {
            BOOL passesAdded = [[[PKPassLibrary alloc] init] containsPass:self.lastPasses[0]];
            self.lastAddPassesCallback(self.lastPasses, passesAdded);
        }
        self.lastAddPassCallback = nil;
        self.lastAddPassesCallback = nil;
        self.lastPass = nil;
        self.lastPasses = nil;
    }];
}

# pragma mark - WKNavigationDelegate

- (void) webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    if (navigationAction.navigationType == WKNavigationTypeLinkActivated && PKPassLibrary.isPassLibraryAvailable && [navigationAction.request.URL.pathExtension isEqualToString:@"pkpass"]) {
        [self downloadPass:navigationAction.request.URL headers:nil success:nil error:nil];
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    
    if (self.navigationDelegate && [self.navigationDelegate respondsToSelector:@selector(webView:decidePolicyForNavigationAction:decisionHandler:)]) {
        [self.navigationDelegate webView:webView decidePolicyForNavigationAction:navigationAction decisionHandler:decisionHandler];
    } else {
        decisionHandler(WKNavigationActionPolicyAllow);
    }
}

- (void) webView:(WKWebView *)webView didCommitNavigation:(null_unspecified WKNavigation *)navigation
{
    if (self.navigationDelegate && [self.navigationDelegate respondsToSelector:@selector(webView:didCommitNavigation:)]) {
        [self.navigationDelegate webView:webView didCommitNavigation:navigation];
    }
}

- (void) webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    if (self.navigationDelegate && [self.navigationDelegate respondsToSelector:@selector(webView:didFinishNavigation:)]) {
        [self.navigationDelegate webView:webView didFinishNavigation:navigation];
    }
}

- (void) webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error
{
    if (self.navigationDelegate && [self.navigationDelegate respondsToSelector:@selector(webView:didFailNavigation:withError:)]) {
        [self.navigationDelegate webView:webView didFailNavigation:navigation withError:error];
    }
}

- (void) webViewWebContentProcessDidTerminate:(WKWebView *)webView
{
    if (self.navigationDelegate && [self.navigationDelegate respondsToSelector:@selector(webViewWebContentProcessDidTerminate:)]) {
        [self.navigationDelegate webViewWebContentProcessDidTerminate:webView];
    }
}

- (void) webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation
{
    if (self.navigationDelegate && [self.navigationDelegate respondsToSelector:@selector(webView:didStartProvisionalNavigation:)]) {
        [self.navigationDelegate webView:webView didStartProvisionalNavigation:navigation];
    }
}

- (void) webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error
{
    if (self.navigationDelegate && [self.navigationDelegate respondsToSelector:@selector(webView:didFailProvisionalNavigation:withError:)]) {
        [self.navigationDelegate webView:webView didFailProvisionalNavigation:navigation withError:error];
    }
}

- (void) webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(WKNavigation *)navigation
{
    if (self.navigationDelegate && [self.navigationDelegate respondsToSelector:@selector(webView:didReceiveServerRedirectForProvisionalNavigation:)]) {
        [self.navigationDelegate webView:webView didReceiveServerRedirectForProvisionalNavigation:navigation];
    }
}


@end

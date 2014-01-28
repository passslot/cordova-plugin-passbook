#import <Cordova/CDVPlugin.h>

@interface CDVPassbook : CDVPlugin

- (void)available:(CDVInvokedUrlCommand*)command;
- (void)downloadPass:(CDVInvokedUrlCommand*)command;

@end
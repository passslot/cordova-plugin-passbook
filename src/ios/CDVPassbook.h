#import <Cordova/CDVPlugin.h>
#import <PassKit/PassKit.h>


@interface CDVPassbook : CDVPlugin

@property(nonatomic, assign, nullable) id < PKAddPassesViewControllerDelegate > delegate;

- (void)available:(CDVInvokedUrlCommand*)command;
- (void)isPassInLibrary:(CDVInvokedUrlCommand*)command;
- (void)openPass:(CDVInvokedUrlCommand*)command;
- (void)downloadPass:(CDVInvokedUrlCommand*)command;
- (void)addPassesViewControllerDidFinish:(PKAddPassesViewController *)controller;
@end
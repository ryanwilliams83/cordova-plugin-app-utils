//
//  AppUtils.m
//
//  The MIT License
//
//  Copyright (c) 2014 Paul Cervenka
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this
//  software and associated documentation files (the "Software"), to deal in the Software
//  without restriction, including without limitation the rights to use, copy, modify, merge,
//  publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to
//  whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or
//  substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
//  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
//  IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
//  IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

#import "AppUtils.h"

@implementation AppUtils

@synthesize controller;

- (void)IdleTimer:(CDVInvokedUrlCommand *)command
{
    CDVPluginResult* pluginResult = nil;
    NSMutableDictionary *options = [command.arguments objectAtIndex:0];
    UIApplication* app = [UIApplication sharedApplication];
    NSString *action = [options objectForKey:@"action"];
    
    if ([action isEqualToString: @"enable"]) {
        if( [app isIdleTimerDisabled] ) {
            [app setIdleTimerDisabled:false];
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        } else {
            // Error 1 - IdleTimer already enabled
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                                                         [NSNumber numberWithInt:1], @"code",
                                                                                                         @"IdleTimer already enabled.", @"reason", nil]];
        }
    } else if ([action isEqualToString: @"disable"]) {
        if( ![app isIdleTimerDisabled] ) {
            [app setIdleTimerDisabled:true];
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        } else {
            // Error 1 - IdleTimer already disabled
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                                                         [NSNumber numberWithInt:1], @"code",
                                                                                                         @"IdleTimer already disabled.", @"reason", nil]];
        }
    } else if ([action isEqualToString: @"status"]) {
        if( [app isIdleTimerDisabled] ) {
            // disabled
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsInt:0];
        } else {
            // enabled
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsInt:1];
        }
    }

    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)BundleInfo:(CDVInvokedUrlCommand *)command
{
    [self.commandDelegate runInBackground:^{
        CDVPluginResult* pluginResult = nil;
        
        NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
                              [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"], @"bundleVersion",
                              [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"], @"bundleBuild",
                              [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"], @"bundleId",
                              [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"], @"bundleDisplayName",
                              [[NSLocale preferredLanguages] objectAtIndex:0], @"localeLanguage", nil];
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:info];
        
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

- (void)OpenWith:(CDVInvokedUrlCommand *)command
{

    NSMutableDictionary *options = [command.arguments objectAtIndex:0];
    CDVViewController* cont = (CDVViewController*)[ super viewController ];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

        NSString* url = [options objectForKey:@"url"];

        dispatch_async(dispatch_get_main_queue(), ^{
            
            CDVPluginResult* pluginResult = nil;

            // File-URL
            if (url != nil && url.length > 0) {
                
                NSURL* absoluteURL = [[NSURL URLWithString:url relativeToURL:[self.webView.request URL]] absoluteURL];
                
                if ([[NSFileManager defaultManager] fileExistsAtPath:absoluteURL.path]) {
                    NSLog(@"[openwith] url: %@", absoluteURL.path);
                    
                    self.controller = [UIDocumentInteractionController interactionControllerWithURL:absoluteURL];
                    
                    // rect coordinates from options
                    int left = [options objectForKey:@"left"] != nil ? [[options objectForKey:@"left"] intValue]: 0;
                    int top = [options objectForKey:@"top"] != nil ? [[options objectForKey:@"top"] intValue]: 0;
                    int width = [options objectForKey:@"width"] != nil ? [[options objectForKey:@"width"] intValue]: self.viewController.view.bounds.size.width;
                    int height = [options objectForKey:@"height"] != nil ? [[options objectForKey:@"height"] intValue]: self.viewController.view.bounds.size.height;
                    CGRect rect = CGRectMake(left, top, width, height);
                    NSLog(@"[openwith] rect: left %i, top:%i, width:%i, height:%i", left, top, width, height);

                    if ([controller presentOpenInMenuFromRect:rect inView:cont.view animated:YES]) {
                        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
                    } else {
                        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                                                                     [NSNumber numberWithInt:3], @"code",
                                                                                                                     @"Unknown filetype.", @"reason", nil]];
                    }

                } else {
                    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                                                                 [NSNumber numberWithInt:2], @"code",
                                                                                                                 @"File not found.", @"reason", nil]];
                }

            } else {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                                                             [NSNumber numberWithInt:1], @"code",
                                                                                                             @"Empty parameter.", @"reason", nil]];
            }

            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        });
    });
}

@end
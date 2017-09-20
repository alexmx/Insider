//
//  AppDelegate.m
//  InsiderDemo
//
//  Created by Alexandru Maimescu on 2/16/16.
//  Copyright © 2016 Alex Maimescu. All rights reserved.
//

#import "AppDelegate.h"

NSString * kLogMessageNotificationKey = @"com.alexmx.notificationLogMessage";

@import Insider;

@interface AppDelegate () <InsiderDelegate>

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(insiderNotification:) name:[Insider insiderNotificationKey] object:nil];
    
    [[Insider shared] startWithDelegate:self];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)postLogNotificationWithObject:(id)object
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kLogMessageNotificationKey object:object];
}

#pragma mark - InsiderDelegate

- (void)insider:(Insider *)insider didReceiveRemoteMessage:(NSDictionary * _Nullable)message
{
    NSLog(@"Insider invoke object: %@", message);
    [self postLogNotificationWithObject:message];
}

- (NSDictionary *)insider:(Insider *)insider returnResponseMessageForRemoteMessage:(NSDictionary * _Nullable)message
{
    [self postLogNotificationWithObject:message];
    
    return @{@"test": @YES};
}

- (void)insider:(Insider *)insider didSendNotificationWithMessage:(NSDictionary * _Nullable)message
{
    [self postLogNotificationWithObject:message];
}

- (void)insider:(Insider *)insider didReturnSystemInfo:(NSDictionary * _Nullable)systemInfo
{
    [self postLogNotificationWithObject:systemInfo];
}

- (void)insider:(Insider *)insider didCreateDirectoryAtPath:(NSString * _Nonnull)path
{
    [self postLogNotificationWithObject:[NSString stringWithFormat:@"Did create path: %@", path]];
}

- (void)insider:(Insider *)insider didDeleteItemAtPath:(NSString * _Nonnull)path
{
    [self postLogNotificationWithObject:[NSString stringWithFormat:@"Did delete item: %@", path]];
}

- (void)insider:(Insider *)insider didDownloadFileAtPath:(NSString * _Nonnull)path
{
    [self postLogNotificationWithObject:[NSString stringWithFormat:@"Did download item: %@", path]];
}

- (void)insider:(Insider *)insider didMoveItemFromPath:(NSString * _Nonnull)fromPath toPath:(NSString * _Nonnull)path
{
    [self postLogNotificationWithObject:[NSString stringWithFormat:@"Did move item from: %@ to: %@", fromPath, path]];
}

- (void)insider:(Insider *)insider didUploadFileAtPath:(NSString * _Nonnull)path
{
    [self postLogNotificationWithObject:[NSString stringWithFormat:@"Did upload item: %@", path]];
}

#pragma mark - Notification

- (void)insiderNotification:(NSNotification *)notification
{
    NSLog(@"Did recieve notification with params: %@", notification.object);
}

@end

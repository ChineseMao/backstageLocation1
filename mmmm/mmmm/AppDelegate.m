//
//  AppDelegate.m
//  mmmm
//
//  Created by 毛韶谦 on 16/5/19.
//  Copyright © 2016年 毛韶谦. All rights reserved.
//

#import "AppDelegate.h"
#import <CoreLocation/CoreLocation.h>
#import <AVFoundation/AVFoundation.h>

@interface AppDelegate ()<CLLocationManagerDelegate>

@property (strong, nonatomic)CLLocationManager *locationManager;   //
@property (assign, nonatomic)BOOL isLogation;      //判断是否定位
@property (assign, nonatomic) CGFloat deviceLevel; //记录电量
@property (strong, nonatomic) NSTimer *myTimer;   //定时器

@end

@implementation AppDelegate

#pragma mark --------懒加载----------

- (CLLocationManager *)locationManager {
    
    if (!_locationManager) {
        
        _locationManager = [[CLLocationManager alloc] init];
        //取得用户授权   不管应用是否在前台运行，都可以获取用户授权；
        [_locationManager requestAlwaysAuthorization];
        //定位服务，每隔多少米定位一次；
        _locationManager.distanceFilter = 100;
        //定位的精确度，越高越耗电
        _locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
        //指定代理
        _locationManager.delegate = self;
        _locationManager.pausesLocationUpdatesAutomatically = NO; //该模式是抵抗ios在后台杀死程序设置，iOS会根据当前手机使用状况会自动关闭某些应用程序的后台刷新，该语句申明不能够被暂停，但是不一定iOS系统在性能不佳的情况下强制结束应用刷新
    }
    return _locationManager;
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    //确保后台运行
    NSError *error1 = nil;
    NSError *error2 = nil;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&error1];
    [[AVAudioSession sharedInstance] setActive:YES error:&error2];
    self.isLogation = [CLLocationManager locationServicesEnabled];
    NSLog(@"%.2f",[self getCurrentBatteryLevel]);
    //是否可定位
    if (self.isLogation) {
        
         _myTimer =  [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(startLocation) userInfo:nil repeats:YES];
        [self.myTimer setFireDate:[NSDate distantFuture]];
        
    }else {
        NSLog(@"洗洗睡吧");
    }
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    
    [self.myTimer setFireDate:[NSDate distantFuture]];
    
    //开启不停歇定位
    UIApplication *app = [UIApplication sharedApplication];
    __block UIBackgroundTaskIdentifier identifier;
    identifier = [app beginBackgroundTaskWithExpirationHandler:^{
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (identifier != UIBackgroundTaskInvalid) {
                
                identifier = UIBackgroundTaskInvalid;
            }
        });
    }];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        dispatch_async(dispatch_get_main_queue(), ^{
           
            if (identifier != UIBackgroundTaskInvalid) {
                
                identifier = UIBackgroundTaskInvalid;
            }
        });
    });
    
    if (self.isLogation) {
        
        [self.myTimer setFireDate:[NSDate distantPast]];
    }else {
        NSLog(@"洗洗睡吧");
    }
    
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}

#pragma mark -------定时器代理方法------

- (void)startLocation {
    
    if ([self getCurrentBatteryLevel]>0.4f) {
        
        //开始定位
        [self.locationManager startUpdatingLocation];
//        [self.locationManager startMonitoringSignificantLocationChanges];
    }else {
        
        [self.myTimer invalidate];
        self.myTimer = nil;
    }
}

#pragma mark -------地图代理方法--------

//实时获取的定位信息    代理方法会被多次执行
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    
    if (locations.count) {
        //获取最新位置
        CLLocation *location = locations.lastObject;
        NSString *str = [NSString stringWithFormat:@"%.2f:%.2f",location.coordinate.latitude,location.coordinate.longitude];
        NSLog(@"%@",str);
        [self.locationManager stopUpdatingLocation];
    }
}
//定位失败
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error{
    
    if ([error code] == kCLErrorDenied) {
        
        NSLog(@"定位被拒绝");
    }
    if ([error code] == kCLErrorLocationUnknown) {
        
        NSLog(@"定位失败 = %@", error);
    }
}

#pragma mark -------判断电量------------

- (CGFloat)getCurrentBatteryLevel {
    
    [UIDevice currentDevice].batteryMonitoringEnabled = YES;
    return [UIDevice currentDevice].batteryLevel;
}
/*
 -(double)getCurrentBatteryLevel
 {
 if ([CLLocationManager significantLocationChangeMonitoringAvailable])
 {
 //        [[GlobalVariables locationManager] stopMonitoringSignificantLocationChanges];
 //        [[GlobalVariables locationManager] startUpdatingLocation];
 }
 else
 {
 NSLog(@"Significant location change monitoring is not available.");
 }
 //Returns a blob of Power Source information in an opaque CFTypeRef.
 CFTypeRef blob = IOPSCopyPowerSourcesInfo();
 
 //Returns a CFArray of Power Source handles, each of type CFTypeRef.
 CFArrayRef sources = IOPSCopyPowerSourcesList(blob);
 
 CFDictionaryRef pSource = NULL;
 const void *psValue;
 
 //Returns the number of values currently in an array.
 int numOfSources = CFArrayGetCount(sources);
 
 //Error in CFArrayGetCount
 if (numOfSources == 0)
 {
 NSLog(@"Error in CFArrayGetCount");
 return -1.0f;
 }
 
 //Calculating the remaining energy
 for (int i = 0 ; i < numOfSources ; i++)
 {
 //Returns a CFDictionary with readable information about the specific power source.
 pSource = IOPSGetPowerSourceDescription(blob, CFArrayGetValueAtIndex(sources, i));
 if (!pSource)
 {
 NSLog(@"Error in IOPSGetPowerSourceDescription");
 return -1.0f;
 }
 psValue = (CFStringRef)CFDictionaryGetValue(pSource, CFSTR(kIOPSNameKey));
 
 int curCapacity = 0;
 int maxCapacity = 0;
 double percent;
 
 psValue = CFDictionaryGetValue(pSource, CFSTR(kIOPSCurrentCapacityKey));
 CFNumberGetValue((CFNumberRef)psValue, kCFNumberSInt32Type, &curCapacity);
 
 psValue = CFDictionaryGetValue(pSource, CFSTR(kIOPSMaxCapacityKey));
 CFNumberGetValue((CFNumberRef)psValue, kCFNumberSInt32Type, &maxCapacity);
 
 percent = ((double)curCapacity/(double)maxCapacity * 100.0f);
 
 return percent;
 }
 return -1.0f;
 }
 */

#pragma mark - Core Data stack

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (NSURL *)applicationDocumentsDirectory {
    // The directory the application uses to store the Core Data store file. This code uses a directory named "com.maoshaoqian.mmmm" in the application's documents directory.
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSManagedObjectModel *)managedObjectModel {
    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"mmmm" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it.
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    // Create the coordinator and store
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"mmmm.sqlite"];
    NSError *error = nil;
    NSString *failureReason = @"There was an error creating or loading the application's saved data.";
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        // Report any error we got.
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
        dict[NSUnderlyingErrorKey] = error;
        error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        // Replace this with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}


- (NSManagedObjectContext *)managedObjectContext {
    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    return _managedObjectContext;
}

#pragma mark - Core Data Saving support

- (void)saveContext {
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        NSError *error = nil;
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

@end

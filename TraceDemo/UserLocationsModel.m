//
//  UserLocationsModel.m
//  TraceDemo
//
//  Created by Ben on 16/10/17.
//  Copyright © 2016年 Ben. All rights reserved.
//

#import "UserLocationsModel.h"






@interface UserLocationsModel ()



@end

@implementation UserLocationsModel


- (void)showInfo:(NSString*)s
{
    NSLog(@"%@", s);
    if(self.infoDisplay) {
        self.infoDisplay(s);
    }
}


- (double)addUserLocation:(BMKUserLocation *)userLocation
{
    CLLocation *location = [userLocation.location copy];
    
    if(self.userLocations.count == 0) {
        self.userLocations = [[NSMutableArray alloc] init];
        [self.userLocations addObject:location];
        [self showInfo:[NSString stringWithFormat:@"第一次定位. [%p]%lf, %lf", location, location.coordinate.latitude, location.coordinate.longitude]];
        return location.speed;
    }
    
    NSInteger count = self.userLocations.count + 1;
    
    CLLocation *userLocationFrom = [self.userLocations lastObject];
    NSLog(@"Prev : [%p]%lf, %lf", userLocationFrom, userLocationFrom.coordinate.latitude, userLocationFrom.coordinate.longitude);
    NSLog(@"To : [%p]%lf, %lf", userLocation, location.coordinate.latitude, location.coordinate.longitude);
    
    CLLocationDistance distance = [userLocationFrom distanceFromLocation:userLocation.location];
    NSTimeInterval dtime = [userLocation.location.timestamp timeIntervalSinceDate:userLocationFrom.timestamp];
    double speed = userLocation.location.speed;
    if(speed == -1) {
        speed = distance / dtime * 3.6;
        [self showInfo:[NSString stringWithFormat:@"[%zd]distance : %lf, interval : %lf, speed* : %lf", count, distance, dtime, speed]];
    }
    else {
        [self showInfo:[NSString stringWithFormat:@"[%zd]distance : %lf, interval : %lf, speed : %lf", count, distance, dtime, userLocation.location.speed]];
    }
    
    [self.userLocations addObject:location];
    
    if(self.couting) {
        self.totalDistance += distance;
        self.totalInterval += dtime;
        if(self.totalInterval > 1) {
            self.averageSpeed = self.totalDistance / self.totalInterval * 3.6;
        }
        
        if(self.traceInfoUse) {
            self.traceInfoUse(self.totalDistance, self.totalInterval, self.averageSpeed, self.userLocations.count, self.countFrom, self.countTo);
        }
        
    }
    
    NSLog(@"---count : %zd", self.userLocations.count);
    return speed;
}


- (void)traceStart
{
    self.couting = YES;
    self.countFrom = self.userLocations.count;
}


- (void)traceFinish
{
    self.couting = NO;
    self.countTo = self.userLocations.count - 1;
    
    if(self.totalInterval > 1) {
        self.averageSpeed = self.totalDistance / self.totalInterval * 3.6;
    }
    
    NSLog(@"total distance : %lf, total timeinterval : %lf, average speed : %lf",
          self.totalDistance,
          self.totalInterval,
          self.averageSpeed);
    
}



@end

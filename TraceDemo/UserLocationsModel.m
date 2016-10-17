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


- (void)addUserLocation:(BMKUserLocation *)userLocation
{
    if(!self.userLocations) {
        self.userLocations = [[NSMutableArray alloc] init];
    }
    
    [self.userLocations addObject:userLocation];
    
    if(self.couting && self.userLocations.count > 1) {
        BMKUserLocation *userLocationFrom = self.userLocations[self.userLocations.count - 2];
        BMKUserLocation *userLocationTo = self.userLocations[self.userLocations.count - 1];
        
        CLLocationDistance distance = [userLocationFrom.location distanceFromLocation:userLocationTo.location];
        NSLog(@"distance : %lf", distance);
        
        self.totalDistance += distance;
        
        NSTimeInterval dtime = [userLocationTo.location.timestamp timeIntervalSinceDate:userLocationFrom.location.timestamp];
        self.totalInterval += dtime;
    }
    
    NSLog(@"---count : %zd", self.userLocations.count);
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

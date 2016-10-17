//
//  UserLocationsModel.h
//  TraceDemo
//
//  Created by Ben on 16/10/17.
//  Copyright © 2016年 Ben. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PrefixHeader.pch"
@interface UserLocationsModel : NSObject





@property (nonatomic, strong) NSMutableArray *userLocations;

@property (nonatomic, assign) double totalDistance;
@property (nonatomic, assign) double totalInterval;
@property (nonatomic, assign) double averageSpeed;

@property (nonatomic, assign) BOOL couting;
@property (nonatomic, assign) NSInteger countFrom;
@property (nonatomic, assign) NSInteger countTo;

- (void)addUserLocation:(BMKUserLocation *)userLocation;
- (void)traceStart;
- (void)traceFinish;


@end




//定位点个数.
//trace点个数. 距离, 时间, 平均速度.
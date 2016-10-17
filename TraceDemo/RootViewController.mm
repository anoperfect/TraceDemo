//
//  ViewController.m
//  TraceDemo
//
//  Created by Ben on 16/10/17.
//  Copyright © 2016年 Ben. All rights reserved.
//

#import "RootViewController.h"
#import "PrefixHeader.pch"





@interface RootViewController () <BMKLocationServiceDelegate,BMKMapViewDelegate,BMKRouteSearchDelegate>
@property (nonatomic, strong) BMKMapView *mapView ;
@property (nonatomic, strong) BMKLocationService * locationService;
    
@property (nonatomic, strong) BMKRouteSearch *routeSearcher;

@property (nonatomic, strong)  BMKUserLocation *userLocationCurrent;
@property (nonatomic, strong)  BMKUserLocation *userLocationPrevious;
    
@end

@implementation RootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.title = @"Root";
    self.view.backgroundColor = [UIColor purpleColor];
    
    self.mapView = [[BMKMapView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height - 100)];
    [self.view addSubview:self.mapView];
    
    [self initBMLocationService];
    
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.mapView.delegate = self;
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.mapView.delegate = nil;
}


- (void)initBMLocationService
{
    BMKLocationViewDisplayParam *displayParam = [[BMKLocationViewDisplayParam alloc]init];
    displayParam.isRotateAngleValid = true;//跟随态旋转角度是否生效
    displayParam.isAccuracyCircleShow = false;//精度圈是否显示
    displayParam.locationViewOffsetX = 0;//定位偏移量(经度)
    displayParam.locationViewOffsetY = 0;//定位偏移量（纬度）
    [_mapView updateLocationViewWithParam:displayParam];
    
    self.locationService = [[BMKLocationService alloc] init];
    self.locationService.delegate = self;
    
    [self.locationService startUserLocationService];
}



- (void)didUpdateUserHeading:(BMKUserLocation *)userLocation
{
    
}


- (void)didUpdateBMKUserLocation:(BMKUserLocation *)userLocation
{
    CLLocationCoordinate2D coordinate = userLocation.location.coordinate;
    NSLog(@"经度:%lf,纬度:%lf,速度:%lf",coordinate.latitude,coordinate.longitude,
          userLocation.location.speed);
    
//    [BMKLocationService setLocationDesiredAccuracy:kCLLocationAccuracyNearestTenMeters];
//    [BMKLocationService setLocationDistanceFilter:10.0];
    
    _mapView.showsUserLocation = YES;//显示定位图层
    [_mapView updateLocationData:userLocation];
    
    //第一次定位成功后, 将地图更新到此位置.
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        BMKCoordinateRegion region ;//表示范围的结构体
        region.center = coordinate;//中心点
        region.span.latitudeDelta = 0.0001;//经度范围（设置为0.1表示显示范围为0.2的纬度范围）
        region.span.longitudeDelta = 0.001;//纬度范围
        [_mapView setRegion:region animated:YES];
    });
    
    self.userLocationPrevious = self.userLocationCurrent;
    self.userLocationCurrent = userLocation;
    
    //画轨迹线.
    [self drawPolyLine];
}


//连线的属性.
- (BMKOverlayView *) mapView:(BMKMapView *)mapView viewForOverlay:(id<BMKOverlay>)overlay
{
    if ([overlay isKindOfClass:[BMKPolyline class]]) {
        BMKPolylineView *polylineView = [[BMKPolylineView alloc]initWithOverlay:overlay];
        polylineView.strokeColor = [[UIColor purpleColor] colorWithAlphaComponent:0.5];
        polylineView.lineWidth = 6.0;
        return polylineView;
    }
    return nil;
}


//轨迹线的方法:
//1.直接连线坐标点. 可能显示出的轨迹线穿越覆盖物.
//2.使用DrivingRoutePlan. 需等待网络返回结果. 部分行驶不可达地区会不覆盖.
//3.使用WalkingRoutePlan. 需等待网络返回结果. 部分不可行走路线不确定是否会进入规划路线.
//暂时使用WalkingRoutePlan
- (void)drawPolyLine
{
    [self drawPolyLineByWalkingRoutePlan];
}


- (void)drawPolyLineByWalkingRoutePlan
{
    self.routeSearcher = [[BMKRouteSearch alloc] init];
    self.routeSearcher.delegate = self;
    
    CLLocationCoordinate2D from = self.userLocationPrevious.location.coordinate;
    CLLocationCoordinate2D to = self.userLocationCurrent.location.coordinate;
    
    BMKPlanNode *startNode = [[BMKPlanNode alloc]init];
    startNode.pt = from;
    BMKPlanNode *endNode = [[BMKPlanNode alloc]init];
    endNode.pt = to;
    BMKWalkingRoutePlanOption * walkingRoutePlanOption = [[BMKWalkingRoutePlanOption alloc]init];
    walkingRoutePlanOption.from = startNode;
    walkingRoutePlanOption.to = endNode;
    //结果于routeSearch的delegate - onGetWalkingRouteResult.
    if ([self.routeSearcher walkingSearch:walkingRoutePlanOption]) {
        NSLog(@"路线查找成功");
    }
    else {
        NSLog(@"线路查找失败");
    }
}


- (void)onGetWalkingRouteResult:(BMKRouteSearch *)searcher result:(BMKWalkingRouteResult *)result errorCode:(BMKSearchErrorCode)error
{
    BMKWalkingRouteLine *plan = (BMKWalkingRouteLine *)[result.routes objectAtIndex:0];
    int size = (int)[plan.steps count];
    int pointCount = 0;
    for (int i = 0; i< size; i++) {
        BMKWalkingStep *step = [plan.steps objectAtIndex:i];
        pointCount += step.pointsCount;
    }
    BMKMapPoint *points = new BMKMapPoint[pointCount];
    int k = 0;
    for (int i = 0; i< size; i++) {
        BMKWalkingStep *step = [plan.steps objectAtIndex:i];
        for (int j= 0; j<step.pointsCount; j++) {
            points[k].x = step.points[j].x;
            points[k].y = step.points[j].y;
            k++;
        }
    }
    
    NSLog(@"点的个数:(%d)",k);
    
    BMKPolyline *polyLine = [BMKPolyline polylineWithPoints:points count:pointCount];
    [_mapView addOverlay:polyLine];
}







- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

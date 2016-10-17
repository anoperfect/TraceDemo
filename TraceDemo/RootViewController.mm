//
//  ViewController.m
//  TraceDemo
//
//  Created by Ben on 16/10/17.
//  Copyright © 2016年 Ben. All rights reserved.
//

#import "RootViewController.h"
#import "PrefixHeader.pch"
#import "UserLocationsModel.h"
#import "UserLocationsView.h"



@interface RootViewController () <BMKGeneralDelegate,BMKLocationServiceDelegate,BMKMapViewDelegate,BMKRouteSearchDelegate,BMKDistrictSearchDelegate>
@property (nonatomic, strong) BMKMapManager *mapManager;
@property (nonatomic, strong) BMKMapView *mapView ;
@property (nonatomic, strong) BMKLocationService * locationService;

@property (nonatomic, strong) UITextView *infoLabel;
@property (nonatomic, strong) UserLocationsView *infoView;
@property (nonatomic, strong) UserLocationsModel *locationModel;


    
@property (nonatomic, strong) BMKRouteSearch *routeSearcher;

//@property (nonatomic, strong)  BMKUserLocation *userLocationCurrent;
//@property (nonatomic, strong)  BMKUserLocation *userLocationPrevious;
@property (nonatomic, strong)  CLLocation *locationCurrent;
@property (nonatomic, strong)  CLLocation *locationPrevious;

@property (nonatomic, strong) UIButton *buttonStart;
@property (nonatomic, strong) UIButton *buttonFinish;
    
@end

@implementation RootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.title = @"Root";
    self.view.backgroundColor = [UIColor purpleColor];
    
    self.mapView = [[BMKMapView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height - 180)];
    [self.view addSubview:self.mapView];
    
    [self initBMLocationService];
    
    [self testPolyLine];
    //[self testPolyLineDrawDirect];
    
    self.infoLabel = [[UITextView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - 180, self.view.bounds.size.width, 180)];
    self.infoLabel.editable = NO;
//    [self.view addSubview:self.infoLabel];
    
    
    self.infoView = [[UserLocationsView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - 180, self.view.bounds.size.width, 180)];
    [self.view addSubview:self.infoView];
    
    [self.infoView updateTraceInfo:@"未开始追踪"];
    [self.infoView appendTraceStepInfo:@"程序开始"];
    
    self.locationModel = [[UserLocationsModel alloc] init];
    
    self.buttonStart = [[UIButton alloc] initWithFrame:CGRectMake(0, 100, 36, 36)];
    [self.view addSubview:self.buttonStart];
    self.buttonStart.layer.cornerRadius = 18;
    [self.buttonStart setTitle:@"开始" forState:UIControlStateNormal];
    [self.buttonStart setBackgroundColor:[UIColor blueColor]];
    self.buttonStart.titleLabel.font = [UIFont systemFontOfSize:10];
    [self.buttonStart addTarget:self action:@selector(actionButton) forControlEvents:UIControlEventTouchDown];
    
    
    [self.locationModel traceStart];
    
    
    __weak typeof(self) _self = self;
    self.locationModel.infoDisplay = ^(NSString *s){
        [_self traceStepInfo:s];
    };
    
    self.locationModel.traceInfoUse = ^(double totalDistance, double totalInterval, double averageSpeed, BOOL count, NSInteger countFrom, NSInteger countTo) {
        [_self.infoView updateTraceInfo:[NSString stringWithFormat:@"总距:%.1lfm, 时间:%.1lfs, 均速:%.1lfkm/h",
                                         totalDistance,
                                         totalInterval,
                                         averageSpeed]];
    };
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


- (void)didUpdateBMKUserLocation:(BMKUserLocation *)userLocation
{
    //没有速度的时候, 自行计算速度.
    double speed = [self.locationModel addUserLocation:userLocation];
    
    static NSInteger knumber = 0;
    knumber ++;
    
    CLLocationCoordinate2D coordinate = userLocation.location.coordinate;
//    NSLog(@"[%zd]经度:%lf,纬度:%lf,速度:%lf",knumber,coordinate.latitude,coordinate.longitude,
//          userLocation.location.speed);
    
    [self traceStepInfo:[NSString stringWithFormat:@"定位[%zd]:经度:%lf,纬度:%lf,速度:%lf",
                                        self.locationModel.userLocations.count,
                                        coordinate.latitude,coordinate.longitude,
                                        speed]];
    
//    [BMKLocationService setLocationDesiredAccuracy:kCLLocationAccuracyNearestTenMeters];
//    [BMKLocationService setLocationDistanceFilter:10.0];
    
    _mapView.showsUserLocation = YES;//显示定位图层
    [_mapView updateLocationData:userLocation];
    
    //第一次定位成功后, 将地图更新到此位置.
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        BMKCoordinateRegion region ;//表示范围的结构体
        region.center = coordinate;//中心点
        region.span.latitudeDelta = 0.0036;//经度范围（设置为0.1表示显示范围为0.2的纬度范围）
        region.span.longitudeDelta = 0.0036;//纬度范围
        [_mapView setRegion:region animated:YES];
    });
    
    self.locationPrevious = self.locationCurrent;
    self.locationCurrent = [userLocation.location copy];
    
    //画轨迹线.
    if(self.locationPrevious) {
        [self drawPolyLine];
    }
    
    [self district];
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
{//return;
    self.routeSearcher = [[BMKRouteSearch alloc] init];
    self.routeSearcher.delegate = self;
    
    CLLocationCoordinate2D from = self.locationPrevious.coordinate;
    CLLocationCoordinate2D to = self.locationCurrent.coordinate;
    
    BMKPlanNode *startNode = [[BMKPlanNode alloc]init];
    startNode.pt = from;
    BMKPlanNode *endNode = [[BMKPlanNode alloc]init];
    endNode.pt = to;
    BMKWalkingRoutePlanOption * walkingRoutePlanOption = [[BMKWalkingRoutePlanOption alloc]init];
    walkingRoutePlanOption.from = startNode;
    walkingRoutePlanOption.to = endNode;
    //结果于routeSearch的delegate - onGetWalkingRouteResult.
    if ([self.routeSearcher walkingSearch:walkingRoutePlanOption]) {
        [self traceStepInfo:@"路线查找成功"];
    }
    else {
        [self traceStepInfo:@"路线查找失败"];
    }
}


- (void)traceStepInfo:(NSString*)infoString
{
    NSLog(@"%@", infoString);
    [self.infoView appendTraceStepInfo:infoString];
}


- (void)onGetWalkingRouteResult:(BMKRouteSearch *)searcher result:(BMKWalkingRouteResult *)result errorCode:(BMKSearchErrorCode)error
{
    if(error != BMK_SEARCH_NO_ERROR) {
        [self traceStepInfo:[NSString stringWithFormat:@"onGetWalkingRouteResult error : %zd", error]];
        return ;
    }
    
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
    
    [self traceStepInfo:[NSString stringWithFormat:@"点的个数:(%d)", k]];
    
    for(int i=0; i<k; i++) {
        [self traceStepInfo:[NSString stringWithFormat:@"x:%.1lf, y:%.1lf", points[i].x, points[i].y]];
    }
    
    BMKPolyline *polyLine = [BMKPolyline polylineWithPoints:points count:pointCount];
    [_mapView addOverlay:polyLine];
}



- (void)testPolyLine
{
    CLLocationCoordinate2D startCoordinate;
    startCoordinate.latitude =22.568729;
    startCoordinate.longitude =113.911660;
    
    CLLocationCoordinate2D endCoordnate;
    endCoordnate.latitude =22.567778;
    endCoordnate.longitude =113.912578;
    
    BMKRouteSearch *_searcher = [[BMKRouteSearch alloc]init];
    _searcher.delegate = self;
    
    
    BMKPlanNode *startNode = [[BMKPlanNode alloc]init];
    startNode.pt = startCoordinate;
    BMKPlanNode *endNode = [[BMKPlanNode alloc]init];
    endNode.pt = endCoordnate;
    
    BMKDrivingRoutePlanOption * drivingRoutePlanOption = [[BMKDrivingRoutePlanOption alloc]init];
    drivingRoutePlanOption.from = startNode;
    drivingRoutePlanOption.to = endNode;
    
    if ([_searcher drivingSearch:drivingRoutePlanOption]) {
        NSLog(@"测试线路路线查找成功");
    }
    else {
        NSLog(@"测试线路路线查找失败");
    }
}


- (void)onGetDrivingRouteResult:(BMKRouteSearch *)searcher result:(BMKDrivingRouteResult *)result errorCode:(BMKSearchErrorCode)error
{
    BMKDrivingRouteLine *plan = (BMKDrivingRouteLine *)[result.routes objectAtIndex:0];
    int size = (int)[plan.steps count];
    int pointCount = 0;
    for (int i = 0; i< size; i++) {
        BMKDrivingStep *step = [plan.steps objectAtIndex:i];
        pointCount += step.pointsCount;
    }
    BMKMapPoint *points = new BMKMapPoint[pointCount];
    int k = 0;
    for (int i = 0; i< size; i++) {
        BMKDrivingStep *step = [plan.steps objectAtIndex:i];
        for (int j= 0; j<step.pointsCount; j++) {
            points[k].x = step.points[j].x;
            points[k].y = step.points[j].y;
            k++;
        }
    }
    NSLog(@"测试点的个数:(%d)",k);
    BMKPolyline *polyLine = [BMKPolyline polylineWithPoints:points count:pointCount];
    [_mapView addOverlay:polyLine];
}


- (void)testPolyLineDrawDirect
{
    
}


- (void)actionButton
{
    
}


- (void)district
{
    //初始化检索对象
    BMKDistrictSearch *_districtSearch = [[BMKDistrictSearch alloc] init];
    //设置delegate，用于接收检索结果
    _districtSearch.delegate = self;
    //构造行政区域检索信息类
    BMKDistrictSearchOption *option = [[BMKDistrictSearchOption alloc] init];
    option.city = @"深圳";
    option.district = @"南山";
    //发起检索
    BOOL flag = [_districtSearch districtSearch:option];
    if (flag) {
        [self traceStepInfo:@"---district检索发送成功"];
    } else {
        [self traceStepInfo:@"---district检索发送失败"];
    }
}


- (void)onGetDistrictResult:(BMKDistrictSearch *)searcher result:(BMKDistrictResult *)result errorCode:(BMKSearchErrorCode)error {
    [self traceStepInfo:[NSString stringWithFormat:@"onGetDistrictResult error: %d", error]];
    if (error == BMK_SEARCH_NO_ERROR) {
        [self traceStepInfo:@"--- 判断区域 : PASS"];
    }
    else {
        [self traceStepInfo:[NSString stringWithFormat:@"--- 判断区域 : FAILED. %d", error]];
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end


#if 0
- (void)testPolyLineDrawDirect
{
    CLLocationCoordinate2D startCoordinate;
    startCoordinate.latitude =22.568729;
    startCoordinate.longitude =113.911660;
    
    CLLocationCoordinate2D endCoordnate;
    endCoordnate.latitude =22.567778;
    endCoordnate.longitude =113.912578;
    
    BMKMapPoint *tempPoints = new BMKMapPoint[2];
    tempPoints[0] = BMKMapPointForCoordinate(startCoordinate);
    tempPoints[1] = BMKMapPointForCoordinate(endCoordnate);
    
    NSLog(@"0 - x:%lf, y:%lf", tempPoints[0].x, tempPoints[0].y);
    NSLog(@"1 - x:%lf, y:%lf", tempPoints[1].x, tempPoints[1].y);
    
    BMKPolyline *polyLine = [BMKPolyline polylineWithPoints:tempPoints count:2];
    if(polyLine) {
        [self.mapView addOverlay:polyLine];
    }
    
    delete [] tempPoints;
}


- (void)actionButton
{
    if([self.buttonStart.titleLabel.text isEqualToString:@"开始"]) {
        [self.buttonStart setTitle:@"结束" forState:UIControlStateNormal];
        [self traceStepInfo:@"开始纪录"];
    }
    else {
        [self.buttonStart setTitle:@"开始" forState:UIControlStateNormal];
        [self traceStepInfo:@"结束纪录"];
    }
}
#endif
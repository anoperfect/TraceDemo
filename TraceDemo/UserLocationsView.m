//
//  UserLocationsView.m
//  TraceDemo
//
//  Created by Ben on 16/10/17.
//  Copyright © 2016年 Ben. All rights reserved.
//

#import "UserLocationsView.h"






@interface UserLocationsView ()

@property (nonatomic, strong) UILabel *traceInfoLabel;
@property (nonatomic, strong) UITextView *traceStepInfoText;


@end





@implementation UserLocationsView


- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self) {
        CGFloat heightTraceInfoLabel = 36;
        self.traceInfoLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, heightTraceInfoLabel)];
        [self addSubview:self.traceInfoLabel];
        self.traceInfoLabel.font = [UIFont systemFontOfSize:12];
        self.traceInfoLabel.backgroundColor = [UIColor colorWithRed:0xe1 green:0xea blue:0xeb alpha:1.0];
        
        self.traceStepInfoText = [[UITextView alloc] initWithFrame:CGRectMake(0, heightTraceInfoLabel, frame.size.width, frame.size.height - heightTraceInfoLabel)];
        self.traceStepInfoText.editable = NO;
        [self addSubview:self.traceStepInfoText];
    }
    
    return self;
}


- (void)updateTraceInfo:(NSString*)infoString
{
    self.traceInfoLabel.text = infoString;
}




- (void)appendTraceStepInfo:(NSString*)stepInfoString
{
    self.traceStepInfoText.text = [self.traceStepInfoText.text stringByAppendingFormat:@"%@\n",stepInfoString];
}








/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end

//
//  personInfoView.m
//  MedicalCase
//
//  Created by GK on 15/4/28.
//  Copyright (c) 2015年 ihefe. All rights reserved.
//

#import "personInfoView.h"

#define viewheight  45 + 8
@interface personInfoView()
@property (nonatomic,strong) NSMutableArray *labelArray;
@end
@implementation personInfoView

-(id)initWithCoder:(NSCoder *)aDecoder
{
   self = [super initWithCoder:aDecoder];
    if (self) {
        [self addSubViewToCurrentView];
    }
    return self;
}
-(instancetype)initWithFrame:(CGRect)frame
{
   self =  [super initWithFrame:frame];
    
    if (self) {
        [self addSubViewToCurrentView];
    }
    return self;
}

-(NSMutableArray *)labelArray
{
    if (!_labelArray) {
        _labelArray = [[NSMutableArray alloc] init];
    }
    return _labelArray;
}
-(void)addSubViewToCurrentView
{
    CGFloat subWidth = self.frame.size.width/6.0;
    
    for (int i=0; i<6; i++){
        UILabel  *label = [[UILabel alloc] init];
        label.frame = CGRectMake(i*subWidth, 8, subWidth, 29);
        label.textAlignment = NSTextAlignmentLeft;
        [self.labelArray addObject:label];
        label.backgroundColor = [self randomColor];
        [self addSubview:label];
    }
    
    UIView *secondView = [[UIView alloc] initWithFrame:CGRectMake(0, viewheight, self.frame.size.width, 98)];
    secondView.backgroundColor = [UIColor darkTextColor];
    [self addSubview:secondView];
    for (int i=0; i<6; i++){
        UILabel  *label = [[UILabel alloc] init];
        label.frame = CGRectMake(i*subWidth, 8, subWidth, 29);
        label.textAlignment = NSTextAlignmentLeft;
        [self.labelArray addObject:label];
        label.backgroundColor = [self randomColor];
        [secondView addSubview:label];
    }
}
-(void)layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat subWidth = self.frame.size.width/6.0;

    for (UILabel *label in self.labelArray) {
        NSInteger index = [self.labelArray indexOfObject:label];
        if (index < 6) {
            label.frame = CGRectMake(index*subWidth, 8, subWidth, 29);
        }else if (index < 12) {
            label.frame = CGRectMake((index-6)*subWidth, 0, subWidth, 29);
        }else {
            label.frame = CGRectMake((index-12)*subWidth, 45, subWidth, 29);
        }
    }
}

-(UIColor*)randomColor
{
    NSArray *colorArray =  @[[UIColor blackColor],[UIColor redColor],[UIColor yellowColor],[UIColor grayColor],[UIColor greenColor],[UIColor orangeColor]];
    
    NSInteger i = arc4random() % 6;
    
    return (UIColor*)colorArray[i];
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end

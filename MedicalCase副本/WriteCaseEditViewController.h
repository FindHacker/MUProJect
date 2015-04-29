//
//  WriteCaseEditViewController.h
//  MedicalCase
//
//  Created by ihefe-JF on 15/4/29.
//  Copyright (c) 2015年 ihefe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WLKMultiTableView.h"

@protocol WriteCaseEditViewControllerDelegate <NSObject>

@required
-(void)didWriteStringToMedicalRecord:(NSString*)writeString;
@end

@interface WriteCaseEditViewController : UIViewController
@property (strong,nonatomic) NSString *labelString;
@property (weak, nonatomic) IBOutlet WLKMultiTableView *multiTableView;

@property (nonatomic,weak) id <WriteCaseEditViewControllerDelegate> WriteDelegate;
@property (nonatomic,strong) UIView *rightSideSlideView;

@property (nonatomic) BOOL  rightSlideViewFlag;

@end

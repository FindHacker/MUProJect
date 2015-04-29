//
//  GetTemplateViewController.h
//  MedicalCase
//
//  Created by ihefe-JF on 15/4/29.
//  Copyright (c) 2015年 ihefe. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol GetTemplateViewControllerDelegate <NSObject>
-(void)didSelectedTemplateWithNode:(Template*)templated;;

@end

@interface GetTemplateViewController : UIViewController
@property (nonatomic,strong) NSString *templateName;

@property (nonatomic,weak) id <GetTemplateViewControllerDelegate> delegate;

@end

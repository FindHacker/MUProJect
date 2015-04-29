//
//  WriteCaseViewController.m
//  MedicalCase
//
//  Created by ihefe-JF on 15/4/28.
//  Copyright (c) 2015年 ihefe. All rights reserved.
//

#import "WriteCaseViewController.h"
#import "AutoHeightTextView.h"

@interface WriteCaseViewController ()<UITextViewDelegate>
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *personInfoHeightConstraints;
@property (weak, nonatomic) IBOutlet UIView *personInfoView;
@property (weak, nonatomic) IBOutlet UIView *personInfoPartialView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *personInfoPartialViewHeightConstraints;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet AutoHeightTextView *textView;

@end

@implementation WriteCaseViewController
- (IBAction)personInfoHideOrShow:(UIButton *)sender
{
    
}
- (IBAction)switchClicked:(UISwitch *)sender
{
    
}
- (IBAction)saveButton:(UIButton *)sender
{
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end

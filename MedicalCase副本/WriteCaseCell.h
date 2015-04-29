//
//  WriteCaseCell.h
//  MedicalCase
//
//  Created by ihefe-JF on 15/4/29.
//  Copyright (c) 2015年 ihefe. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol WriteCaseCellDelegate;

@interface WriteCaseCell : UITableViewCell<UITextViewDelegate>
@property (weak, nonatomic) IBOutlet UITextView *textView;

@property (weak,nonatomic) id <WriteCaseCellDelegate> delegate;
@end

@protocol WriteCaseCellDelegate
@required
-(void)textViewCell:(WriteCaseCell*)cell didChangeText:(NSString*)text;
-(void)textViewDidBeginEditing:(UITextView*)textView withCellIndexPath:(NSIndexPath*)indexPath;

@end

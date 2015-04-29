//
//  WriteCaseCell.m
//  MedicalCase
//
//  Created by ihefe-JF on 15/4/29.
//  Copyright (c) 2015年 ihefe. All rights reserved.
//

#import "WriteCaseCell.h"

@implementation WriteCaseCell

- (void)awakeFromNib {
    // Initialization code
}
-(void)layoutSubviews
{
    [super layoutSubviews];
    
    [self.contentView layoutIfNeeded];
    
    self.textView.delegate = self;
    self.textView.userInteractionEnabled = NO;
}

-(void)textViewDidChange:(UITextView *)textView
{
    [self.delegate textViewCell:self didChangeText:textView.text];
    CGRect bounds = textView.bounds;
    
    CGSize maxSize = CGSizeMake(bounds.size.width, CGFLOAT_MAX);
    CGSize newSize = [textView sizeThatFits:maxSize];
    
    if (newSize.width < bounds.size.width) {
        newSize.width = bounds.size.width;
    }
    if (newSize.height < bounds.size.height) {
        newSize.height = bounds.size.height;
    }
    bounds.size = newSize;
    
    textView.bounds = bounds;
    
    UITableView *tableView = [self tableView];
    [tableView beginUpdates];
    [tableView endUpdates];
    
}
-(void)textViewDidBeginEditing:(UITextView *)textView
{
    
    
}
-(BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    NSIndexPath *indexPath = [[self tableView] indexPathForCell:self];
    [self.delegate textViewDidBeginEditing:textView withCellIndexPath:indexPath];
    
    return YES;
}

-(UITableView*)tableView
{
    UIView *tableView = self.superview;
    
    while (![tableView isKindOfClass:[UITableView class]]) {
        tableView = tableView.superview;
    }
    
    return (UITableView*)tableView;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end

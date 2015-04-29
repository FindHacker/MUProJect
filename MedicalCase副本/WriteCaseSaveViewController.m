//
//  WriteCaseSaveViewController.m
//  MedicalCase
//
//  Created by ihefe-JF on 15/4/29.
//  Copyright (c) 2015年 ihefe. All rights reserved.
//

#import "WriteCaseSaveViewController.h"
#import "CoreDataStack.h"
#import "AdmissionRecordCell.h"
#import "WriteCaseEditViewController.m"
#import "WriteCaseCell.h"

@interface WriteCaseSaveViewController ()<NSFetchedResultsControllerDelegate,AdmissionRecordCellDelegate,UITableViewDelegate,UITableViewDataSource,WriteCaseEditViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UILabel *remainTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *currentDateLabel;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic,strong) CoreDataStack *coreDataStack;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@property (nonatomic,strong) NSFetchedResultsController *fetchResultController;

@property (nonatomic,strong) NSString *selectedStr;


@property (nonatomic,strong) UITextView *currentTextView;
@property (nonatomic,strong) NSIndexPath *currentIndexPath;

@property (nonatomic) BOOL keyboardShow;
@property (nonatomic) CGFloat keyboardOverlap;

@end

@implementation WriteCaseSaveViewController

- (IBAction)rightUpButon:(UIButton *)sender
{
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setUpTableView];
   // [self addKeyboardObserver];
    
    [self setUpFetchViewController];

    [self addKeyboardObserver];
}
-(NSManagedObjectContext *)managedObjectContext
{
    return self.coreDataStack.managedObjectContext;
}
-(CoreDataStack *)coreDataStack
{
    _coreDataStack = [[CoreDataStack alloc] init];
    return _coreDataStack;
}

-(void)setUpTableView
{
    self.tableView.layer.shadowOffset = CGSizeMake(15, 13);
    self.tableView.layer.shadowOpacity = 1;
    self.tableView.layer.shadowRadius = 20;
    self.tableView.layer.shadowColor = [UIColor darkGrayColor].CGColor;
    
    self.tableView.layer.borderWidth = 1;
    //self.tableView.layer.borderColor = [UIColor darkGrayColor].CGColor;
    self.tableView.estimatedRowHeight = 55;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
}

-(void)setUpFetchViewController
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:[Node entityName]];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"parentNode.nodeName = %@",@"入院记录"];
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"nodeIndex" ascending:YES];
    //  NSSortDescriptor *sortDescriptor = nil;
    fetchRequest.predicate = predicate;
    fetchRequest.sortDescriptors = @[sortDescriptor];
    
    self.fetchResultController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.coreDataStack.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
    self.fetchResultController.delegate = self;
    NSError *error = nil;
    if (![self.fetchResultController performFetch:&error]) {
        NSLog(@"error: %@",error.description);
        abort();
    }else {
        // Template *template = [self.fetchResultController objectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
        // NSLog(@"template condition : %@",template.condition);
        [self.tableView reloadData];
        
    }
    
}
-(void)setRecordCase:(RecordBaseInfo *)recordCase
{
    _recordCase = recordCase;
    
    ////
    if (recordCase.caseContent == nil) {
        recordCase.caseContent = @"";
    }
    NSDictionary *dic =[self convertJSONDataToList:[self convertStringToJSONData:_recordCase.caseContent]];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"nodeName = %@",@"入院记录"];
    //NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"nodeIndex" ascending:YES];
    
    NSArray *resultA = [self.coreDataStack fetchNSManagedObjectEntityWithName:[ParentNode entityName] withNSPredicate:predicate setUpFetchRequestResultType:0 isSetUpResultType:NO setUpFetchRequestSortDescriptors:nil isSetupSortDescriptors:NO];
    if (resultA.count == 1) {
        ParentNode *parentNode = (ParentNode*)[resultA firstObject];
        for (Node *node in parentNode.nodes.array) {
            node.nodeContent = [dic objectForKey:node.nodeName];
        }
        [self.coreDataStack saveContext];
    }else {
        abort();
    }
    
}
#pragma mask - parase to json data
-(NSData*)convertToJSONDataFromList:(id)listData
{
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:listData options:NSJSONWritingPrettyPrinted error:&error];
    if ([jsonData length] > 0 && error == nil) {
        return jsonData;
    }else {
        return nil;
    }
}
-(NSString*)convertJSONDataToString:(NSData*)jsonData
{
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}
#pragma mask - parse to list
-(NSData*)convertStringToJSONData:(NSString*)jsonString
{
    return [jsonString dataUsingEncoding:NSUTF8StringEncoding];
}
-(id)convertJSONDataToList:(NSData*)jsonData
{
    NSError *error = nil;
    id list = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments error:&error];
    if (list != nil && error == nil) {
        return list;
    }else {
        NSLog(@"parse error");
    }
    return nil;
}

#pragma mask - table view delegate && data source
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSLog(@"section count %@", @(self.fetchResultController.sections.count));
    return self.fetchResultController.sections.count ;
    
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // return self.dataArray.count;
    id <NSFetchedResultsSectionInfo> sectionInfo = self.fetchResultController.sections[section];
    
    return [sectionInfo numberOfObjects];
    
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    WriteCaseCell *cell = [tableView dequeueReusableCellWithIdentifier:@"writeCaseCell"];
    cell.autoresizesSubviews = NO;
    [self configureCell:cell AtIndexPath:indexPath];
    
    return cell;
}


-(void)configureCell:(WriteCaseCell*)cell AtIndexPath:(NSIndexPath*)indexPath
{
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    Node *tempNode = [self.fetchResultController objectAtIndexPath:indexPath];
   // cell.textViewDelegate = self;
    UILabel *cellLabel = (UILabel*)[cell viewWithTag:1001];
    UITextView *textView = (UITextView*)[cell viewWithTag:1002];
        
    cellLabel.text = tempNode.nodeName;
    textView.text = ([tempNode.nodeContent isEqualToString:tempNode.nodeName]) ? @" ": tempNode.nodeContent;
    [textView layoutIfNeeded];
    //    if(indexPath.row == 0) {
    //        cellLabel.text = @"主诉";
    //      //  textView.text = [self.dataArray objectAtIndex:indexPath.row];
    //        textView.text = tempNode.nodeName
    //    }else {
    //        cellLabel.text = @"现病史";
    //        textView.text = [self.dataArray objectAtIndex:indexPath.row];
    //    }
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    WriteCaseCell *cell =(WriteCaseCell*) [tableView cellForRowAtIndexPath:indexPath];
    UILabel *label =(UILabel*) [cell viewWithTag:1001];
    self.selectedStr = label.text;
    
    self.currentIndexPath = indexPath;
    [self performSegueWithIdentifier:@"ToWirteMedicalCaseSegue" sender:nil];
}
#pragma mask - AdmissionRecordCell  delegate
-(void)textViewCell:(WriteCaseCell *)cell didChangeText:(NSString *)text
{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    
    Node *tempNode = [self.fetchResultController objectAtIndexPath:indexPath];
    tempNode.nodeContent = text;
    [self.coreDataStack saveContext];
    //    NSMutableArray *data = [self.dataArray mutableCopy];
    //    data[indexPath.row]  = text;
    //    self.dataArray = [data copy];
}
-(void)textViewDidBeginEditing:(UITextView *)textView withCellIndexPath:(NSIndexPath *)indexPath
{
    self.currentIndexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section];
    self.currentTextView = textView;
}



-(void)addKeyboardObserver
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}
-(void)keyboardWillShow:(NSNotification*)notificationInfo
{
    if (self.keyboardShow) {
        return;
    }
    self.keyboardShow = YES;
    // Get the keyboard size
    UIScrollView *tableView;
    if([self.tableView.superview isKindOfClass:[UIScrollView class]])
        tableView = (UIScrollView *)self.tableView.superview;
    else
        tableView = self.tableView;
    
    NSDictionary *userInfo = [notificationInfo userInfo];
    NSValue *aValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    
    //[self.delegate keyboardShow:[aValue CGRectValue].size.height];
    CGRect keyboardRect = [tableView.superview convertRect:[aValue CGRectValue] fromView:nil];
    
    
    // [self.delegate keyboardShow:keyboardRect.size.height];
    // Get the keyboard's animation details
    NSTimeInterval animationDuration;
    [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
    UIViewAnimationCurve animationCurve;
    [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
    
    // Determine how much overlap exists between tableView and the keyboard
    CGRect tableFrame = tableView.frame;
    CGFloat tableLowerYCoord = tableFrame.origin.y + tableFrame.size.height;
    self.keyboardOverlap = tableLowerYCoord - keyboardRect.origin.y;
    if(self.currentTextView && self.keyboardOverlap>0)
    {
        CGFloat accessoryHeight = self.currentTextView.frame.size.height;
        self.keyboardOverlap -= accessoryHeight;
        
        tableView.contentInset = UIEdgeInsetsMake(0, 0, accessoryHeight, 0);
        tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, accessoryHeight, 0);
    }
    
    if(self.keyboardOverlap < 0)
        self.keyboardOverlap = 0;
    
    if(self.keyboardOverlap != 0)
    {
        tableFrame.size.height -= self.keyboardOverlap;
        
        NSTimeInterval delay = 0;
        if(keyboardRect.size.height)
        {
            delay = (1 - self.keyboardOverlap/keyboardRect.size.height)*animationDuration;
            animationDuration = animationDuration * self.keyboardOverlap/keyboardRect.size.height;
        }
        
        [UIView animateWithDuration:animationDuration delay:delay
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{ tableView.frame = tableFrame; }
                         completion:^(BOOL finished){ [self tableAnimationEnded:nil finished:nil contextInfo:nil]; }];
    }
    
}
-(void)keyboardWillHide:(NSNotification*)notificationInfo
{
    
    [self.coreDataStack saveContext];
    
    self.keyboardShow = NO;
    
    UIScrollView *tableView;
    if([self.tableView.superview isKindOfClass:[UIScrollView class]])
        tableView = (UIScrollView *)self.tableView.superview;
    else
        tableView = self.tableView;
    if(self.currentTextView)
    {
        tableView.contentInset = UIEdgeInsetsZero;
        tableView.scrollIndicatorInsets = UIEdgeInsetsZero;
    }
    
    if(self.keyboardOverlap == 0)
        return;
    
    // Get the size & animation details of the keyboard
    NSDictionary *userInfo = [notificationInfo userInfo];
    NSValue *aValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardRect = [tableView.superview convertRect:[aValue CGRectValue] fromView:nil];
    
    NSTimeInterval animationDuration;
    [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
    UIViewAnimationCurve animationCurve;
    [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
    
    CGRect tableFrame = tableView.frame;
    tableFrame.size.height += self.keyboardOverlap;
    
    //  tableFrame.size = CGSizeMake(678, 497);
    if(keyboardRect.size.height)
        animationDuration = animationDuration * self.keyboardOverlap/keyboardRect.size.height;
    
    [UIView animateWithDuration:animationDuration delay:0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{ tableView.frame = tableFrame; }
                     completion:^(BOOL finished){ [self tableAnimationEnded:nil finished:nil contextInfo:nil]; }];
    
    
}
- (void) tableAnimationEnded:(NSString*)animationID finished:(NSNumber *)finished contextInfo:(void *)context
{
    // Scroll to the active cell
    UITableView *tableView = self.tableView;
    if(self.currentIndexPath)
    {
        [tableView scrollToRowAtIndexPath:self.currentIndexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        [tableView selectRowAtIndexPath:self.currentIndexPath animated:NO scrollPosition:UITableViewScrollPositionBottom];
    }
}
#pragma mask - fetch view controller delegate
/// fetch result controller delegate
-(void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView beginUpdates];
}
-(void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
    switch (type) {
        case NSFetchedResultsChangeInsert:{
            [self.tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        }
        case NSFetchedResultsChangeDelete:{
            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        }
        case NSFetchedResultsChangeUpdate:{
            BOOL pop =  [[NSUserDefaults standardUserDefaults] boolForKey:@"referenceTemplateString"];
            if (pop) {
                AdmissionRecordCell *cell =(AdmissionRecordCell*) [self.tableView cellForRowAtIndexPath:indexPath];
                [self configureCell:cell AtIndexPath:indexPath];
                [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"referenceTemplateString"];
            }
        }
            
        default:
            break;
    }
}
-(void)controller:(NSFetchedResultsController *)controller didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:sectionIndex];
    switch (type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        default:
            break;
    }
}
-(void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
}


-(void)removeKeyboardObserver
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
-(void)dealloc
{
    [self removeKeyboardObserver];
}

#pragma mask - write delegate
-(void)didWriteStringToMedicalRecord:(NSString *)writeString
{
    Node *tempNode = [self.fetchResultController objectAtIndexPath:self.currentIndexPath];
    tempNode.nodeContent = writeString;
    [self.coreDataStack saveContext];
    
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString:@"EditCaseSegue"]) {
        WriteCaseEditViewController *writeMedicalVC = (WriteCaseEditViewController*)segue.destinationViewController;
        writeMedicalVC.labelString = self.selectedStr;
        writeMedicalVC.WriteDelegate = self;
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"referenceTemplateString"];

    }
    
}

@end

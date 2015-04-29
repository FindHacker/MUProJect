//
//  AdmissionRecordsViewController.m
//  MedicalCase
//
//  Created by ihefe-JF on 15/4/1.
//  Copyright (c) 2015年 ihefe. All rights reserved.
//

#import "AdmissionRecordsViewController.h"
#import "AdmissionRecordCell.h"
#import "ShowTemplateViewControllerTwo.h"
#import "Constants.h"
#import "CoreDataStack.h"
#import "ParentNode.h"
#import "Node.h"
#import "Template.h"
#import "WriteMedicalRecordVCViewController.h"
#import "Patient.h"
#import "IHMsgSocket.h"
#import "MessageObject+DY.h"

@interface AdmissionRecordsViewController () <UITableViewDataSource,UITableViewDelegate,AdmissionRecordCellDelegate,WriteMedicalRecordVCViewControllerDelegate,ShowTemplateViewControllerTwo,NSFetchedResultsControllerDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tabelView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *genderLabel;
@property (weak, nonatomic) IBOutlet UILabel *ageLable;
@property (weak, nonatomic) IBOutlet UILabel *departmentLabel;
@property (weak, nonatomic) IBOutlet UILabel *admissionNumberLabel;
@property (weak, nonatomic) IBOutlet UILabel *bedNLabel;
@property (weak, nonatomic) IBOutlet UIView *myPersonInfoView;

@property (nonatomic,strong) CoreDataStack *coreDataStack;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@property (nonatomic,strong) NSMutableArray *dataArray;
@property (nonatomic) CGFloat keyboardOverlap;
@property (nonatomic,strong) NSIndexPath *currentIndexPath;
@property (nonatomic,strong) UITextView *currentTextView;

@property (nonatomic) BOOL keyboardShow;

@property (nonatomic,strong) NSString *selectedStr;

@property (nonatomic,strong) NSFetchedResultsController *fetchResultController;
@property (nonatomic,strong) IHMsgSocket *socket;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *personInfoHeight;
@property (weak, nonatomic) IBOutlet UIView *personInfoView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *showViewConstant;
@property (weak, nonatomic) IBOutlet UIView *showView;

@property (nonatomic) BOOL isShowPersonInfoView;
@end

@implementation AdmissionRecordsViewController
- (IBAction)myButton:(UIButton *)sender {
    
    if (self.personInfoHeight.constant > 88) {
        self.personInfoHeight.constant = 40;
        self.showViewConstant.constant = 0;
        self.isShowPersonInfoView = NO;
        self.showView.hidden = YES;

    }else {
        self.personInfoHeight.constant = 117;
        self.showViewConstant.constant = 79;
        self.isShowPersonInfoView = YES;
        
        self.showView.hidden = NO;
    }
    
    [self.personInfoView setNeedsUpdateConstraints];
    
}
- (IBAction)cancelEdit:(UIBarButtonItem *)sender
{
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}
- (IBAction)commitButton:(UIBarButtonItem *)sender
{
    [self.coreDataStack saveContext];
    
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"nodeName = %@",@"入院记录"];
    //NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"nodeIndex" ascending:YES];
    
    NSArray *resultA = [self.coreDataStack fetchNSManagedObjectEntityWithName:[ParentNode entityName] withNSPredicate:predicate setUpFetchRequestResultType:0 isSetUpResultType:NO setUpFetchRequestSortDescriptors:nil isSetupSortDescriptors:NO];
    NSString * createdTime;
    if([self.recordCase.caseType isEqualToString: @"未创建"]){
        createdTime = [self changeDateToDateString:[NSDate date]];
    }
    NSString *caseState = self.recordCase.caseState;
    NSString *caseType = self.recordCase.caseType;
    if (resultA.count == 1) {
        ParentNode *parentNode = (ParentNode*)[resultA firstObject];
        for (Node *node in parentNode.nodes.array) {
            [dic setObject:node.nodeContent==nil? @"":node.nodeContent forKey:node.nodeName];
            if ([node.nodeContent isEqualToString:node.nodeName]) {
                caseState  = @"未完整创建";
            }
        }
//        NSString *patientName = [dataDic objectForKey:@"pName"];
//        NSString *patientID = [dataDic objectForKey:@"pID"];
//        NSString *caseType = [dataDic objectForKey:@"caseType"];

//        @property (nonatomic, retain) NSDate * archivedTime;
//        @property (nonatomic, retain) NSString * caseContent;
//        @property (nonatomic, retain) NSString * casePresenter;
//        @property (nonatomic, retain) NSString * caseState;
//        @property (nonatomic, retain) NSString * caseType;
//        @property (nonatomic, retain) NSDate * createdTime;
//        @property (nonatomic, retain) NSDate * lastModifyTime;

        NSString *caseContent =[self convertJSONDataToString:[self convertToJSONDataFromList:dic]];
        NSString *lastModifyTime =[self changeDateToDateString:[NSDate date]];
        Patient *patient = self.recordCase.patient;
        
        NSString *pName = patient.pName;
        NSString *pID = patient.pID;
        
        NSDictionary *tempDic = NSDictionaryOfVariableBindings(caseType,caseState,lastModifyTime,pName,caseContent);
        NSMutableDictionary *dic = [[NSMutableDictionary alloc] initWithDictionary:tempDic];
        if (pID) {
            [dic setObject:pID forKey:@"pID"];
        }
        if (createdTime) {
            [dic setObject:createdTime forKey:@"createdTime"];
        }
        
        [MessageObject messageObjectWithUsrStr:@"1" pwdStr:@"test" iHMsgSocket:self.socket optInt:20001 dictionary:[NSMutableDictionary dictionaryWithDictionary:@{@"bl":[self convertJSONDataToString:[self convertToJSONDataFromList:dic]]}] block:^(IHSockRequest *request) {
            if ([request.responseData isKindOfClass:[NSArray class]]) {
                NSArray *tempA = (NSArray*)request.responseData;
                NSDictionary *tempDic = (NSDictionary*)[tempA firstObject];
                
                if ([tempDic.allKeys containsObject:@"_id"]) {
                    NSString *caseID = tempDic[@"_id"];
                    [dic setObject:caseID forKey:@"caseID"];
                    [self.coreDataStack updateRecordBaseInfoEntityWithDataDic:dic];
                }
            }
            
        } failConection:^(NSError *error) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"服务器端出错" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];

        }];
        
        [self dismissViewControllerAnimated:YES completion:^{
            
        }];
    }else {
        abort();
    }

}
- (NSString *) changeDateToDateString :(NSDate *) date {
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeZone:[NSTimeZone localTimeZone]];
    NSLocale *locale = [NSLocale currentLocale];
    NSString *dateFormat = [NSDateFormatter dateFormatFromTemplate:@"hh mm" options:0 locale:locale];
    [dateFormatter setDateFormat:dateFormat];
    [dateFormatter setLocale:locale];
    NSString *dateString = [dateFormatter stringFromDate:date];
    return dateString;
}
-(IHMsgSocket *)socket
{
    if (!_socket) {
        _socket = [IHMsgSocket sharedRequest];
        [_socket connectToHost:@"192.168.10.106" onPort:2323];
    }
    return _socket;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.tabelView.autoresizesSubviews = NO;
    [self setUpTableView];
    [self addKeyboardObserver];
    
    [self setUpFetchViewController];
    
   // self.personInfoHeight.constant = 0;
    //[self.personInfoView setNeedsUpdateConstraints];
   // self.personInfoView.hidden = YES;
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
        [self.tabelView reloadData];
        
    }
  
}
-(NSMutableArray *)dataArray
{
    if (!_dataArray) {
        _dataArray = [[NSMutableArray alloc] init];
//        [_dataArray addObject:@"我是一个肺腧将我是一个肺腧将我是一个肺腧将我是一个肺腧将我是一个肺腧将我是一个肺腧将我是一个肺腧将我是一个肺腧将我是一个肺腧将我是一个肺腧将"];
//        [_dataArray addObject:@"cell2"];
//        [_dataArray addObject:@"我是一个肺腧将我是一个肺腧将我是一个肺腧将我是一个肺腧将我是一个肺腧将我是一个肺腧将"];
//        [_dataArray addObject:@"我是一个肺腧将"];
//        [_dataArray addObject:@"我是一个肺腧将我是一个肺腧将我是一个肺腧将我是一个肺腧将我是一个肺腧将我是一个肺腧将我是一个肺腧将我是一个肺腧将我是一个肺腧将我是一个肺腧将我是一个肺腧将我是一个肺腧将我是一个肺腧将我是一个肺腧将我是一个肺腧将我是一个肺腧将我是一个肺腧将我是一个肺腧将我是一个肺腧将我是一个肺腧将我是一个肺腧将"];
//        [_dataArray addObject:@"我是说姐姐家啊啊时间即可开始快速开始上课"];
//
//        [_dataArray addObject:@"我是说姐姐家啊啊时间即可开始快速开始上课我是说姐姐家啊啊时间即可开始快速开始上课"];
//        [_dataArray addObject:@"cell2"];
//        [_dataArray addObject:@"我是说姐姐家啊啊时间即可开始快速开始上课我是说姐姐家啊啊时间即可开始快速开始上课我是说姐姐家啊啊时间即可开始快速开始上课我是说姐姐家啊啊时间即可开始快速开始上课"];
//        [_dataArray addObject:@"我是说姐姐家啊啊时间即可开始快速开始上课"];
//        [_dataArray addObject:@"我是一个肺腧将我是一个肺腧将我是一个肺腧将我是一个肺腧将我是一个肺腧将我是一个肺腧将我是一个肺腧将我是一个肺腧将我是一个肺腧将我是一个肺腧将我是一个肺腧将我是一个肺腧将我是一个肺腧将我是一个肺腧将我是一个肺腧将我是一个肺腧将我是一个肺腧将我是一个肺腧将我是一个肺腧将我是一个肺腧将我是一个肺腧将我是说姐姐家啊啊时间即可开始快速开始上课我是说姐姐家啊啊时间即可开始快速开始上课"];
//        [_dataArray addObject:@"cell6"];

    }
    return _dataArray;
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
    if([self.tabelView.superview isKindOfClass:[UIScrollView class]])
        tableView = (UIScrollView *)self.tabelView.superview;
    else
        tableView = self.tabelView;
    
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
    if([self.tabelView.superview isKindOfClass:[UIScrollView class]])
        tableView = (UIScrollView *)self.tabelView.superview;
    else
        tableView = self.tabelView;
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
    UITableView *tableView = self.tabelView;
    if(self.currentIndexPath)
    {
        [tableView scrollToRowAtIndexPath:self.currentIndexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        [tableView selectRowAtIndexPath:self.currentIndexPath animated:NO scrollPosition:UITableViewScrollPositionBottom];
    }
}

-(void)removeKeyboardObserver
{
 [[NSNotificationCenter defaultCenter] removeObserver:self];
}
-(void)setUpTableView
{
    self.tabelView.layer.shadowOffset = CGSizeMake(15, 13);
    self.tabelView.layer.shadowOpacity = 1;
    self.tabelView.layer.shadowRadius = 20;
    self.tabelView.layer.shadowColor = [UIColor darkGrayColor].CGColor;
    
    self.tabelView.layer.borderWidth = 1;
   // self.tabelView.layer.borderColor = [UIColor darkGrayColor].CGColor;
    self.tabelView.estimatedRowHeight = 55;
    self.tabelView.rowHeight = UITableViewAutomaticDimension;
    
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
    AdmissionRecordCell *cell = [tableView dequeueReusableCellWithIdentifier:@"admissionRecordCell"];
    cell.autoresizesSubviews = NO;
    [self configureCell:cell AtIndexPath:indexPath];
    
    return cell;
}
-(void)configureCell:(AdmissionRecordCell*)cell AtIndexPath:(NSIndexPath*)indexPath
{
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    Node *tempNode = [self.fetchResultController objectAtIndexPath:indexPath];
    cell.textViewDelegate = self;
    UILabel *cellLabel = (UILabel*)[cell viewWithTag:1001];
    UITextView *textView = (UITextView*)[cell viewWithTag:1002];
    
    cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
    
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

#pragma mask - AdmissionRecordCell  delegate
-(void)textViewCell:(AdmissionRecordCell *)cell didChangeText:(NSString *)text
{
    NSIndexPath *indexPath = [self.tabelView indexPathForCell:cell];

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

-(void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    AdmissionRecordCell *cell =(AdmissionRecordCell*) [tableView cellForRowAtIndexPath:indexPath];
    UILabel *label =(UILabel*) [cell viewWithTag:1001];
    self.selectedStr = label.text;
    
    self.currentIndexPath = indexPath;
    [self performSegueWithIdentifier:@"ToWirteMedicalCaseSegue" sender:nil];
}

///
-(void)didSelectedTemplate:(Template *)template
{
    //self.dataArray[self.currentIndexPath.row] = template.condition;
    Node *tempNode = [self.fetchResultController objectAtIndexPath:self.currentIndexPath];
    tempNode.nodeContent = template.content;
    [self.coreDataStack saveContext];
    //[self.tabelView reloadRowsAtIndexPaths:@[self.currentIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}
#pragma mask - fetch view controller delegate
/// fetch result controller delegate
-(void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.tabelView beginUpdates];
}
-(void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
    switch (type) {
        case NSFetchedResultsChangeInsert:{
            [self.tabelView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        }
        case NSFetchedResultsChangeDelete:{
            [self.tabelView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        }
        case NSFetchedResultsChangeUpdate:{
           BOOL pop =  [[NSUserDefaults standardUserDefaults] boolForKey:@"referenceTemplateString"];
            if (pop) {
                AdmissionRecordCell *cell =(AdmissionRecordCell*) [self.tabelView cellForRowAtIndexPath:indexPath];
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
            [self.tabelView insertSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        case NSFetchedResultsChangeDelete:
            [self.tabelView deleteSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        default:
            break;
    }
}
-(void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tabelView endUpdates];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
//    if ([segue.identifier isEqualToString:@"popoverTemSegue"]) {
//        ShowTemplateViewControllerTwo *showVC = (ShowTemplateViewControllerTwo*)segue.destinationViewController;
//        showVC.fetchStr = self.selectedStr;
//        showVC.showTempDelegate  =self;
//        
//        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"referenceTemplateString"];
//    }
    if ([segue.identifier isEqualToString:@"ToWirteMedicalCaseSegue"]){
        WriteMedicalRecordVCViewController *writeMedicalVC = (WriteMedicalRecordVCViewController*)segue.destinationViewController;
        writeMedicalVC.labelString = self.selectedStr;
        writeMedicalVC.WriteDelegate = self;
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"referenceTemplateString"];
    }
}
#pragma mask - write delegate
-(void)didWriteStringToMedicalRecord:(NSString *)writeString
{
    Node *tempNode = [self.fetchResultController objectAtIndexPath:self.currentIndexPath];
    tempNode.nodeContent = writeString;
    [self.coreDataStack saveContext];
    
}

- (IBAction)unwindSegueToAdmissioVC:(UIStoryboardSegue *)segue
{
    
}


-(void)dealloc
{
    [self removeKeyboardObserver];
}
@end

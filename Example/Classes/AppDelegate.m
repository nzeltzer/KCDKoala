//
//  AppDelegate.m
//  KCDKoalaMobileSampleApp
//
//  Created by Nicholas Zeltzer on 10/28/14.
//  Copyright (c) 2014 Nicholas Zeltzer
//

#import "AppDelegate.h"
#import "KCDObjectController+KCDDemoApp.h"
#import "NSString+KCDDemo.h"

#pragma mark - Constants

NSString * const KCDDemoTableViewShuffle = @"UITableView Shuffle";
NSString * const KCDDemoCollectionViewShuffle = @"UICollection View Shuffle";
NSString * const KCDDemoCollectionViewArrangement = @"UICollectionView Transition";
NSString * const KCDDemoTableViewArrangement = @"UITableView Transition";
NSString * const KCDDemoTableViewFiles = @"File Based UITableView";
NSString * const KCDDemoCollectionViewFiles = @"File Based UICollectionView";
NSString * const KCDDemoTableViewColors = @"UIColor UITableView";
NSString * const KCDDemoCollectionViewColors = @"UIColor UICollectionView";
NSString * const KCDDemoTableViewStrings = @"NSString UITableView";
NSString * const KCDDemoCollectionViewStrings = @"NSString UICollectionView";
NSString * const KCDDemoTableViewAPISample = @"UITableView API Read Along";
NSString * const KCDDemoCollectionViewAPISample = @"UICollectionView API Read-Along";

#pragma mark - KCDCollectionViewTableLayout

@interface KCDCollectionViewTableLayout : UICollectionViewFlowLayout

@end

#pragma mark - KCDCollectionViewTableLayout

@implementation KCDCollectionViewTableLayout

@end

#pragma mark - AppDelegate -

#pragma mark Class Extension

@interface AppDelegate () <KCDTableViewDataSourceDelegate, UITableViewDelegate, KCDCollectionViewDataSourceDelegate, UICollectionViewDelegate>

@property (nonatomic, readwrite, strong) KCDObjectController *dataSource;
@property (nonatomic, readwrite, strong) UINavigationController *navigationController;
@property (nonatomic, readwrite, strong) UIViewController *viewController;

@end

#pragma mark Implementation

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions;
{
    
    self.viewController = ({
        // NSString+KCDKoala brings NSString into conformance with the KCDTableViewObject and KCDCollectionViewObject protocols.
        // As conformant objects, we can initialize a table view controller directly.
        NSArray *cellNames = @[KCDDemoTableViewAPISample,
                               KCDDemoCollectionViewAPISample,
                               KCDDemoTableViewShuffle,
                               KCDDemoCollectionViewShuffle,
                               KCDDemoCollectionViewArrangement,
                               KCDDemoTableViewArrangement,
                               KCDDemoTableViewColors,
                               KCDDemoCollectionViewColors,
                               KCDDemoTableViewStrings,
                               KCDDemoCollectionViewStrings,
                               KCDDemoTableViewFiles,
                               KCDDemoCollectionViewFiles,
                               ];
        
        UITableViewController *viewController = [[UITableViewController alloc]
                                                 initWithStyle:UITableViewStyleGrouped
                                                 objects:cellNames];
        [viewController.KCDDataSource setDelegate:self];
        viewController;
    });
    
    self.navigationController = ({
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:self.viewController];
        nav;
    });
    
    self.window = ({
        UIWindow *window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        window.backgroundColor = [UIColor whiteColor];
        [window setRootViewController:self.navigationController];
        window;
    });
    
    [self.window makeKeyAndVisible];
    
    return YES;
}

#pragma mark - Delegate Methods

#pragma mark KCDTableViewDataSourceDelegate

- (void)koala:(KCDObjectController<KCDIntrospective> *)koala
    tableView:(UITableView *)tableView
didSelectObject:(id<KCDObject>)tableViewObject
  atIndexPath:(NSIndexPath *)indexPath;
{
    if (koala == [self.viewController KCDObjectController]) {
        if ([tableViewObject isKindOfClass:[NSString class]]) {
            if (tableView == [self.viewController view]) {
                [self handleDemoSelection:(id<KCDObject>)tableViewObject];
            }
        }
        else if ([tableViewObject isKindOfClass:[KCDAbstractObject class]]) {
            NSLog(@"%@", [(KCDAbstractObject *)tableViewObject title]);
        }
    }
    else {
        NSLog(@"%@", tableViewObject);
    }
}

#pragma mark KCDCollectionViewDataSourceDelegate

- (UICollectionReusableView *)koala:(KCDCollectionViewDataSource<KCDIntrospective>*)koala
                     collectionView:(UICollectionView *)collectionView
  viewForSupplementaryElementOfKind:(NSString *)kind
                        atIndexPath:(NSIndexPath *)indexPath;
{
    KCDDemoResusableView *view = (KCDDemoResusableView*)[collectionView dequeueReusableSupplementaryViewOfKind:kind
                                                                                           withReuseIdentifier:NSStringFromClass([KCDDemoResusableView class])
                                                                                                  forIndexPath:indexPath];
    id <KCDSection> section = [koala sectionAtIndex:indexPath.section];
    view.title = [section sectionName];
    return view;
}

- (void)koala:(KCDCollectionViewDataSource<KCDIntrospective>*)koala
collectionView:(UICollectionView *)collectionView
didSelectItem:(id<KCDObject>)item
  atIndexPath:(NSIndexPath *)indexPath;
{
    NSLog(@"%@.%@ - %@", @(indexPath.section), @(indexPath.row), item);
}

#pragma mark - Factory

- (UICollectionViewFlowLayout *)flowLayout;
{
    // A simple flow layout instance for use with the demo collection views.
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.itemSize = CGSizeMake(50, 50);
    layout.minimumInteritemSpacing = 20.0f;
    layout.minimumLineSpacing = 10.f;
    layout.sectionInset = UIEdgeInsetsMake(10, 10, 10, 10);
    return layout;
}

#pragma mark - Demo Selection -

- (void)handleDemoSelection:(id<KCDObject>)object;
{
    if (object == KCDDemoTableViewShuffle) {
        [self pushShuffleDemo:[UITableViewController class]];
    }
    else if (object == KCDDemoCollectionViewShuffle) {
        [self pushShuffleDemo:[UICollectionViewController class]];
    }
    else if (object == KCDDemoTableViewAPISample) {
        [self pushAPIDemo:[UITableViewController class]];
    }
    else if (object == KCDDemoCollectionViewAPISample) {
        [self pushAPIDemo:[UICollectionViewController class]];
    }
    else if (object == KCDDemoTableViewArrangement) {
        [self pushContentTransitionDemo:[UITableViewController class]];
    }
    else if (object == KCDDemoCollectionViewArrangement) {
        [self pushContentTransitionDemo:[UICollectionViewController class]];
    }
    else if (object == KCDDemoTableViewColors) {
        [self pushColorsCategoryDemo:[UITableViewController class]];
    }
    else if (object == KCDDemoCollectionViewColors) {
        [self pushColorsCategoryDemo:[UICollectionViewController class]];
    }
    else if (object == KCDDemoTableViewStrings) {
        [self pushStringsCategoryDemo:[UITableViewController class]];
    }
    else if (object == KCDDemoCollectionViewStrings) {
        [self pushStringsCategoryDemo:[UICollectionViewController class]];
    }
    else if (object == KCDDemoTableViewFiles) {
        [self pushFilesDemo:[UITableViewController class]];
    }
    else if (object == KCDDemoCollectionViewFiles) {
        [self pushFilesDemo:[UICollectionViewController class]];
    }
}

#pragma mark Colors

- (void)pushColorsCategoryDemo:(Class)viewControllerClass;
{
    UIViewController *controller = nil;
    
    NSArray *colorsArray =  @[[UIColor redColor],
                              [UIColor orangeColor],
                              [UIColor yellowColor],
                              [UIColor darkGrayColor],
                              [UIColor lightGrayColor],
                              [UIColor purpleColor],
                              [UIColor greenColor],
                              [UIColor blueColor],
                              [UIColor magentaColor],
                              [UIColor cyanColor],
                              [UIColor brownColor]];
    
    if ([NSStringFromClass(viewControllerClass) isEqualToString:NSStringFromClass([UICollectionViewController class])]) {
        controller = [[UICollectionViewController alloc]
                      initWithLayout:[self flowLayout]
                      objects:colorsArray];
        [[(UICollectionViewController*)controller collectionView]
         registerClass:[UICollectionViewCell class]
         forCellWithReuseIdentifier:NSStringFromClass([UIColor class])];
        [(UICollectionViewController *)controller setEditing:YES animated:NO];
    }
    if ([NSStringFromClass(viewControllerClass) isEqualToString:NSStringFromClass([UITableViewController class])]) {
        controller = [[UITableViewController alloc]
                      initWithStyle:UITableViewStylePlain
                      objects:colorsArray];
        [(UITableViewController *)controller setEditing:YES animated:NO];
    }
    [controller.KCDObjectController setDelegate:self];
    [self.navigationController pushViewController:controller animated:YES];
}

#pragma mark Strings

- (void)pushStringsCategoryDemo:(Class)viewControllerClass;
{
    NSMutableArray *stringSections = [NSMutableArray new];
    for (NSInteger x = 0; x < 3; x++) {
        NSMutableArray *strings = [NSMutableArray new];
        for (NSInteger s = 0; s < 10; s++)
        {
            [strings addObject:KCDRandomTitle()];
        }
        [stringSections addObject:[KCDObjectController sectionWithName:@(x).stringValue objects:strings]];
    }
    
    UIViewController *controller = nil;
    if ([NSStringFromClass(viewControllerClass) isEqualToString:NSStringFromClass([UICollectionViewController class])]) {
        controller = [[UICollectionViewController alloc]
                      initWithLayout:[self flowLayout]
                      sections:stringSections];
        [[(UICollectionViewController *)controller collectionView]
         registerClass:[KCDDemoTableCollectionViewCell class]
         forCellWithReuseIdentifier:NSStringFromClass([NSString class])];
    }
    if ([NSStringFromClass(viewControllerClass) isEqualToString:NSStringFromClass([UITableViewController class])]) {
        controller = [[UITableViewController alloc]
                      initWithStyle:UITableViewStylePlain
                      sections:stringSections];
    }
    [controller.KCDObjectController setDelegate:self];
    [self.navigationController pushViewController:controller animated:YES];
}

#pragma mark Content Transition

- (void)pushContentTransitionDemo:(Class)viewControllerClass;
{
    UIViewController *controller = nil;
    NSArray *randomSections = KCDRandomSectionsWithIdentifier([KCDDemoObject class], KCDCircleCellIdentifier, 2, 0);
    if ([NSStringFromClass(viewControllerClass) isEqualToString:NSStringFromClass([UICollectionViewController class])]) {
        controller = [[UICollectionViewController alloc]
                      initWithLayout:[self flowLayout]
                      sections:randomSections];
        [(UICollectionViewController *)controller KCDCellClassRegister:[KCDDemoObject class]];
    }
    if ([NSStringFromClass(viewControllerClass) isEqualToString:NSStringFromClass([UITableViewController class])]) {
        controller = [[UITableViewController alloc]
                      initWithStyle:UITableViewStyleGrouped
                      sections:randomSections];
    }
    [controller.KCDObjectController setDelegate:self];
    [self.navigationController pushViewController:controller animated:YES];
    [controller.KCDObjectController KCDDemoDiffForever:KCDCircleCellIdentifier];
}

#pragma mark Shuffle Demo

- (void)pushShuffleDemo:(Class)viewControllerClass;
{
    UIViewController *controller = nil;
    NSArray *randomSections = KCDRandomSectionsWithIdentifier([KCDDemoObject class], KCDCircleCellIdentifier, 2, 1);
    if ([NSStringFromClass(viewControllerClass) isEqualToString:NSStringFromClass([UICollectionViewController class])]) {
        UICollectionViewFlowLayout *layout = [self flowLayout];
        controller = [[UICollectionViewController alloc]
                      initWithLayout:layout
                      sections:randomSections];
        [(UICollectionViewController *)controller KCDCellClassRegister:[KCDDemoObject class]];
    }
    if ([NSStringFromClass(viewControllerClass) isEqualToString:NSStringFromClass([UITableViewController class])]) {
        controller = [[UITableViewController alloc]
                      initWithStyle:UITableViewStyleGrouped
                      sections:randomSections];
    }
    [controller.KCDObjectController setDelegate:self];
    [self.navigationController pushViewController:controller animated:YES];
    [controller.KCDObjectController KCDDemoShuffleForever];
}

#pragma mark API Demo

- (void)pushAPIDemo:(Class)viewControllerClass;
{
    UIViewController *controller = nil;
    if ([NSStringFromClass(viewControllerClass) isEqualToString:NSStringFromClass([UICollectionViewController class])]) {
        controller = [[UICollectionViewController alloc]
                      initWithLayout:[self flowLayout]
                      sections:nil];
        [(UICollectionViewController *)controller KCDCellClassRegister:[KCDDemoObject class]];
    }
    if ([NSStringFromClass(viewControllerClass) isEqualToString:NSStringFromClass([UITableViewController class])]) {
        controller = [[UITableViewController alloc]
                      initWithStyle:UITableViewStyleGrouped
                      objects:nil];
    }
    [controller.KCDObjectController setDelegate:self];
    [self.navigationController pushViewController:controller animated:YES];
    [controller.KCDObjectController KCDDemoAPIForever:KCDCircleCellIdentifier];
}

#pragma mark Files Demo

- (void)pushFilesDemo:(Class)viewControllerClass;
{
    // TODO: Implementation
}

@end

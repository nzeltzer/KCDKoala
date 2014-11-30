//
//  KCDCollectionViewDataSource.m
//  KCDKoala
//
//  Created by Nicholas Zeltzer on 10/29/14.
//  Copyright (c) 2014 LawBox LLC. All rights reserved.
//

#import "KCDTableViewDataSource.h"
#import "KCDAbstractObject.h"
#import "KCDUtilities.h"
#import "UITableView+KCDKoala.h"

typedef struct {
    BOOL cellForObject;
    BOOL didSelectObject;
    BOOL didDeselectObject;
    BOOL heightForObject;
    BOOL viewForHeader;
    BOOL viewForFooter;
    BOOL heightForHeader;
    BOOL heightForFooter;
    BOOL commitEditing;
    BOOL accessoryButtonTapped;
    BOOL canMoveObject;
    BOOL canEditObject;
    BOOL didDeleteCellForTableViewObject;
} KCDTableViewDataSourceDelegateFlags;

@interface KCDTableViewDataSource() <KCDIntrospective> {
    KCDTableViewDataSourceDelegateFlags _tableViewDelegateFlags;
}

@property (nonatomic, readwrite, weak) id <KCDTableViewDataSourceDelegate, UITableViewDelegate, UITableViewDataSource> tableViewDelegate;

@property (nonatomic, readwrite, strong) NSMutableArray *sectionObjects;

@end

@implementation KCDTableViewDataSource

@synthesize tableView = _tableView;
@dynamic transactionStaggerDuration;
@dynamic sectionObjects;

- (instancetype)initWithDelegate:(id<KCDObjectControllerDelegate>)delegate;
{
    self = [super initWithDelegate:delegate];
    if (self) {
        self.transactionStaggerDuration = 0.0f;
    }
    return self;
}

- (void)setTransactionStaggerDuration:(NSTimeInterval)transactionStaggerDuration;
{
    _KCDTransactionDelay = transactionStaggerDuration;
}

- (NSTimeInterval)transactionStaggerDuration;
{
    return _KCDTransactionDelay;
}

- (void)dealloc;
{
    [self.tableView setDataSource:nil];
    [self.tableView setDelegate:nil];
}

- (void)commitUpdate:(void(^)())action completion:(void (^)())completion;
{
    __block UITableView *__weak weakView = nil;
    if (!(weakView = _tableView)) {
        if (completion) { completion(); }
        return;
    }
    __block UITableView *__strong strongView = nil;
    
    void (^didFinish)() = ^{
        dispatch_group_leave(_KCDAnimationGroup);
        if (completion) {
            completion();
        }
        strongView = nil;
    };
    
    dispatch_group_notify(_KCDAnimationGroup, _KCDAnimationQueue, ^{
        dispatch_group_wait(_KCDAnimationGroup, DISPATCH_TIME_FOREVER);
        dispatch_group_enter(_KCDAnimationGroup);
        dispatch_async(dispatch_get_main_queue(), ^{
            if ((strongView = weakView)) {
                [strongView beginUpdates];
                action();
                [strongView endUpdates];
            }
            didFinish();
        });
    });
}

- (NSMutableArray *)sectionObjects;
{
    return _KCDSectionObjects;
}

- (void)setSectionObjects:(NSMutableArray *)sectionObjects;
{
    [self willChangeValueForKey:@"sections"];
    _KCDSectionObjects = sectionObjects;
    [self didChangeValueForKey:@"sections"];
}

#pragma mark - Forwarding

- (NSArray *)forwardingProtocols;
{
    NSMutableArray *forwards = [NSMutableArray arrayWithArray:[super forwardingProtocols]];
    [forwards addObject:@protocol(UITableViewDelegate)];
    return forwards;
}

#pragma mark - Accessors

- (void)setTableView:(UITableView *)tableView;
{
    [_tableView setDelegate:nil];
    [_tableView setDataSource:nil];
    _tableView = tableView;
    [_tableView setDelegate:self];
    [_tableView setDataSource:self];
}

- (void)setDelegate:(id<KCDTableViewDataSourceDelegate>)delegate;
{
    KCDTableViewDataSourceDelegateFlags newFlags;
    _tableViewDelegateFlags = newFlags;
    _tableViewDelegateFlags.canEditObject =
    [self.delegate respondsToSelector:@selector(koala:tableView:canEditObject:atIndexPath:)];
    _tableViewDelegateFlags.canMoveObject =
    [self.delegate respondsToSelector:@selector(koala:tableView:canMoveObject:atIndexPath:)];
    _tableViewDelegateFlags.didSelectObject =
    [(id<UITableViewDelegate>)delegate respondsToSelector:@selector(koala:tableView:didSelectObject:atIndexPath:)];
    _tableViewDelegateFlags.didDeselectObject =
    [(id<UITableViewDelegate>)delegate respondsToSelector:@selector(koala:tableView:didDeselectObject:atIndexPath:)];
    _tableViewDelegateFlags.heightForObject =
    [(id<UITableViewDelegate>)delegate respondsToSelector:@selector(koala:tableView:heightForObject:)];
    _tableViewDelegateFlags.cellForObject =
    [(id<UITableViewDelegate>)delegate respondsToSelector:@selector(koala:tableView:cellForObject:atIndexPath:)];
    _tableViewDelegateFlags.viewForHeader =
    [(id<UITableViewDelegate>)delegate respondsToSelector:@selector(tableView:viewForHeaderInSection:)];
    _tableViewDelegateFlags.viewForFooter =
    [(id<UITableViewDelegate>)delegate respondsToSelector:@selector(tableView:viewForFooterInSection:)];
    _tableViewDelegateFlags.heightForHeader =
    [(id<UITableViewDelegate>)delegate respondsToSelector:@selector(tableView:heightForHeaderInSection:)];
    _tableViewDelegateFlags.heightForFooter =
    [(id<UITableViewDelegate>)delegate respondsToSelector:@selector(tableView:heightForFooterInSection:)];
    _tableViewDelegateFlags.commitEditing =
    [(id<UITableViewDelegate>)delegate respondsToSelector:@selector(koala:tableView:commitEditingStyle:forObject:atIndexPath:)];
    _tableViewDelegateFlags.accessoryButtonTapped =
    [(id<UITableViewDelegate>)delegate respondsToSelector:@selector(koala:tableView:accessoryButtonTappedForObject:withIndexPath:)];
    _tableViewDelegateFlags.didDeleteCellForTableViewObject = [self.delegate respondsToSelector:@selector(tableView:didDeleteCellForTableViewObject:)];
    [super setDelegate:delegate];
    // Regenerate delegate response struct
    [self.tableView setDelegate:self];
    [self.tableView setDataSource:self];
}

- (id<KCDTableViewDataSourceDelegate, UITableViewDelegate>)tableViewDelegate;
{
    return (id<KCDTableViewDataSourceDelegate, UITableViewDelegate>)self.delegate;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    if (indexPath.row < 50) {
        return UITableViewAutomaticDimension;
    }
    return 44.0f;
}

- (void)tableView:(UITableView*)tableView didDeleteCellForTableViewObject:(id<KCDObject>)tableViewObject;
{
    KCDObjectController <KCDIntrospective> *__weak weakSelf = self;
    if (_tableViewDelegateFlags.didDeleteCellForTableViewObject)
    {
        [self.tableViewDelegate koala:weakSelf tableView:tableView didDeleteCellForTableViewObject:tableViewObject];
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath;
{
    KCDObjectController <KCDIntrospective> *__weak weakSelf = self;
    id <KCDObject>cellObject = nil;
    if ((cellObject = [self objectAtIndexPath:indexPath])) {
        if (_tableViewDelegateFlags.commitEditing) {
            [self.delegate
             koala:weakSelf
             tableView:tableView
             commitEditingStyle:editingStyle
             forObject:cellObject
             atIndexPath:indexPath];
        }
        else if (editingStyle == UITableViewCellEditingStyleDelete) {
            [self deleteObjectsAtIndexPaths:@[indexPath]
                                  animation:UITableViewRowAnimationFade];
            [self queueTransaction:^(KCDObjectController *koala){
                [(KCDTableViewDataSource *)koala tableView:tableView didDeleteCellForTableViewObject:cellObject];
            }];
        }
    }
    NSAssert(cellObject,
             @"%@ returned nil cell object for index path: %@",
             NSStringFromClass([self class]),
             indexPath);
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath;
{
     KCDObjectController <KCDIntrospective> *__weak weakSelf = self;
    id <KCDObject>cellObject = nil;
    if ((cellObject = [self objectAtIndexPath:indexPath])) {
        if (_tableViewDelegateFlags.canMoveObject) {
            return [self.delegate
                    koala:weakSelf
                    tableView:tableView
                    canMoveObject:cellObject
                    atIndexPath:indexPath];
        }
        else if ([cellObject respondsToSelector:@selector(canMove)]) {
            return [cellObject canMove];
        }
    }
    NSAssert(cellObject,
             @"%@ returned nil cell object for index path: %@",
             NSStringFromClass([self class]),
             indexPath);
    return NO;
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath;
{
    KCDObjectController <KCDIntrospective> *__weak weakSelf = self;
    id <KCDObject>cellObject = nil;
    if ((cellObject = [self objectAtIndexPath:indexPath])) {
        if (_tableViewDelegateFlags.canEditObject) {
            return [self.delegate
                    koala:weakSelf
                    tableView:tableView
                    canEditObject:cellObject
                    atIndexPath:indexPath];
        }
        else if ([cellObject respondsToSelector:@selector(canEdit)]) {
            return [cellObject canEdit];
        }
    }
    NSAssert(cellObject,
             @"%@ returned nil cell object for index path: %@",
             NSStringFromClass([self class]),
             indexPath);
    return NO;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView;
{
    NSInteger numberOfSections = [self.sectionObjects count];
    return numberOfSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;
{
    id<KCDSection> module = [self.sectionObjects objectAtIndex:section];
    NSInteger count = [[module objects] count];
    return count;
}

- (UITableViewCell*)tableView:(UITableView *)tableView
        cellForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    UITableViewCell *cell = nil;
    KCDObjectController <KCDIntrospective> *__weak weakSelf = self;
    id <KCDTableViewObject>cellObject = nil;
    if ((cellObject = (id<KCDTableViewObject>)[self objectAtIndexPath:indexPath])) {
        if (_tableViewDelegateFlags.cellForObject) {
            cell = [self.delegate
                    koala:weakSelf
                    tableView:tableView
                    cellForObject:cellObject
                    atIndexPath:indexPath];
            NSAssert(cell,
                     @"%@ implements %@ but did not return a table view cell for %@",
                     NSStringFromClass([self.delegate class]),
                     NSStringFromSelector(_cmd),
                     indexPath);
        }
        else {
            cell = [cellObject cellForTableView:tableView];
        }
    }
    return cell;
}

- (NSArray*)sectionIndexTitlesForTableView:(UITableView *)tableView;
{
    if (![self enableSectionIndex]) {
        return nil;
    }
    NSMutableArray *titles = [NSMutableArray arrayWithCapacity:[self.sectionObjects count]];
    for (id<KCDSection> section in self.sectionObjects)
    {
        NSString *sectionHeader = nil;
        if ((sectionHeader = [section sectionHeader])) {
            [titles addObject:sectionHeader];
        }
    }
    return titles;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index;
{
    return index;
}

#pragma mark - Reordering Table Rows

- (void)tableView:(UITableView *)tableView
moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath
      toIndexPath:(NSIndexPath *)destinationIndexPath;
{
    NSAssert(sourceIndexPath, @"Source index path cannot be nil!");
    NSAssert(destinationIndexPath, @"Destination index path cannot be nil!");
    if (!sourceIndexPath || !destinationIndexPath) {
        return;
    }
    [self queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
        id<KCDMutableSection> sourceSection = (id<KCDMutableSection>)[koala sectionAtIndex:sourceIndexPath.section];
        id<KCDObject> object = [sourceSection objectAtIndex:sourceIndexPath.row];
        [sourceSection removeObjectAtIndex:sourceIndexPath.row];
        id<KCDMutableSection> destinationSection = (id<KCDMutableSection>)[koala sectionAtIndex:destinationIndexPath.section];
        NSInteger row = destinationIndexPath.row;
        [destinationSection insertObject:object atIndex:&row];
    }];
    
}

#pragma Headers and Footers

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section;
{
    id<KCDSection> module = [self.sectionObjects objectAtIndex:section];
    NSString *title = nil;
    if (!(title = [module sectionHeader]))
    {
        title = [module sectionName];
    }
    return title;
}

- (NSString*)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section;
{
    id<KCDSection> module = [self.sectionObjects objectAtIndex:section];
    NSString *title = [module sectionFooter];
    return title;
}

#pragma mark - UITableViewDelegate

#pragma mark Selection

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath;
{
    KCDObjectController <KCDIntrospective> *__weak weakSelf = self;
    
    if (_tableViewDelegateFlags.accessoryButtonTapped) {
        id <KCDObject> cellObject = nil;
        if ((cellObject = [self objectAtIndexPath:indexPath])) {
            [self.delegate
             koala:weakSelf
             tableView:tableView
             accessoryButtonTappedForObject:cellObject
             withIndexPath:indexPath];
        }
        NSAssert(cellObject,
                 @"%@ returned nil cell object for index path: %@",
                 NSStringFromClass([self class]),
                 indexPath);
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
{
    KCDObjectController <KCDIntrospective> *__weak weakSelf = self;
    if (_tableViewDelegateFlags.didSelectObject) {
        id <KCDObject> cellObject = nil;
        if ((cellObject = [self objectAtIndexPath:indexPath])) {
            [self.delegate
             koala:weakSelf
             tableView:tableView
             didSelectObject:cellObject
             atIndexPath:indexPath];
        }
        NSAssert(cellObject,
                 @"%@ returned nil cell object for index path: %@",
                 NSStringFromClass([self class]),
                 indexPath);
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath;
{
    KCDObjectController <KCDIntrospective> *__weak weakSelf = self;
    if (_tableViewDelegateFlags.didDeselectObject)
    {
        id <KCDObject> cellObject = nil;
        if ((cellObject = [self objectAtIndexPath:indexPath])) {
            [self.delegate
             koala:weakSelf
             tableView:tableView
             didDeselectObject:cellObject
             atIndexPath:indexPath];
        }
        NSAssert(cellObject,
                 @"%@ returned nil cell object for index path: %@",
                 NSStringFromClass([self class]),
                 indexPath);
    }
}

#pragma mark Height

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    KCDObjectController <KCDIntrospective> *__weak weakSelf = self;
    CGFloat height = 0;
    id<KCDTableViewObject>cellObject = nil;
    if ((cellObject = (id<KCDTableViewObject>)[self objectAtIndexPath:indexPath])) {
        if (_tableViewDelegateFlags.heightForObject) {
            height = [self.delegate
                      koala:weakSelf
                      tableView:tableView
                      heightForObject:cellObject];
        } else {
            height = [cellObject heightForCellInTableView:tableView];
        }
    }
    NSAssert(cellObject,
             @"%@ returned nil cell object for index path: %@",
             NSStringFromClass([self class]),
             indexPath);
    NSAssert(height >= 0, @"Height must be greater than 0.0f");
    return height;
}

#pragma mark Headers and Footers

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section;
{
    UITableViewHeaderFooterView *view = nil;
    if (_tableViewDelegateFlags.viewForHeader)
    {
        return [(id<UITableViewDelegate>)self.delegate tableView:tableView viewForHeaderInSection:section];
    }
    NSString *sectionHeaderTitle = nil;
    if ((sectionHeaderTitle = [self tableView:tableView titleForHeaderInSection:section]))
    {
        static NSString *identifier = @"KCDTableViewDataSourceHeaderIdentifier";
        if (!(view = [tableView dequeueReusableCellWithIdentifier:identifier]))
        {
            view = [[UITableViewHeaderFooterView alloc] initWithReuseIdentifier:identifier];
        }
        view.contentView.backgroundColor = [UIColor blackColor];
        view.textLabel.textColor = [UIColor whiteColor];
        view.textLabel.text = sectionHeaderTitle;
        view.layer.masksToBounds = YES;
    }
    return view;
}

- (UIView*)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section;
{
    UITableViewHeaderFooterView *view = nil;
    if (_tableViewDelegateFlags.viewForFooter)
    {
        return [(id<UITableViewDelegate>)self.delegate tableView:tableView viewForFooterInSection:section];
    }
    if ([self tableView:tableView titleForFooterInSection:section])
    {
        static NSString *identifier = @"KCDTableViewDataSourceFooterIdentifier";
        if (!(view = [tableView dequeueReusableCellWithIdentifier:identifier]))
        {
            view = [[UITableViewHeaderFooterView alloc] initWithReuseIdentifier:identifier];
            [view.contentView setBackgroundColor:[UIColor colorWithWhite:0.5 alpha:1]];
            [view.layer setMasksToBounds:YES];
        }
    }
    return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section;
{
    CGFloat height = 0;
    if (_tableViewDelegateFlags.heightForHeader) {
        height = [(id<UITableViewDelegate>)self.delegate tableView:tableView heightForHeaderInSection:section];
    } else if ([self tableView:tableView titleForHeaderInSection:section]/* && numberOfSections > 0*/) {
        height = 30;
    } else {
        height = 0;
    }
    NSAssert(height >= 0, @"Height must not be less than 0.0f");
    return MAX(height, 0);
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section;
{
    CGFloat height = 0;
    if (_tableViewDelegateFlags.heightForFooter) {
        height = [(id<UITableViewDelegate>)self.delegate tableView:tableView heightForFooterInSection:section];
    } else if ([self tableView:tableView titleForFooterInSection:section]) {
        height = 30;
    } else {
        height = 0; // iOS 7 will create a default height of 30.0f, if passed 0.
    }
    NSAssert(height >= 0, @"Height must be greater than 0.0f");
    return MAX(height, 0);
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView;
{
    if (_scrollViewDelegateFlags.scrollViewWillBeginDragging) {
        [(id<UIScrollViewDelegate>)self.delegate scrollViewWillBeginDragging:scrollView];
    }
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView
                     withVelocity:(CGPoint)velocity
              targetContentOffset:(inout CGPoint *)targetContentOffset;{
    
    // TODO: Table View row snapping
    /**
    if ([self.tableView snapsToRows] &&
        scrollView == _tableView)
    {
        CGPoint targetPoint = [(UITableView*)scrollView snapContentOffsetForOffset:*targetContentOffset];
        *targetContentOffset = targetPoint;
    }
     */
    
    if (_scrollViewDelegateFlags.scrollViewWillEndDragging_withVelocity_targetContentOffset) {
        [(id<UIScrollViewDelegate>)self.delegate scrollViewWillEndDragging:scrollView withVelocity:velocity targetContentOffset:targetContentOffset];
    }
}

#pragma mark - KCDObjectController

#pragma mark - Pipelining


- (void)beginUpdates;
{
    [self.tableView beginUpdates];
}

- (void)insertSectionsViews:(NSIndexSet*)indexSet withAnimation:(NSInteger)animation;
{
    [self.tableView insertSections:indexSet withRowAnimation:animation];
    [self.tableView reloadSectionIndexTitles];
}

- (void)deleteSectionViews:(NSIndexSet *)indexSet withAnimation:(NSInteger)animation;
{
    [self.tableView deleteSections:indexSet withRowAnimation:animation];
    [self.tableView reloadSectionIndexTitles];
}

- (void)reloadSectionViews:(NSIndexSet *)indexSet withAnimation:(NSInteger)animation;
{
    [self.tableView reloadSections:indexSet withRowAnimation:animation];
    [self.tableView reloadSectionIndexTitles];
}

- (void)moveSectionViewAtIndex:(NSInteger)fromIndex toSectionIndex:(NSInteger)toIndex;
{
    [self.tableView moveSection:fromIndex toSection:toIndex];
    [self.tableView reloadSectionIndexTitles];
}

- (void)insertViewsAtIndexPaths:(NSArray *)indexPaths withAnimation:(NSInteger)animation;
{
    [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:animation];
}

- (void)deleteViewsAtIndexPaths:(NSArray *)indexPaths withAnimation:(NSInteger)animation;
{
    [self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:animation];
}

- (void)reloadViewsAtIndexPaths:(NSArray *)indexPaths withAnimation:(NSInteger)animation;
{
    [self.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:animation];
}

- (void)moveViewAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)targetIndexPath;
{
    [self.tableView moveRowAtIndexPath:sourceIndexPath toIndexPath:targetIndexPath];
}

- (NSArray *)indexPathsForSelectedViews;
{
    return [self.tableView indexPathsForSelectedRows];
}

- (void)endUpdates;
{
    [self.tableView endUpdates];
}

- (void)reloadData;
{
    [self.tableView reloadData];
}

@end


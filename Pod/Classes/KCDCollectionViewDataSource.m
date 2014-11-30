//
//  KCDCollectionViewDataSource.m
//  KCDKoala
//
//  Created by Nicholas Zeltzer on 10/29/14.
//  Copyright (c) 2014 LawBox LLC. All rights reserved.
//

#import "KCDCollectionViewDataSource.h"
#import "KCDAbstractObject.h"
#import "KCDUtilities.h"

typedef struct {
    BOOL sizeForItem;
    BOOL viewForSupplementaryElementOfKind;
    BOOL cellForItem;
}   KCDCollectionViewDataSourceDelegateFlags;

@interface KCDCollectionViewDataSource() <KCDIntrospective> {
    @protected
    KCDCollectionViewDataSourceDelegateFlags _collectionViewDelegateFlags;
}

@end

@implementation KCDCollectionViewDataSource

@synthesize collectionView = _collectionView;

- (void)dealloc;
{
    [self.collectionView setDelegate:nil];
    [self.collectionView setDataSource:nil];
}

#pragma mark - Accessors

- (void)setCollectionView:(UICollectionView *)collectionView;
{
    [_collectionView setDataSource:nil];
    [_collectionView setDelegate:nil];
    _collectionView = collectionView;
    // Register Default View Classes
    [_collectionView registerClass:[KCDReusableView class]
        forSupplementaryViewOfKind:UICollectionElementKindSectionHeader
               withReuseIdentifier:NSStringFromClass([KCDReusableView class])];
    [_collectionView registerClass:[KCDReusableView class]
        forSupplementaryViewOfKind:UICollectionElementKindSectionFooter
               withReuseIdentifier:NSStringFromClass([KCDReusableView class])];
    [_collectionView setDelegate:self];
    [_collectionView setDataSource:self];
    [_collectionView reloadData];
}

- (void)setDelegate:(id<KCDCollectionViewDataSourceDelegate>)delegate;
{
    _collectionViewDelegateFlags.sizeForItem = [delegate respondsToSelector:@selector(koala:collectionView:layout:sizeForItem:atIndexPath:)];
    _collectionViewDelegateFlags.viewForSupplementaryElementOfKind = [delegate respondsToSelector:@selector(koala:collectionView:viewForSupplementaryElementOfKind:atIndexPath:)];
    _collectionViewDelegateFlags.cellForItem = [delegate respondsToSelector:@selector(koala:collectionView:cellForItem:atIndexPath:)];
    [super setDelegate:delegate];
    // Regenerate delete response struct
    [self.collectionView setDataSource:self];
    [self.collectionView setDelegate:self];
}

- (id<KCDCollectionViewDataSourceDelegate, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>)delegate;
{
    return (id<KCDCollectionViewDataSourceDelegate, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>)[super delegate];
}

#pragma mark - KCDObjectController

#pragma mark Message Forwarding

- (NSArray *)forwardingProtocols;
{
    NSMutableArray *forwards = [NSMutableArray arrayWithArray:[super forwardingProtocols]];
    [forwards addObject:@protocol(UICollectionViewDelegate)];
    [forwards addObject:@protocol(UICollectionViewDelegateFlowLayout)];
    return forwards;
}

- (void)commitUpdate:(void(^)())action completion:(void(^)())completion;
{
    __block UICollectionView *__weak weakView = nil;
    if (!(weakView = _collectionView) || ![weakView superview]) {
        if (completion) { completion(); }
        return;
    }
    __block UICollectionView *__strong strongView = nil;
    void (^didFinish)(BOOL) = ^(BOOL finished) {
        dispatch_group_leave(_KCDAnimationGroup);
        if (completion) {
            completion();
        }
        strongView = nil;
    };
    dispatch_group_notify(_KCDAnimationGroup, _KCDAnimationQueue, ^{
        // This update is dispatched to the main thread, so we must wait on the group.
        dispatch_group_wait(_KCDAnimationGroup, DISPATCH_TIME_FOREVER);
        dispatch_group_enter(_KCDAnimationGroup);
        dispatch_async(dispatch_get_main_queue(), ^{
            // We need a strong reference to guarantee the didFinish block is called.
            if ((strongView = weakView)) {
                [strongView performBatchUpdates:action
                                     completion:didFinish];
            }
            else {
                // The view has been removed.
                didFinish(NO);
            }
        });
    });
}

#pragma mark Pipelining


- (void)reloadViewsAtIndexPaths:(NSArray *)indexPaths withAnimation:(NSInteger)animation;
{
    [self.collectionView reloadItemsAtIndexPaths:indexPaths];
}

- (void)insertSectionsViews:(NSIndexSet*)indexSet withAnimation:(NSInteger)animation;
{
    [self.collectionView insertSections:indexSet];
}

- (void)deleteSectionViews:(NSIndexSet *)indexSet withAnimation:(NSInteger)animation;
{
    [self.collectionView deleteSections:indexSet];
}

- (void)moveSectionViewAtIndex:(NSInteger)fromIndex toSectionIndex:(NSInteger)toIndex;
{
    [self.collectionView moveSection:fromIndex toSection:toIndex];
}

- (void)reloadSectionViews:(NSIndexSet *)indexSet withAnimation:(NSInteger)animation;
{
    [self.collectionView reloadSections:indexSet];
}

- (void)insertViewsAtIndexPaths:(NSArray *)indexPaths withAnimation:(NSInteger)animation;
{
    [self.collectionView insertItemsAtIndexPaths:indexPaths];
}

- (void)deleteViewsAtIndexPaths:(NSArray *)indexPaths withAnimation:(NSInteger)animation;
{
    [self.collectionView deleteItemsAtIndexPaths:indexPaths];
}

- (void)moveViewAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)targetIndexPath;
{
    [self.collectionView moveItemAtIndexPath:sourceIndexPath toIndexPath:targetIndexPath];
}

- (NSArray *)indexPathsForSelectedViews;
{
    return [self.collectionView indexPathsForSelectedItems];
}

- (void)reloadData;
{
    [self.collectionView reloadData];
}

#pragma mark - UICollectionViewDataSource

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView
           viewForSupplementaryElementOfKind:(NSString *)kind
                                 atIndexPath:(NSIndexPath *)indexPath;
{
    UICollectionReusableView *view = nil;
    if (_collectionViewDelegateFlags.viewForSupplementaryElementOfKind) {
        view = [self.delegate koala:self
                     collectionView:collectionView
           viewForSupplementaryElementOfKind:kind
                                 atIndexPath:indexPath];
    }
    else {
        view = [collectionView dequeueReusableSupplementaryViewOfKind:kind
                                                  withReuseIdentifier:NSStringFromClass([KCDReusableView class])
                                                         forIndexPath:indexPath];
        view.backgroundColor = KCDRandomColor();
    }
    
    return view;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath;
{
    UICollectionViewCell *cell = nil;
    id <KCDCollectionViewObject> cellObject = nil;
    if ((cellObject = (id<KCDCollectionViewObject>)[self objectAtIndexPath:indexPath]))
    {
        if (_collectionViewDelegateFlags.cellForItem) {
            cell = [self.delegate koala:self
                         collectionView:collectionView
                                     cellForItem:cellObject
                                     atIndexPath:indexPath];
        }
        else {
            cell = [cellObject cellForCollectionView:collectionView atIndexPath:indexPath];
        }
    }
    NSAssert(cell,
             @"%@ did not return a collection view cell for %@",
             NSStringFromClass([self class]),
             indexPath);
    return cell;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView;
{
    NSInteger sectionCount = [_KCDSectionObjects count];
    NSAssert(sectionCount >= 0, @"Invalid section count: %@", @(sectionCount));
    return sectionCount;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section;
{
    id<KCDSection> sectionObject = _KCDSectionObjects[section];
    NSInteger numberOfItems = [sectionObject.objects count];
    NSAssert(numberOfItems >= 0, @"Invalid item count for section %@: %@", @(section), @(numberOfItems));
    return numberOfItems;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath;
{
    if ([self.delegate respondsToSelector:_cmd]) {
        [(id<UICollectionViewDelegate>)self.delegate collectionView:collectionView didSelectItemAtIndexPath:indexPath];
    }
    else if ([self.delegate respondsToSelector:@selector(koala:collectionView:didSelectItem:atIndexPath:)]) {
        [self queueTransaction:^(KCDObjectController<KCDIntrospective> *koala) {
            [self.delegate koala:self collectionView:collectionView didSelectItem:[koala objectAtIndexPath:indexPath] atIndexPath:indexPath];
        }];
    }
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath;
{
    id<KCDCollectionViewObject>cellObject = nil;
    if ((cellObject = (id<KCDCollectionViewObject>)[self objectAtIndexPath:indexPath])) {
        if (_collectionViewDelegateFlags.sizeForItem) {
            return [self.delegate koala:self
                         collectionView:collectionView
                                 layout:collectionViewLayout
                            sizeForItem:cellObject
                            atIndexPath:indexPath];
        }
        else if ([cellObject respondsToSelector:@selector(sizeForCollectionView:layout:)]) {
            return [cellObject sizeForCollectionView:collectionView layout:collectionViewLayout];
        }
    }
    NSAssert(cellObject, @"%@ returned nil cell object for %@", NSStringFromClass([self class]), indexPath);
    return CGSizeMake(44.0f, 44.0f);
}

@end

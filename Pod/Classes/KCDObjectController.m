//
//  KCDObjectController.m
//
//  Created by Nicholas Zeltzer on 11/2/11.
//  Copyright (c) 2011. All rights reserved.
//

#import "KCDObjectController.h"
#import "KCDSectionContainer.h"
#import "KCDUtilities.h"
#import <objc/runtime.h>

#define KCDIllegalStackCheck [self KCDIllegalStackCheckAndAssert]
#define Koala_Should_LogMethodCalls 0
#define KCDDiffLogEnabled 0

#if KCDDiffLogEnabled
#define KCDSectionDiffLog(...) NSLog(__VA_ARGS__)
#else
#define KCDSectionDiffLog(...) /**/
#endif

// Verbose method logging.

#if Koala_Should_LogMethodCalls
#define Koala_LogMethodCall NSLog(@"%@", NSStringFromSelector(_cmd))
#define Koala_LogMethodCallWithArg(...) NSLog(@"%@ %@", NSStringFromSelector(_cmd), __VA_ARGS__)
#else
#define Koala_LogMethodCall /* */
#define Koala_LogMethodCallWithArg(...) /* */
#endif

// General logging variations.

#ifndef VLog
// Verbose logging (for deep analysis)
#define VLog(...) /**/
#endif
#ifndef ALog
// Always enabled logging
#define ALog(...) NSLog(@"%s %@", __PRETTY_FUNCTION__, [NSString stringWithFormat:__VA_ARGS__])
#endif
#ifndef DLog
#ifdef DEBUG
// Debug build logging.
#define DLog(...) NSLog(@"%s %@", __PRETTY_FUNCTION__, [NSString stringWithFormat:__VA_ARGS__])
#else
#define DLog(...) /**/
#endif
#endif


NSString * const kKCDSectionObjects = @"sectionObjects";
NSString * const kKCDCellObjects = @"cellObjects";
NSString * const kKCDTransactionCount = @"transactionCount";

#pragma mark - KCDObjectController Class Extension -

@interface KCDObjectController() <KCDIntrospective, KCDInternalTransactions, KCDViewUpdates>

@property (nonatomic, readwrite, strong) NSMutableArray *sectionObjects;
@property (nonatomic, readonly, strong) NSArray *sectionSortDescriptors;

/** Sorts equated arrays of objects and index paths by index path value. */

void KCDSortObjectsAndIndexPaths(NSArray ** objects, NSArray ** indexPaths);

/** Returns a mutable copy of the sections array that contains copies of each section object. */

NSMutableArray * KCDMutableCopySectionsArray(NSArray *sectionObjects);

@end

#pragma mark - KCDObjectController Implementation -

@implementation KCDObjectController

NSInteger const * KCDTransactionCountContext;

@synthesize delegate = _delegate;

@dynamic sections;
@dynamic objects;
@dynamic sectionObjects;
@dynamic objectCount;
@dynamic sectionCount;
@dynamic allIndexPaths;

#pragma mark - Initialization

- (instancetype)initWithDelegate:(id<KCDObjectControllerDelegate>)delegate
                        sections:(NSArray *)KCDSections;
{
    self = [super init];
    if (self) {
        DLog(@"[+] %@", NSStringFromClass([self class]));
        [self setDelegate:delegate]; // Necessary to trigger delegate flag setup.
        _KCDSectionObjects = ([KCDSections count] > 0) ? [NSMutableArray arrayWithArray:KCDSections] : [NSMutableArray arrayWithArray:@[KCDNewSectionWithNameAndObjects(nil, nil)]];
        _KCDAnimationQueue = dispatch_queue_create("com.koala.animate", DISPATCH_QUEUE_SERIAL);
        _KCDAnimationGroup = dispatch_group_create();
        _KCDTransactionQueue = dispatch_queue_create("com.koala.update", DISPATCH_QUEUE_SERIAL);
        _KCDTransactionGroup = dispatch_group_create();
        [self addObserver:self
               forKeyPath:kKCDTransactionCount
                  options:kNilOptions
                  context:&KCDTransactionCountContext];
        [self addObserver:self
               forKeyPath:kKCDSectionObjects
                  options:kNilOptions
                  context:&KCDTransactionCountContext];
    }
    return self;
}

- (instancetype)initWithDelegate:(id<KCDObjectControllerDelegate>)delegate;
{
    self = [self initWithDelegate:delegate sections:nil];
    if (self) {
        
    }
    return self;
}

- (void)dealloc;
{
    [self removeObserver:self
              forKeyPath:kKCDTransactionCount
                 context:&KCDTransactionCountContext];
    [self removeObserver:self
              forKeyPath:kKCDSectionObjects
                 context:&KCDTransactionCountContext];
    DLog(@"[-] %@", NSStringFromClass([self class]));
}

#pragma mark - KVO

- (void)incrementTransactionCount;
{
    [self willChangeValueForKey:kKCDTransactionCount];
    _KCDTransactionCount++;
    [self didChangeValueForKey:kKCDTransactionCount];
}

- (void)decrementTransactionCount;
{
    [self willChangeValueForKey:kKCDTransactionCount];
    _KCDTransactionCount--;
    [self didChangeValueForKey:kKCDTransactionCount];
}

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key;
{
    if ([key isEqualToString:@"sections"]) {
        // KVO "sections" is a dynamic readonly property derived from sectionObjects;
        // observers must be notified when the underlying property: "sectionObjects" changes.
        return [NSSet setWithObjects:kKCDSectionObjects, nil];
    }
    if ([key isEqualToString:@"objects"]) {
        // Notify observers subscribing to dynamic objects property
        // when we've changed the private cellObjects property.
        return [NSSet setWithObjects:kKCDCellObjects, nil];
    }
    return [super keyPathsForValuesAffectingValueForKey:key];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context;
{
    if (context == &KCDTransactionCountContext) {
        if (keyPath == kKCDTransactionCount) {
            // For debugging purposes.
            KCDKoalaLog(@"%@ : %@",
                        keyPath,
                        @(_KCDTransactionCount));
        }
        if (keyPath == kKCDSectionObjects) {
            // For debugging purposes.
            KCDKoalaLog(@"%@ : %@",
                        keyPath,
                        @(_KCDSectionObjects.count));
        }
    }
}

#pragma mark - Message Forwarding

/**
 Where this class does not implement a method described in a forwarding protocol, we allow our delegate to step up and assume responsibility.
 */

/**
 An array of protocols that we will allow forwarding for.
 */

- (NSArray *)forwardingProtocols;
{
    
    /**
     Sublcasses should not forward data source protocol methods,
     as _any_ override might interfere with this implementation; this
     class _consumes_ the data source protocol.
     */
    
    return nil;
}

/**
 Returns YES if the method should be forwarded to our delegate.
 */

- (BOOL)shouldForwardMethodToDelegate:(SEL)aSelector;
{
    for (Protocol *aProtocol in [self forwardingProtocols])
    {
        if (KCDProtocolIncludesSelector(aProtocol, aSelector)) {
            if ([self.delegate respondsToSelector:aSelector]) {
                return YES;
            }
        }
    }
    return NO;
}

#pragma mark NSObject

/**
 If this class does not implement the method, check to see if it can be forwarded to our delegate.
 */

- (BOOL)respondsToSelector:(SEL)aSelector;
{
    BOOL responds = [super respondsToSelector:aSelector];
    if (!responds && [self shouldForwardMethodToDelegate:aSelector]) {
        return YES;
    }
    return responds;
}

/**
 This method will be called where an instance of this class returns YES to respondsToSelector, but does not implement the matching method.
 */

- (id)forwardingTargetForSelector:(SEL)aSelector;
{
    if ([self shouldForwardMethodToDelegate:aSelector]) {
        return [self delegate];
    }
    return [super forwardingTargetForSelector:aSelector];
}

#pragma mark - Transaction Queuing

- (void)commitUpdate:(void(^)())update
          completion:(void(^)())completion;
{
    // Submit the block to the animation group.
    // You can create bulk transactions by commiting several updates from within a single transaction.
    // See, e.g., queueArrangement:animation:completion:, infra.
    // See KCDCollectionViewDataSource and KCDTableViewDataSource for sample implementations.
    
    NSAssert(NO, @"Subclasses must implement %@", NSStringFromSelector(_cmd));
}


- (void)queueAction:(void(^)())action;
{
    [self queueTransaction:^(KCDObjectController *koala) {
        if (action) {
            action();
        }
    }];
}

- (void)queueTransaction:(void(^)(KCDObjectController<KCDIntrospective>*koala))action;
{
    // Schedule the block on on the transaction queue.
    [self incrementTransactionCount];
    KCDObjectController *__weak weakSelf = self;
    dispatch_group_notify(_KCDTransactionGroup, _KCDTransactionQueue, ^{
        dispatch_group_wait(_KCDTransactionGroup, DISPATCH_TIME_FOREVER);
        dispatch_group_enter(_KCDTransactionGroup);
        if (action) {
            action(weakSelf);
        }
        dispatch_group_leave(_KCDTransactionGroup);
        [weakSelf decrementTransactionCount];
    });
}

/**
 Schedules the block on the update queue; the block will be executed as an action with 'commitUpdate:completion:'.
 */

- (void)stageUpdate:(void(^)(KCDObjectController *koala))update;
{
    [self incrementTransactionCount];
    KCDObjectController *__weak weakSelf = self;
    dispatch_group_notify(_KCDTransactionGroup, _KCDTransactionQueue, ^{
        dispatch_group_wait(_KCDTransactionGroup, DISPATCH_TIME_FOREVER);
        dispatch_group_enter(_KCDTransactionGroup);
        [weakSelf commitUpdate:^{
            if (update) {
                update(weakSelf);
            }
        }
                    completion:^{
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(_KCDTransactionDelay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                            dispatch_group_leave(_KCDTransactionGroup);
                            [weakSelf decrementTransactionCount];
                        });
                    }];
    });
}

/**
 Schedules an action on the update queue that can be transacted asynchronously.
 @note This is primarily useful for grouping 'commitUpdate:completion:' calls.
 */

- (void)queueAsyncTransaction:(void(^)(KCDObjectController *koala, dispatch_block_t finished))action;
{
    // Schedule the block on on the transaction queue.
    [self incrementTransactionCount];
    KCDObjectController *__weak weakSelf = self;
    void (^didFinishCallback)() = ^(){
        dispatch_group_leave(_KCDTransactionGroup);
        [weakSelf decrementTransactionCount];
    };
    dispatch_group_notify(_KCDTransactionGroup, _KCDTransactionQueue, ^{
        dispatch_group_wait(_KCDTransactionGroup, DISPATCH_TIME_FOREVER);
        dispatch_group_enter(_KCDTransactionGroup);
        if (action) {
            action(weakSelf, didFinishCallback);
        }
        else {
            didFinishCallback();
        }
    });
}

- (void)queueArrangement:(void(^)(KCDObjectController<KCDIntrospective>* koala, NSMutableArray *sections))transaction
               animation:(NSInteger)animation
              completion:(void(^)(KCDObjectController<KCDIntrospective>* koala))completion;
{
    KCDObjectController *__weak weakSelf = self;
    [self queueAsyncTransaction:^(KCDObjectController *koala, dispatch_block_t finished) {
        NSMutableArray *sections = KCDMutableCopySectionsArray(_KCDSectionObjects);
        transaction(weakSelf, sections);
        [koala updateSections:sections
                    animation:animation
                   completion:^{
                       finished();
                       if (completion) {
                           completion(weakSelf);
                       }
                   }];
    }];
}

#pragma mark - Sections -

#pragma mark Inserting Sections

- (id<KCDSection>)addSectionWithName:(NSString *)sectionName
                             objects:(NSArray *)objects
                           animation:(NSInteger)animation;
{
    Koala_LogMethodCall;
    id<KCDSection>newSection = [self newSectionWithName:sectionName objects:objects];
    [self stageUpdate:^(KCDObjectController *koala) {
        [koala willChangeValueForKey:kKCDSectionObjects];
        [koala KCDInlineAddSection:newSection
                         animation:animation];
        [koala didChangeValueForKey:kKCDSectionObjects];
    }];
    return newSection;
}

- (id<KCDSection>)insertSectionWithName:(NSString *)sectionName
                                objects:(NSArray *)objects
                                atIndex:(NSInteger)index
                              animation:(NSInteger)animation;
{
    Koala_LogMethodCall;
    id<KCDSection>newSection = [self newSectionWithName:sectionName objects:objects];
    [self stageUpdate:^(KCDObjectController *koala) {
        [koala willChangeValueForKey:kKCDSectionObjects];
        NSAssert(index <= _KCDSectionObjects.count, @"Index %@ is out of bounds", @(index));
        NSInteger insertion = MIN(_KCDSectionObjects.count, index);
        [koala KCDInlineInsertSection:newSection
                              atIndex:insertion
                            animation:animation];
        [koala didChangeValueForKey:kKCDSectionObjects];
    }];
    return newSection;
}

- (void)insertSection:(id<KCDSection, NSCopying>)aSection
              atIndex:(NSUInteger)index
            animation:(NSInteger)animation;
{
    Koala_LogMethodCall;
    [self stageUpdate:^(KCDObjectController *koala) {
        [koala willChangeValueForKey:kKCDSectionObjects];
        NSAssert(index <= _KCDSectionObjects.count,
                 @"Index %@ is out of bounds", @(index));
        NSInteger target = MIN([koala->_KCDSectionObjects count], index);
        id<KCDSection> sectionCopy = [(id)aSection copy];
        [koala KCDInlineInsertSection:sectionCopy
                              atIndex:target
                            animation:animation];
        [koala didChangeValueForKey:kKCDSectionObjects];
    }];
}

- (void)addSections:(NSArray *)sections
          animation:(NSInteger)animation;
{
    Koala_LogMethodCall;
    [self stageUpdate:^(KCDObjectController *koala) {
        NSInteger index = koala->_KCDSectionObjects.count;
        for (id<KCDSection>aSection in sections)
        {
            [koala willChangeValueForKey:kKCDSectionObjects];
            id<KCDSection> sectionCopy = [(id)aSection copy];
            [koala KCDInlineInsertSection:sectionCopy
                                  atIndex:index++
                                animation:animation];
            [koala didChangeValueForKey:kKCDSectionObjects];
        }
    }];
}

- (void)addSection:(id<KCDSection, NSCopying>)section
         animation:(NSInteger)animation;
{
    Koala_LogMethodCall;
    [self stageUpdate:^(KCDObjectController *koala) {
        [koala willChangeValueForKey:kKCDSectionObjects];
        id<KCDSection> sectionCopy = [(id)section copy];
        NSInteger index = [koala->_KCDSectionObjects count];
        [koala KCDInlineInsertSection:sectionCopy
                              atIndex:index
                            animation:animation];
        [koala didChangeValueForKey:kKCDSectionObjects];
    }];
}

#pragma mark Moving Sections

- (void)moveSection:(id<KCDSection>)sourceSection
            toIndex:(NSUInteger)targetIndex;
{
    Koala_LogMethodCall;
    [self stageUpdate:^(KCDObjectController *koala) {
        [koala willChangeValueForKey:kKCDSectionObjects];
        [koala KCDInlineMoveSection:sourceSection
                            toIndex:targetIndex];
        [koala didChangeValueForKey:kKCDSectionObjects];
    }];
}

- (void)moveSections:(NSArray *)sections
           toIndices:(NSArray *)indices;
{
    Koala_LogMethodCall;
    [self stageUpdate:^(KCDObjectController *koala) {
        [koala willChangeValueForKey:kKCDSectionObjects];
        [koala KCDInlineMoveSections:sections
                           toIndices:indices];
        [koala didChangeValueForKey:kKCDSectionObjects];
    }];
}

- (void)moveSectionsAtIndices:(NSArray *)fromIndices
                    toIndices:(NSArray *)toIndices;
{
    [self stageUpdate:^(KCDObjectController *koala) {
        [koala willChangeValueForKey:kKCDSectionObjects];
        NSAssert(fromIndices.count == toIndices.count, @"From/To index mismatch");
        if (fromIndices.count == toIndices.count) {
            NSMutableArray *sections = [NSMutableArray new];
            NSMutableArray *indices = [NSMutableArray new];
            [fromIndices enumerateObjectsUsingBlock:^(NSNumber *from, NSUInteger idx, BOOL *stop) {
                id<KCDSection> aSection = nil;
                if ((aSection = [self sectionAtIndex:from.integerValue])) {
                    [sections addObject:aSection];
                    [indices addObject:toIndices[idx]];
                }
                NSAssert(aSection, @"There is no section at index %@", @(from.integerValue));
            }];
            [koala KCDInlineMoveSections:sections
                               toIndices:indices];
        }
        [koala didChangeValueForKey:kKCDSectionObjects];
    }];
}

- (void)moveSectionAtIndex:(NSUInteger)fromIndex
                   toIndex:(NSUInteger)toIndex;
{
    Koala_LogMethodCall;
    [self stageUpdate:^(KCDObjectController *koala) {
        [koala willChangeValueForKey:kKCDSectionObjects];
        id <KCDSection> aSection = nil;
        if ((aSection = [koala sectionAtIndex:fromIndex])) {
            [koala KCDInlineMoveSection:aSection
                                toIndex:toIndex];
        }
        NSAssert(aSection, @"There is no section at index %@", @(fromIndex));
        [koala didChangeValueForKey:kKCDSectionObjects];
    }];
}

#pragma mark Deleting Sections

- (void)deleteSection:(id<KCDSection>)section
            animation:(NSInteger)animation;
{
    Koala_LogMethodCall;
    [self stageUpdate:^(KCDObjectController *koala) {
        [koala willChangeValueForKey:kKCDSectionObjects];
        [koala KCDInlineDeleteSections:@[section]
                             animation:animation];
        [koala didChangeValueForKey:kKCDSectionObjects];
    }];
}

- (void)deleteSectionsWithIndices:(NSIndexSet*)sectionIndexSet
                        animation:(NSInteger)animation;
{
    Koala_LogMethodCall;
    [self stageUpdate:^(KCDObjectController *koala) {
        [koala willChangeValueForKey:kKCDSectionObjects];
        [koala KCDInlineDeleteSectionsWithIndices:sectionIndexSet
                                        animation:animation];
        [koala didChangeValueForKey:kKCDSectionObjects];
    }];
}

- (void)deleteSectionAtIndex:(NSUInteger)index
                   animation:(NSInteger)animation;
{
    Koala_LogMethodCall;
    [self stageUpdate:^(KCDObjectController *koala) {
        [koala willChangeValueForKey:kKCDSectionObjects];
        [koala KCDInlineDeleteSectionsWithIndices:[NSIndexSet indexSetWithIndex:index]
                                        animation:animation];
        [koala didChangeValueForKey:kKCDSectionObjects];
    }];
}

- (void)deleteAllSections:(NSInteger)animation;
{
    Koala_LogMethodCall;
    [self stageUpdate:^(KCDObjectController *koala) {
        [koala willChangeValueForKey:kKCDSectionObjects];
        [koala KCDInlineDeleteSections:[koala->_KCDSectionObjects copy]
                             animation:animation];
        [koala didChangeValueForKey:kKCDSectionObjects];
    }];
}

#pragma mark Sorting Sections

- (void)sortSectionsUsingDescriptors:(NSArray *)descriptors;
{
    Koala_LogMethodCall;
    [self stageUpdate:^(KCDObjectController *koala) {
        [koala willChangeValueForKey:kKCDSectionObjects];
        [koala KCDInlineSortSectionsusingDescriptors:descriptors];
        [koala didChangeValueForKey:kKCDSectionObjects];
    }];
}

- (void)sortSectionsWithComparator:(NSComparator)comparator;
{
    Koala_LogMethodCall;
    [self stageUpdate:^(KCDObjectController *koala) {
        [koala willChangeValueForKey:kKCDSectionObjects];
        [koala KCDInlineSortSectionsWithComparator:comparator];
        [koala didChangeValueForKey:kKCDSectionObjects];
    }];
}

#pragma mark - Objects -

#pragma mark Inserting Objects

- (void)insertObjects:(NSArray*)objects
         atIndexPaths:(NSArray*)indexPaths
            animation:(NSInteger)animation;
{
    Koala_LogMethodCall;
    [self stageUpdate:^(KCDObjectController *koala) {
        [koala KCDInlineInsertObjects:objects
                         atIndexPaths:indexPaths
                            animation:animation];
    }];
}

- (void)insertObject:(id<KCDObject>)object
         atIndexPath:(NSIndexPath*)indexPath
           animation:(NSInteger)animation;
{
    Koala_LogMethodCall;
    [self stageUpdate:^(KCDObjectController *koala) {
        [koala KCDInlineInsertObjects:@[object]
                         atIndexPaths:@[indexPath]
                            animation:animation];
    }];
}

- (void)addObjects:(NSArray*)objects
         toSection:(KCDSectionContainer*)section
         animation:(NSInteger)animation;
{
    Koala_LogMethodCall;
    [self stageUpdate:^(KCDObjectController *koala) {
        id<KCDSection> localSection = nil;
        if ((localSection = [koala localSectionForSection:section])) {
            [koala KCDInlineAddObjects:objects
                             toSection:localSection
                             animation:animation];
        }
    }];
}

- (void)addObjects:(NSArray*)objects // by reference
  toSectionAtIndex:(NSUInteger)index
         animation:(NSInteger)animation;
{
    Koala_LogMethodCall;
    [self stageUpdate:^(KCDObjectController *koala) {
        id <KCDSection> section = nil;
        if ((section = [koala sectionAtIndex:index])) {
            [koala KCDInlineAddObjects:objects
                             toSection:section
                             animation:animation];
        }
        else {
            DLog(@"Failed to get section for index: %@", @(index));
        }
        NSAssert(section, @"Invalid section index: %@", @(index));
    }];
}

#pragma mark Moving Objects

- (void)moveObject:(id<KCDObject>)cellObject
       toIndexPath:(NSIndexPath *)indexPath;
{
    [self moveObjects:@[cellObject] toIndexPaths:@[indexPath]];
}

- (void)moveObjects:(NSArray *)objects
       toIndexPaths:(NSArray *)indexPaths;
{
    Koala_LogMethodCall;
    [self stageUpdate:^(KCDObjectController *koala) {
        [koala KCDInlineMoveObjects:objects
                       toIndexPaths:indexPaths];
    }];
}

- (void)moveObjectsAtIndexPaths:(NSArray*)fromIndexPaths
                   toIndexPaths:(NSArray*)toIndexPaths;
{
    Koala_LogMethodCall;
    [self stageUpdate:^(KCDObjectController *koala) {
        [koala KCDInlineMoveObjectsAtIndexPaths:fromIndexPaths
                                   toIndexPaths:toIndexPaths];
    }];
}
#pragma mark Deleting Objects

- (void)deleteObject:(id<KCDObject>)object
           animation:(NSInteger)animation;
{
    Koala_LogMethodCall;
    [self stageUpdate:^(KCDObjectController *koala) {
        [koala KCDInlineDeleteObjects:@[object]
                            animation:animation];
    }];
}

- (void)deleteObjectAtIndexPath:(NSIndexPath*)indexPath
                      animation:(NSInteger)animation;
{
    Koala_LogMethodCall;
    [self stageUpdate:^(KCDObjectController *koala) {
        [koala KCDInlineDeleteObjectAtIndexPath:indexPath
                                      animation:animation];
    }];
}

- (void)deleteObjectAtSection:(NSUInteger)section
                          row:(NSUInteger)row
                    animation:(NSInteger)animation;
{
    Koala_LogMethodCall;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
    [self deleteObjectAtIndexPath:indexPath
                        animation:animation];
}

- (void)deleteObjects:(NSArray*)objects
            animation:(NSInteger)animation;
{
    Koala_LogMethodCall;
    [self stageUpdate:^(KCDObjectController *koala) {
        [koala KCDInlineDeleteObjects:objects
                            animation:animation];
    }];
}

- (void)deleteObjectsAtIndexPaths:(NSArray*)indexPaths
                        animation:(NSInteger)animation;
{
    Koala_LogMethodCall;
    [self stageUpdate:^(KCDObjectController *koala) {
        [koala KCDInlineDeleteObjectsAtIndexPaths:indexPaths
                                        animation:animation];
    }];
}

#pragma mark Sorting Objects

- (void)sortSection:(id<KCDSection>)section
    usingComparator:(NSComparator)cmptr
          animation:(NSInteger)animation;
{
    Koala_LogMethodCall;
    [self stageUpdate:^(KCDObjectController *koala) {
        NSInteger sectionIndex = [koala indexForSection:section];
        [koala KCDInlineSortSectionAtIndex:sectionIndex
                           usingComparator:cmptr];
    }];
}

- (void)sortSection:(id<KCDSection>)section
   usingDescriptors:(NSArray *)descriptors
          animation:(NSInteger)animation;
{
    Koala_LogMethodCall;
    [self stageUpdate:^(KCDObjectController *koala) {
        NSInteger sectionIndex = [koala indexForSection:section];
        [koala KCDInlineSortSectionAtIndex:sectionIndex
                          usingDescriptors:descriptors];
    }];
}


- (void)sortSectionAtIndex:(NSUInteger)sectionIndex
           usingComparator:(NSComparator)cmptr;
{
    Koala_LogMethodCall;
    [self stageUpdate:^(KCDObjectController *koala) {
        [koala KCDInlineSortSectionAtIndex:sectionIndex
                           usingComparator:cmptr];
    }];
    
}

- (void)sortSectionAtIndex:(NSUInteger)index
          usingDescriptors:(NSArray*)descriptors;
{
    Koala_LogMethodCall;
    [self stageUpdate:^(KCDObjectController *koala) {
        [koala KCDInlineSortSectionAtIndex:index
                          usingDescriptors:descriptors];
    }];
}


#pragma mark Filtering Objects

- (void)filterSectionAtIndex:(NSUInteger)sectionIndex
                   predicate:(NSPredicate*)predicate
                   animation:(NSInteger)animation;
{
    Koala_LogMethodCall;
    [self stageUpdate:^(KCDObjectController *koala) {
        [koala KCDInlineFilterSectionAtIndex:sectionIndex
                                   predicate:predicate
                                   animation:animation];
    }];
}

- (void)filterWithPredicate:(NSPredicate*)predicate
                  animation:(NSInteger)animation;
{
    Koala_LogMethodCall;
    [self stageUpdate:^(KCDObjectController *koala) {
        [koala KCDInlineFilterWithPredicate:predicate
                                  animation:animation];
    }];
}

#pragma mark Reloading Objects

- (void)reloadItemsAtIndexPaths:(NSArray*)indexPaths
                      animation:(NSInteger)animation;
{
    Koala_LogMethodCall;
    [self stageUpdate:^(KCDObjectController *koala) {
        [koala KCDInlineReloadObjectsAtIndexPaths:indexPaths
                                        animation:animation];
    }];
}

#pragma mark - Enumeration

- (void)KCDInlineEnumerate:(void(^)(id<KCDObject>object, id<KCDSection>section, NSIndexPath *(^indexPath)(), BOOL *stop))block;
{
    __block BOOL exit = NO;
    __block NSInteger _currentRow;
    __block NSInteger _currentSection;
    static NSIndexPath *(^indexPath)() = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        indexPath = ^NSIndexPath * {
            return [NSIndexPath indexPathForRow:_currentRow inSection:_currentSection];
        };
    });
    [_KCDSectionObjects enumerateObjectsUsingBlock:^(id<KCDSection> sec, NSUInteger s, BOOL *stop) {
        _currentSection = s;
        [sec enumerateObjectsUsingBlock:^(id<KCDObject>obj, NSUInteger r, BOOL *stop) {
            _currentRow = r;
            block(obj, sec, indexPath, &exit);
            *stop = exit;
        }];
        *stop = exit;
    }];
}

- (void)enumerateObjectsUsingBlock:(void(^)(id<KCDObject>object, id<KCDSection>section, NSIndexPath *(^indexPath)(), BOOL *stop))block;
{
    [self KCDInlineEnumerate:block];
}

#pragma mark - Accessors

- (NSArray *)allIndexPaths;
{
    NSMutableArray *paths = [NSMutableArray new];
    [self.sectionObjects enumerateObjectsUsingBlock:^(id<KCDSection>aSection, NSUInteger idx, BOOL *stop) {
        for (NSInteger x = 0; x < aSection.count; x++)
        {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:x inSection:idx];
            [paths addObject:indexPath];
        }
    }];
    return paths;
}

- (NSInteger)objectCount;
{
    NSInteger count = 0;
    for (id<KCDSection> aSection in self.sectionObjects) {
        count += aSection.count;
    }
    return count;
}

- (NSInteger)sectionCount;
{
    return self.sectionObjects.count;
}

- (id<KCDSection>)localSectionForSection:(id<KCDSection>)section;
{
    NSInteger sectionIndex;
    if ((sectionIndex = [_KCDSectionObjects indexOfObject:section]) != NSNotFound) {
        NSAssert([section isEqual:_KCDSectionObjects[sectionIndex]], @"The section does not equate.");
        DLog(@"%@ %@", @(sectionIndex), _KCDSectionObjects[sectionIndex]);
        return _KCDSectionObjects[sectionIndex];
    }
    ALog(@"Failed to lock local section");
    return nil;
}

- (void)setSections:(NSArray *)sections;
{
    NSAssert([NSThread isMainThread],
             @"Attempt to set section off of main thread");
    NSMutableArray *localSections = [NSMutableArray new];
    for (id<KCDSection> aSection in sections) {
        id<KCDSection> sectionCopy = [(id)aSection copy];
        [localSections addObject:sectionCopy];
    }
    [self setSectionObjects:localSections];
    [self reloadData];
}

- (NSArray*)sections;
{
    @synchronized(_KCDSectionObjects) {
        return _KCDSectionObjects;
    }
}

- (NSArray *)objects;
{
    return [self allObjects];
}

- (NSArray*)allObjects;
{
    NSMutableArray *allObjects = [NSMutableArray array];
    for (id<KCDSection> aSection in _KCDSectionObjects)
    {
        [allObjects addObjectsFromArray:aSection.objects.array];
    }
    return allObjects;
}

- (NSArray*)selectedObjects;
{
    NSArray *indexPaths = nil;
    NSMutableArray *selectedObjects = nil;
    if ((indexPaths = [self indexPathsForSelectedViews]))
    {
        selectedObjects = [NSMutableArray arrayWithCapacity:[indexPaths count]];
        for (NSIndexPath *anIndexPath in indexPaths)
        {
            id <KCDObject> anObject = nil;
            if ((anObject = [self objectAtIndexPath:anIndexPath]))
            {
                [selectedObjects addObject:anObject];
            }
        }
    }
    return selectedObjects;
}

- (NSMutableArray *)sectionObjects;
{
    return _KCDSectionObjects;
}

- (void)resetSections:(NSArray *)sections;
{
    NSMutableArray *sectionCopies = KCDMutableCopySectionsArray(sections);
    [self setSectionObjects:sectionCopies];
    [self reloadData];
}

- (void)setSectionObjects:(NSMutableArray *)sectionObjects;
{
    [self willChangeValueForKey:kKCDSectionObjects];
    _KCDSectionObjects = sectionObjects;
    [self didChangeValueForKey:kKCDSectionObjects];
}

- (void)setSections:(NSArray *)sections
          animation:(NSInteger)animation
         completion:(void(^)())completion;
{
    
    NSMutableArray *sectionCopies = KCDMutableCopySectionsArray(sections);
    [self queueAsyncTransaction:^(KCDObjectController *koala, dispatch_block_t finished) {
        [koala updateSections:sectionCopies
                    animation:animation
                   completion:^{
                       finished();
                       if (completion) {
                           completion();
                       }
                   }];
    }];
}

#pragma mark - Introspection

- (BOOL)containsObject:(id<KCDObject>)anObject;
{
    for (id<KCDSection> aSection in _KCDSectionObjects)
    {
        if ([aSection containsObject:anObject]) {
            return YES;
        }
    }
    return NO;
}

- (NSArray *)objectsForIndexPaths:(NSArray *)indexPaths;
{
    NSMutableArray *objects = [NSMutableArray new];
    for (NSIndexPath *aPath in indexPaths)
    {
        id<KCDObject>anObject = nil;
        if ((anObject = [self objectAtIndexPath:aPath])) {
            [objects addObject:anObject];
        }
    }
    return objects;
}

/**
 Returns an array of index paths for the objects, in the same sequence as the objects.
 */

- (NSArray*)indexPathsForObjects:(NSArray*)objects;
{
    KCDStrictAssert(objects.count > 0, @"Zero or nil objects");
    if (objects.count == 0) {
        return nil;
    }
    
    // Maintain a running list of objects that we need to find.
    NSMutableSet *remainingObjects = [NSMutableSet setWithArray:objects];
    NSInteger sectionCount = _KCDSectionObjects.count;
    // We need to keep track of which index paths go with what objects:
    // allocate a buffer for NSIndexPath pointers.
    size_t indexPathSize = class_getInstanceSize([NSIndexPath class]);
    NSIndexPath *__unsafe_unretained * paths = NULL;
    if (!(paths = (NSIndexPath *__unsafe_unretained *)calloc(objects.count, indexPathSize))) {
        ALog(@"Failed to allocate index path buffer");
        return nil;
    }
    // Iterate over the sections
    for (NSInteger sIndex = 0; sIndex < sectionCount; sIndex++)
    {
        // Use an intersection to find which objects this section contains.
        NSOrderedSet *sectionObjects = [(id<KCDSection>)_KCDSectionObjects[sIndex] objects];
        NSMutableSet *foundObjects = [NSMutableSet setWithSet:sectionObjects.set];
        [foundObjects intersectSet:remainingObjects];
        // Iterate over the found objects and collect their indices.
        for (id<KCDObject> anObject in foundObjects)
        {
            NSInteger row;
            if ((row = [sectionObjects indexOfObject:anObject]) != NSNotFound) {
                // Get the corresponding object index.
                NSInteger oIndex = [objects indexOfObject:anObject];
                // Keep ARC from releasing the index path.
                NS_VALID_UNTIL_END_OF_SCOPE NSIndexPath * aPath = [NSIndexPath indexPathForRow:row inSection:sIndex];
                // Store the index path at the index corresponding to the object.
                paths[oIndex] = aPath;
            }
            NSAssert(row != NSNotFound, @"No index for object.");
        }
        // Remove the found objects from the remaining objects.
        [remainingObjects minusSet:foundObjects];
    }
    NSAssert(remainingObjects.count == 0,
             @"Failed to locate index paths for %@ objects", @(remainingObjects.count));
    
    // Collect the index paths.
    NSMutableArray *indexPaths = [NSMutableArray new];
    for (NSInteger x = 0; x < objects.count; x++)
    {
        NSIndexPath *aPath = nil;
        if ((aPath = paths[x])) {
            [indexPaths addObject:aPath];
        }
    }
    // Cleanup and return.
    free(paths);
    return indexPaths;
}

- (NSIndexPath*)indexPathForObject:(id<KCDObject>)object;
{
    NSAssert(object, @"Attempt to get index path for nil object");
    if (!object) {
        return nil;
    }
    NSIndexPath *matchedPath = nil;
    NSInteger sectionIndex = 0;
    for (id<KCDSection> aSection in _KCDSectionObjects)
    {
        NSInteger row;
        if ((row = [aSection.objects indexOfObject:object]) != NSNotFound) {
            matchedPath = [NSIndexPath indexPathForRow:row inSection:sectionIndex];
            break;
        }
        sectionIndex++;
    }
    NSAssert(matchedPath, @"Nil index path for %@", object);
    return matchedPath;
}

- (id<KCDObject>)objectAtIndexPath:(NSIndexPath*)indexPath;
{
    id<KCDObject>object = nil;
    if (indexPath.section < _KCDSectionObjects.count) {
        id<KCDSection> section = _KCDSectionObjects[indexPath.section];
        if (indexPath.row < section.objects.count) {
            object = [section objectAtIndex:indexPath.row];
        }
    }
    return object;
}

- (id<KCDMutableSection>)sectionAtIndex:(NSUInteger)sectionIndex;
{
    id<KCDMutableSection>section = nil;
    if (sectionIndex < [_KCDSectionObjects count]) {
        section = [_KCDSectionObjects objectAtIndex:sectionIndex];
    }
    KCDStrictAssert(section, @"Section index out of bounds: %@", @(sectionIndex));
    return section;
}

- (NSUInteger)indexForSection:(id<KCDSection>)aSection;
{
    NSInteger index;
    if ((index = [_KCDSectionObjects indexOfObject:aSection]) == NSNotFound) {
        ALog(@"An index for the provided section could not be found.");
    }
    NSAssert(index != NSNotFound, @"Index could not be found for section: %@", aSection);
    return index;
}

#pragma mark - Factory Methods

+ (id<KCDMutableSection>)sectionWithName:(NSString *)sectionName objects:(NSArray *)objects;
{
    return (id<KCDSortableSection>)KCDNewSectionWithNameAndObjects(sectionName, objects);
}

- (id<KCDMutableSection>)newSectionWithName:(NSString *)sectionName objects:(NSArray *)objects;
{
    return [[self class] sectionWithName:sectionName objects:objects];
}

#pragma mark - KCDObjectControllerViewUpdates -

/**
 These methods describe specific functionality that subclasses must implement.
 */

- (void)insertSectionsViews:(NSIndexSet*)indexSet withAnimation:(NSInteger)animation;
{
    NSAssert(NO, @"This method must be subclassed");
}

- (void)deleteSectionViews:(NSIndexSet *)indexSet withAnimation:(NSInteger)animation;
{
    NSAssert(NO, @"This method must be subclassed");
}

- (void)reloadSectionViews:(NSIndexSet *)indexSet withAnimation:(NSInteger)animation;
{
    NSAssert(NO, @"This method must be subclassed");
}

- (void)moveSectionViewAtIndex:(NSInteger)fromIndex toSectionIndex:(NSInteger)toIndex;
{
    NSAssert(NO, @"This method must be subclassed");
}

- (void)insertViewsAtIndexPaths:(NSArray *)indexPaths withAnimation:(NSInteger)animation;
{
    NSAssert(NO, @"This method must be subclassed");
}

- (void)deleteViewsAtIndexPaths:(NSArray *)indexPaths withAnimation:(NSInteger)animation;
{
    NSAssert(NO, @"This method must be subclassed");
}

- (void)reloadViewsAtIndexPaths:(NSArray *)indexPaths withAnimation:(NSInteger)animation;
{
    NSAssert(NO, @"This method must be subclassed");
}

- (void)moveViewAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)targetIndexPath;
{
    NSAssert(NO, @"This method must be subclassed");
}

- (NSArray *)indexPathsForSelectedViews;
{
    NSAssert(NO, @"This method must be subclassed");
    return nil;
}

- (void)reloadData;
{
    NSAssert(NO, @"This method must be subclassed");
}

#pragma mark - KCDInternalTransactions -

/**
 These methods are not dispatched onto a specific queue and are safe to be called from within performBatchUpdates:completion:.
 */

#pragma mark Sections

- (void)KCDInlineInsertSection:(id<KCDSection>)aSection
                       atIndex:(NSUInteger)index
                     animation:(NSInteger)animation;
{
    if ([_KCDSectionObjects containsObject:aSection]) {
        DLog(@"Section already present: %@", aSection);
        // This section, or a variation, is already present.
        // Assume that we're replacing the section with a modified copy
        // and delete the equivalent section from the stack.
        [self KCDInlineDeleteSections:@[aSection] animation:animation];
    }
    NSAssert(index <= _KCDSectionObjects.count,
             @"Invalid index: %@", @(index));
    NSUInteger sectionIndex = MIN(_KCDSectionObjects.count, index);
    [_KCDSectionObjects insertObject:aSection atIndex:sectionIndex];
    NSAssert([_KCDSectionObjects[sectionIndex] isEqual:aSection], @"Section at incorrect index");
    VLog(@"Adding Section View: %@", @(sectionIndex));
    [self insertSectionsViews:[NSIndexSet indexSetWithIndex:sectionIndex] withAnimation:animation];
    if (aSection.objects.count > 0) {
        // If the section came with any objects, insert those rows now.
        NSMutableArray *indexPaths = [NSMutableArray new];
        [aSection.objects enumerateObjectsUsingBlock:^(id<KCDObjectControllerDelegate> obj, NSUInteger idx, BOOL *stop) {
            NSIndexPath *anIndexPath = [NSIndexPath indexPathForRow:idx inSection:sectionIndex];
            [indexPaths addObject:anIndexPath];
        }];
        [self insertViewsAtIndexPaths:indexPaths withAnimation:animation];
    }
}


- (void)KCDInlineAddSection:(id<KCDSection>)aSection
                  animation:(NSInteger)animation;
{
    if ([_KCDSectionObjects containsObject:aSection]) {
        DLog(@"Section already present: %@", aSection);
        // This section, or a variation, is already present.
        // Assume that we're replacing the section with a modified copy
        // and delete the equivalent section from the stack.
        [self KCDInlineDeleteSections:@[aSection] animation:animation];
    }
    NSInteger insertIndex = _KCDSectionObjects.count;
    [_KCDSectionObjects insertObject:aSection atIndex:insertIndex];
    NSMutableArray *indexPaths = [NSMutableArray new];
    [[aSection objects] enumerateObjectsUsingBlock:^(id<KCDObjectControllerDelegate> obj, NSUInteger idx, BOOL *stop) {
        NSIndexPath *anIndexPath = [NSIndexPath indexPathForRow:idx inSection:insertIndex];
        [indexPaths addObject:anIndexPath];
    }];
    VLog(@"Adding Section View: %@", @(insertIndex));
    [self insertSectionsViews:[NSIndexSet indexSetWithIndex:insertIndex] withAnimation:animation];
    [self insertViewsAtIndexPaths:indexPaths withAnimation:animation];
}

- (void)KCDInlineMoveSection:(id<KCDSection>)section
                     toIndex:(NSUInteger)index;
{
    NSAssert(section, @"Attempt to move nil section");
    NSAssert(index <= [_KCDSectionObjects count],
             @"Index (%@) out of bounds: only %@ sections",
             @(index),
             @(_KCDSectionObjects.count));
    NSInteger sourceIndex = NSNotFound;
    if ((sourceIndex = [_KCDSectionObjects indexOfObject:section]) != NSNotFound) {
        NSInteger targetIndex = MIN(index, [_KCDSectionObjects count]);
        NSAssert(targetIndex == index,
                 @"Index mismatch: intended %@; got %@",
                 @(index),
                 @(targetIndex));
        [_KCDSectionObjects removeObjectAtIndex:sourceIndex];
        [_KCDSectionObjects insertObject:section atIndex:targetIndex];
        NSAssert([_KCDSectionObjects[targetIndex] isEqual:section],
                 @"Section placed improperly");
        NSAssert([_KCDSectionObjects[targetIndex] objects].count == section.objects.count, @"Section object count changed.");
        [self moveSectionViewAtIndex:sourceIndex toSectionIndex:targetIndex];
        VLog(@"Moving Section View from %@ to %@", @(sourceIndex), @(targetIndex));
    }
    NSAssert(sourceIndex != NSNotFound, @"Index could not be found for %@", section);
}

- (void)KCDInlineMoveSections:(NSArray *)sections toIndices:(NSArray *)indices;
{
    
    NSMutableArray *toIndices = [indices mutableCopy];
    NSMutableDictionary *fromToMap = [NSMutableDictionary new];
    NSMutableDictionary *sourceTargetMap = [NSMutableDictionary new];
    
    NSAssert([toIndices count] == [sections count],
             @"Object/path mismatch: %@ objects, %@ index paths",
             @([sections count]),
             @([toIndices count]));
    
    if ([toIndices count] == [sections count]) {
        if ([toIndices count] == 1 && [sections count] == 1) {
            [self KCDInlineMoveSection:[sections firstObject] toIndex:[toIndices.firstObject integerValue]];
        }
        else {
            
            // Multi path moves: the controller's structure mid-transaction will not match
            // the final structure; and the index paths from which objects are moved
            // during the transaction may not match the index paths of the views that
            // represent the objects.
            
            __block NSInteger sectionIndex = 0;
            [toIndices enumerateObjectsUsingBlock:^(NSNumber *toIndexNum, NSUInteger idx, BOOL *stop) {
                id<KCDSection> sectionToMove = sections[sectionIndex++];
                // Associate the section with its destination index
                sourceTargetMap[toIndexNum] = sectionToMove;
                NSInteger fromIndex = [self indexForSection:sectionToMove];
                // Associate the source indexPath with its destination index path.
                fromToMap[@(fromIndex)] = toIndexNum;
            }];
            
            // Enumerate and move.
            [toIndices enumerateObjectsUsingBlock:^(NSNumber *toIndexNum, NSUInteger idx, BOOL *stop) {
                id <KCDSection> obj = nil;
                if ((obj = sourceTargetMap[toIndexNum])) {
                    // During restructure, the index path for the object may have changed.
                    NSInteger from = [self indexForSection:obj];
                    [_KCDSectionObjects removeObjectAtIndex:from];
                    [_KCDSectionObjects insertObject:obj atIndex:toIndexNum.integerValue];
                    NSAssert(_KCDSectionObjects[toIndexNum.integerValue] == obj, @"Object at incorrect index");
                }
            }];
#ifdef DEBUG
            __block NSInteger s = 0;
            [toIndices enumerateObjectsUsingBlock:^(NSNumber *toIndexNum, NSUInteger idx, BOOL *stop) {
                id<KCDSection> section = sections[s++];
                NSAssert([[self sectionAtIndex:toIndexNum.integerValue] isEqual:section], @"Section at wrong index");
            }];
#endif
            [fromToMap enumerateKeysAndObjectsUsingBlock:^(NSNumber *from, NSNumber *to, BOOL *stop) {
                [self moveSectionViewAtIndex:from.integerValue toSectionIndex:to.integerValue];
            }];
        }
    }
}

- (void)KCDInlineDeleteSections:(NSArray *)sections
                      animation:(NSInteger)animation;
{
    NSMutableIndexSet *indexSet = [NSMutableIndexSet new];
    [sections enumerateObjectsUsingBlock:^(id<KCDSection>aSection, NSUInteger idx, BOOL *stop) {
        NSInteger sectionIndex = NSNotFound;
        if ((sectionIndex = [self indexForSection:aSection]) != NSNotFound) {
            [indexSet addIndex:sectionIndex];
        }
        NSAssert(sectionIndex != NSNotFound, @"No index for section: %@", aSection);
    }];
    [_KCDSectionObjects removeObjectsAtIndexes:indexSet];
    [self deleteSectionViews:indexSet withAnimation:animation];
}

- (void)KCDInlineDeleteSectionsWithIndices:(NSIndexSet *)sectionIndexSet
                                 animation:(NSInteger)animation;
{
    NSMutableIndexSet *indexSet = [NSMutableIndexSet new];
    [sectionIndexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        id<KCDSection> sectionToDelete = nil;
        if ((sectionToDelete = [self sectionAtIndex:idx])) {
            [indexSet addIndex:idx];
        }
        NSAssert(sectionToDelete, @"There is no section at index: %@", @(idx));
    }];
    [_KCDSectionObjects removeObjectsAtIndexes:indexSet];
    [self deleteSectionViews:indexSet withAnimation:animation];
}

- (void)KCDInlineSortSectionsusingDescriptors:(NSArray *)descriptors;
{
    NSAssert(descriptors.count, @"Attempt to pass nil or empty descriptors array");
    if (descriptors.count == 0) {
        return;
    }
    NSMutableArray *newSectionOrder = KCDMutableCopySectionsArray(_KCDSectionObjects);
    [newSectionOrder sortUsingDescriptors:descriptors];
    NSMutableArray *indices = [NSMutableArray new];
    for (NSInteger x = 0; x < newSectionOrder.count; x++) {
        [indices addObject:@(x)];
    }
    [self KCDInlineMoveSections:newSectionOrder toIndices:indices];
}

- (void)KCDInlineSortSectionsWithComparator:(NSComparator)comparator;
{
    NSAssert(comparator, @"Attempt to pass nil comparator");
    if (!comparator) {
        return;
    }
    NSMutableArray *newSectionOrder = KCDMutableCopySectionsArray(_KCDSectionObjects);
    [newSectionOrder sortUsingComparator:comparator];
    NSMutableArray *indices = [NSMutableArray new];
    for (NSInteger x = 0; x < newSectionOrder.count; x++) {
        [indices addObject:@(x)];
    }
    [self KCDInlineMoveSections:newSectionOrder toIndices:indices];
}

- (void)KCDInlineFilterSectionAtIndex:(NSUInteger)index
                            predicate:(NSPredicate *)predicate
                            animation:(NSInteger)animation;
{
    id<KCDSection> section = nil;
    if ((section = [self sectionAtIndex:index]) &&
        [section conformsToProtocol:@protocol(KCDSortableSection)]) {
        [(id<KCDSortableSection>)section setPredicate:predicate];
        [self reloadSectionViews:[NSIndexSet indexSetWithIndex:index]
                   withAnimation:animation];
    }
    NSAssert(section, @"Nil section for index (%@)", @(index));
}

- (void)KCDInlineFilterSection:(id<KCDSection>)section
                     predicate:(NSPredicate *)predicate
                     animation:(NSInteger)animation;
{
    NSInteger index;
    if (((index = [self indexForSection:section]) != NSNotFound) &&
        [section conformsToProtocol:@protocol(KCDSortableSection)]) {
        [(id<KCDSortableSection>)section setPredicate:predicate];
        [self reloadSectionViews:[NSIndexSet indexSetWithIndex:index]
                   withAnimation:animation];
    }
    NSAssert(index != NSNotFound, @"Invalid index for section: %@", section);
}


#pragma mark Objects

- (void)KCDInlineInsertObjects:(NSArray *)objects
                  atIndexPaths:(NSArray *)indexPaths
                     animation:(NSInteger)animation;
{
    
    NSAssert([objects count] == [indexPaths count],
             @"Count mismatch: %@ items; %@ indexPaths",
             @([objects count]),
             @([indexPaths count]));
    
    KCDSortObjectsAndIndexPaths(&objects, &indexPaths);
    NSInteger count = MIN(indexPaths.count, objects.count);
    for (NSInteger x = 0; x < count; x++)
    {
        id<KCDObject> anObject = objects[x];
        NSAssert(![self.allObjects containsObject:anObject],
                 @"Attempt to insert duplicate object");
        NSIndexPath *aPath = indexPaths[x];
        NSAssert([anObject conformsToProtocol:@protocol(KCDObject)],
                 @"Object does not conform to %@", NSStringFromProtocol(@protocol(KCDObject)));
        if ([anObject conformsToProtocol:@protocol(KCDObject)]) {
            id<KCDMutableSection>section = nil;
            NSInteger sectionIndex = [aPath section];
            NSAssert(sectionIndex < _KCDSectionObjects.count, @"Section index %@ out of bounds: %@", @(sectionIndex), @(_KCDSectionObjects.count));
            if ((section = (id<KCDMutableSection>)[self sectionAtIndex:sectionIndex]))
            {
                NSInteger row = aPath.row;
                if ([section insertObject:anObject atIndex:&row] && row != NSNotFound) {
                    NSAssert([section objectAtIndex:row] == anObject, @"Object is not at the reported index");
                    NSIndexPath *insertionPath = [NSIndexPath indexPathForRow:row inSection:sectionIndex];
                    [self insertViewsAtIndexPaths:@[insertionPath] withAnimation:animation];
                }
                NSAssert(row != NSNotFound, @"Invalid insertion index: NSNotFound");
            }
            NSAssert(section, @"Nil section for index (%@)", @(aPath.section));
        }
    }
}

- (void)KCDInlineAddObjects:(NSArray *)objects
                  toSection:(id<KCDSection>)section
                  animation:(NSInteger)animation;
{
    NSAssert(section, @"Attempt to pass nil section");
    NSInteger sectionIndex;
    if ((sectionIndex = [self indexForSection:section]) != NSNotFound) {
        id<KCDMutableSection>targetSection = _KCDSectionObjects[sectionIndex];
        NSMutableArray *indexPaths = [NSMutableArray new];
        for (id <KCDObject> anObject in objects)
        {
            NSAssert([anObject conformsToProtocol:@protocol(KCDObject)],
                     @"%@ does not conform to %@", anObject,
                     NSStringFromProtocol(@protocol(KCDObject)));
            NSAssert(![self.allObjects containsObject:anObject],
                     @"Attempt to insert duplicate object");
            NSInteger row;
            [targetSection addObject:anObject index:&row];
            NSAssert(targetSection.objects[row] == anObject, @"Object not in position.");
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:sectionIndex];
            [indexPaths addObject:indexPath];
        }
        [self insertViewsAtIndexPaths:indexPaths withAnimation:animation];
    }
    NSAssert(sectionIndex != NSNotFound, @"Invalid section: %@", section);
}

- (void)KCDInlineMoveObjectsAtIndexPaths:(NSArray *)fromIndexPaths
                            toIndexPaths:(NSArray *)toIndexPaths;
{
    NSAssert(fromIndexPaths, @"Source paths must not be nil");
    NSAssert(toIndexPaths, @"Target paths must not be nil");
    NSAssert([fromIndexPaths count] == [toIndexPaths count],
             @"from and to index paths count mismatch: %@ source, %@ target",
             @(fromIndexPaths.count),
             @(toIndexPaths.count));
    if ([fromIndexPaths count] == [toIndexPaths count]) {
        // Release: plan for being fed inaccurate index paths: we will track and use only index paths
        // that actually contain objects. All invalid paths will be discarded.
        NSMutableArray *targetPaths = [NSMutableArray new];
        NSMutableArray *objectsToMove = [NSMutableArray new];
        [fromIndexPaths enumerateObjectsUsingBlock:^(NSIndexPath *fromPath, NSUInteger idx, BOOL *stop) {
            id <KCDObject> aSourceObject = nil;
            if ((aSourceObject = [self objectAtIndexPath:fromPath])) {
                NSIndexPath *aTargetIndexPath = toIndexPaths[idx];
                [targetPaths addObject:aTargetIndexPath];
                [objectsToMove addObject:aSourceObject];
            }
            NSAssert(aSourceObject, @"There is no object at index path: %@.%@",
                     @([fromPath section]),
                     @([fromPath row]));
        }];
        [self KCDInlineMoveObjects:objectsToMove toIndexPaths:targetPaths];
    }
}

- (void)KCDInlineMoveObjects:(NSArray *)objects toIndexPaths:(NSArray *)indexPaths;
{
    
    KCDSortObjectsAndIndexPaths(&objects, &indexPaths);
    NSMutableArray *toIndexPaths = [indexPaths mutableCopy];
    NSMutableDictionary *fromToMap = [NSMutableDictionary new];
    NSMutableDictionary *sourceTargetMap = [NSMutableDictionary new];
    
    NSAssert([toIndexPaths count] == [objects count],
             @"Object/path mismatch: %@ objects, %@ index paths",
             @([objects count]),
             @([toIndexPaths count]));
    
    if ([toIndexPaths count] == [objects count]) {
        if ([toIndexPaths count] == 1 && [objects count] == 1) {
            // An optimization for single object moves.
            id<KCDObject> movingObject = objects[0];
            NSIndexPath *toPath = indexPaths[0];
            NSIndexPath *fromPath = nil;
            if ((fromPath = [self indexPathForObject:movingObject])) {
                NSAssert(fromPath.section < [_KCDSectionObjects count], @"From section index out of bounds: %@", @(fromPath.section));
                id<KCDMutableSection>fromSection = _KCDSectionObjects[fromPath.section];
                NSAssert(toPath.section <= _KCDSectionObjects.count, @"To section index (%@) out of bounds: %@", @(toPath.section), @(_KCDSectionObjects.count));
                if (fromPath.section < _KCDSectionObjects.count && toPath.section < _KCDSectionObjects.count) {
                    id<KCDMutableSection>toSection = _KCDSectionObjects[toPath.section];
                    [fromSection removeObjectAtIndex:fromPath.row];
                    NSInteger toRow = toPath.row;
                    [toSection insertObject:movingObject atIndex:&toRow];
                    [self moveViewAtIndexPath:fromPath toIndexPath:toPath];
                }
            }
            NSAssert(fromPath, @"The ambulatory object is not present.");
        }
        else {
            
            // Multi path moves: the controller's structure mid-transaction will not match
            // the final structure; and the index paths from which objects are moved during
            // the transaction may not match the index paths of the views that represent
            // the objects.
            
            [toIndexPaths enumerateObjectsUsingBlock:^(NSIndexPath *toIndexPath, NSUInteger idx, BOOL *stop) {
                id<KCDObject> objectToMove = objects[idx];
                // Associate the object with its destination index path
                NSIndexPath *fromIndexPath = nil;
                if ((fromIndexPath = [self indexPathForObject:objectToMove])) {
                    sourceTargetMap[toIndexPath] = objectToMove;
                    NSAssert(fromIndexPath, @"Received nil index path for object: %@", objectToMove);
                    // Associate the source indexPath with its destination index path.
                    fromToMap[fromIndexPath] = toIndexPath;
                }
                NSAssert(fromIndexPath, @"The ambulatory object is not present.");
            }];
            
            // Sort the target index paths.
            [toIndexPaths sortUsingComparator:KCDIndexPathComparator()];
            
            // Enumerate and move.
            [toIndexPaths enumerateObjectsUsingBlock:^(NSIndexPath *aToIndexPath, NSUInteger idx, BOOL *stop) {
                id <KCDObject> obj = nil;
                if ((obj = sourceTargetMap[aToIndexPath])) {
                    // During restructure, the index path for the object may have changed.
                    NSIndexPath *from = [self indexPathForObject:obj];
                    [(id<KCDMutableSection>)_KCDSectionObjects[from.section] removeObjectAtIndex:from.row];
                    NSInteger row = aToIndexPath.row;
                    [(id<KCDMutableSection>)_KCDSectionObjects[aToIndexPath.section] insertObject:obj atIndex:&row];
                }
                NSAssert(obj, @"Nil object for index path: %@", aToIndexPath);
            }];
            
            [self KCDDebugVerifyObjects:[sourceTargetMap allValues] atIndexPaths:[sourceTargetMap allKeys]];
            
            [fromToMap enumerateKeysAndObjectsUsingBlock:^(NSIndexPath *from, NSIndexPath *to, BOOL *stop) {
                [self moveViewAtIndexPath:from toIndexPath:to];
            }];
        }
    }
}

- (void)KCDInlineReloadObjectsAtIndexPaths:(NSArray *)indexPaths
                                 animation:(NSInteger)animation;
{
    NSMutableSet *effectedObjects = [NSMutableSet setWithCapacity:[indexPaths count]];
    for (NSIndexPath *anIndexPath in indexPaths)
    {
        id<KCDSection> effectedSection = nil;
        if ((effectedSection = [self sectionAtIndex:anIndexPath.section]))
        {
            id <KCDObject> effectedObject = nil;
            if ((effectedObject = [effectedSection objectAtIndex:anIndexPath.row])) {
                [effectedObjects addObject:effectedObject];
            }
        }
    }
    NSMutableSet *indexPathsForReload = [NSMutableSet setWithCapacity:[effectedObjects count]];
    for (id <KCDObject> anEffectedObject in effectedObjects)
    {
        NSIndexPath *indexPath = nil;
        if ((indexPath = [self indexPathForObject:anEffectedObject]))
        {
            [indexPathsForReload addObject:indexPath];
        }
    }
    NSArray *reloadIndexPaths = [indexPathsForReload allObjects];
    [self reloadViewsAtIndexPaths:reloadIndexPaths withAnimation:animation];
}

- (void)KCDInlineDeleteObjectAtIndexPath:(NSIndexPath *)indexPath
                               animation:(NSInteger)animation;
{
    id<KCDMutableSection> aSection =nil;
    if ((aSection = (id<KCDMutableSection>)[self sectionAtIndex:indexPath.section])) {
        if ([aSection removeObjectAtIndex:indexPath.row]) {
            NSArray *indexPaths = [NSArray arrayWithObject:indexPath];
            [self deleteViewsAtIndexPaths:indexPaths withAnimation:animation];
        }
    }
}

- (void)KCDInlineDeleteObjects:(NSArray *)objects animation:(NSInteger)animation;
{
    NSMutableSet *indexPathsForDeletion = [NSMutableSet set];
    for (id <KCDObject> anObject in objects)
    {
        NSIndexPath *indexPath = nil;
        if ((indexPath = [self indexPathForObject:anObject]))
        {
            [indexPathsForDeletion addObject:indexPath];
        }
    }
    [self KCDInlineDeleteObjectsAtIndexPaths:[indexPathsForDeletion allObjects] animation:animation];
}

- (void)KCDInlineDeleteObjectsAtIndexPaths:(NSArray *)indexPaths
                                 animation:(NSInteger)animation;
{
    NSMutableDictionary *indexSets = [NSMutableDictionary dictionary];
    for (NSIndexPath *anIndexPath in indexPaths)
    {
        NSNumber *indexKey = @([anIndexPath section]);
        NSMutableArray *sectionArray = nil;
        if (!(sectionArray = [indexSets objectForKey:indexKey])) {
            sectionArray = [NSMutableArray array];
            [indexSets setObject:sectionArray forKey:indexKey];
        }
        [sectionArray addObject:anIndexPath];
    }
    
    for (NSNumber *aSectionKey in indexSets)
    {
        NSMutableArray *indexPathsToDelete = [NSMutableArray new];
        NSMutableArray *indices = [indexSets objectForKey:aSectionKey];
        NSMutableArray *objectsToDelete = [NSMutableArray new];
        NSUInteger sectionIndex = [(NSIndexPath*)indices[0] section];
        id<KCDMutableSection>section = nil;
        if ((section = (id<KCDMutableSection>)[self sectionAtIndex:sectionIndex])) {
            for (NSIndexPath *anIndexPath in indices)
            {
                id <KCDObject> objectToDelete = nil;
                if ((objectToDelete = [section objectAtIndex:[anIndexPath row]])) {
                    [indexPathsToDelete addObject:anIndexPath];
                    [objectsToDelete addObject:objectToDelete];
                }
            }
            for (id <KCDObject> anObjectToDelete in objectsToDelete)
            {
                [section removeObject:anObjectToDelete];
            }
            [self deleteViewsAtIndexPaths:indexPathsToDelete withAnimation:animation];
        }
    }
}

- (void)KCDInlineFilterWithPredicate:(NSPredicate *)predicate
                           animation:(NSInteger)animation;
{
    NSMutableIndexSet *indexSet = [NSMutableIndexSet new];
    [_KCDSectionObjects enumerateObjectsUsingBlock:^(id<KCDSection> aSection, NSUInteger idx, BOOL *stop) {
        if ([aSection conformsToProtocol:@protocol(KCDSortableSection)]) {
            [(id<KCDSortableSection>)aSection setPredicate:predicate];
            [indexSet addIndex:idx];
        }
    }];
    [self reloadSectionViews:indexSet
               withAnimation:animation];
}


- (void)KCDInlineSortSectionAtIndex:(NSUInteger)index
                    usingComparator:(NSComparator)cmptr;
{
    NSAssert(cmptr, @"Attempt to pass nil comparator");
    NSAssert([self sectionAtIndex:index], @"Section does not exist at index: %@", @(index));
    id<KCDSection> aSection = [self sectionObjects][index];
    NSMutableArray *sortedObjects = [[aSection objects] mutableCopy];
    [sortedObjects sortUsingComparator:cmptr];
    NSMutableArray *fromIndexPaths = [NSMutableArray new];
    NSMutableArray *toIndexPaths = [NSMutableArray new];
    [sortedObjects enumerateObjectsUsingBlock:^(id<KCDObject>obj, NSUInteger idx, BOOL *stop) {
        NSIndexPath *aFromIndexPath = [self indexPathForObject:obj];
        [fromIndexPaths addObject:aFromIndexPath];
        NSIndexPath *aToIndexPath = [NSIndexPath indexPathForRow:[sortedObjects indexOfObject:obj] inSection:index];
        [toIndexPaths addObject:aToIndexPath];
    }];
    [self KCDInlineMoveObjectsAtIndexPaths:fromIndexPaths
                              toIndexPaths:toIndexPaths];
}

- (void)KCDInlineSortSectionAtIndex:(NSUInteger)index
                   usingDescriptors:(NSArray *)descriptors;
{
    NSAssert([descriptors count] > 0, @"Attempt to pass empty descriptors array");
    NSAssert([self sectionAtIndex:index], @"Section does not exist at index: %@", @(index));
    id<KCDSection> aSection = [self sectionObjects][index];
    NSMutableArray *sortedObjects = [[aSection objects] mutableCopy];
    [sortedObjects sortUsingDescriptors:descriptors];
    NSMutableArray *fromIndexPaths = [NSMutableArray new];
    NSMutableArray *toIndexPaths = [NSMutableArray new];
    [sortedObjects enumerateObjectsUsingBlock:^(id<KCDObject>obj, NSUInteger idx, BOOL *stop) {
        NSIndexPath *aFromIndexPath = [self indexPathForObject:obj];
        [fromIndexPaths addObject:aFromIndexPath];
        NSIndexPath *aToIndexPath = [NSIndexPath indexPathForRow:[sortedObjects indexOfObject:obj] inSection:index];
        [toIndexPaths addObject:aToIndexPath];
    }];
    NSAssert([fromIndexPaths count] == [toIndexPaths count], @"Mismatch");
    [self KCDInlineMoveObjectsAtIndexPaths:fromIndexPaths toIndexPaths:toIndexPaths];
}

- (void)updateSections:(NSArray *)arrangement
             animation:(NSInteger)animation
            completion:(void(^)())completion;
{
    // This is accomplished as a series of transactions; nesting this call inside of a queuing
    // method may have unexpected results.
    
    NSIndexPath* (^indexPathOfObject)(NSArray *, id<KCDObject>, NSEnumerationOptions) =
    ^NSIndexPath*(NSArray *sections, id<KCDObject> object, NSEnumerationOptions options) {
        // Section objects are ordered sets; this will be fast.
        __block NSIndexPath *indexPath = nil;
        [sections enumerateObjectsWithOptions:options
                                   usingBlock:^(id<KCDSection> section, NSUInteger idx, BOOL *stop) {
                                       if ([section.objects containsObject:object]) {
                                           indexPath =  [NSIndexPath indexPathForRow:[section indexOfObject:object] inSection:idx];
                                           *stop = YES;
                                       }
                                   }];
        return indexPath;
    };
    
    // Keep track of the start and end state.
    __block NSMutableArray *newArrangement = nil;
    __block NSMutableArray *oldArrangement = nil;
    
    __block NSMutableOrderedSet * insertedSections = nil;
    __block NSMutableOrderedSet * deletedSections = nil;
    
    __block NSMutableOrderedSet * oldObjects = nil;
    __block NSMutableOrderedSet * insertedObjects = nil;
    __block NSMutableOrderedSet * deletedObjects = nil;
    
    __block NSMutableSet * proactivelyInsertedObjects = [NSMutableSet new]; // Keep track of objects that we insert during this stage.
    
    __block KCDObjectController *__weak blockSelf = self;
    
    void (^prepStorage)() = ^{
        newArrangement = [NSMutableArray arrayWithArray:arrangement];
        oldArrangement = KCDMutableCopySectionsArray(_KCDSectionObjects);
        
        NSOrderedSet *newSections = [[NSOrderedSet alloc] initWithArray:newArrangement];
        NSOrderedSet *oldSections = [[NSOrderedSet alloc] initWithArray:oldArrangement];
        
        insertedSections = [newSections mutableCopy];
        [insertedSections minusOrderedSet:oldSections];
        deletedSections = [oldSections mutableCopy];
        [deletedSections minusOrderedSet:newSections];
        
        NSMutableOrderedSet * newObjects = [NSMutableOrderedSet new];
        [newArrangement enumerateObjectsUsingBlock:^(id<KCDSection>aSection, NSUInteger idx, BOOL *stop) {
            [newObjects addObjectsFromArray:aSection.objects.array];
        }];
        oldObjects = [[NSMutableOrderedSet alloc] initWithArray:[blockSelf allObjects]];
        deletedObjects = [oldObjects mutableCopy];
        [deletedObjects minusOrderedSet:newObjects];
        insertedObjects = [newObjects mutableCopy];
        [insertedObjects minusOrderedSet:oldObjects];
        
        KCDSectionDiffLog(@"Sections: %@ Inserted; %@ Deleted",
                          @([insertedSections count]),
                          @([deletedSections count]));
        
        KCDSectionDiffLog(@"Objects: %@ Inserted; %@ Deleted",
                          @([insertedObjects count]),
                          @([deletedObjects count]));
    };
    
    // Add new sections
    
    void(^insertNewSectionsTransaction)() = ^{
        KCDSectionDiffLog(@"insertNewSectionsTransaction");
        [insertedSections enumerateObjectsUsingBlock:^(id<KCDSection> obj, NSUInteger idx, BOOL *stop) {
            id<KCDMutableSection>emptySection = [(id)obj copy];
            [emptySection removeAllObjects];
            [obj.objects enumerateObjectsUsingBlock:^(id<KCDObject> obj, NSUInteger idx, BOOL *stop) {
                if (!indexPathOfObject(_KCDSectionObjects, obj, kNilOptions)) {
                    [emptySection addObject:obj index:NULL];
                    [proactivelyInsertedObjects addObject:obj];
                }
            }];
            [blockSelf KCDInlineInsertSection:emptySection atIndex:idx animation:animation];
        }];
    };
    
    void (^moveSectionsTransaction)() = ^{
        KCDSectionDiffLog(@"moveSectionsTransaction");
        // Move the current sections to an approximation of their final positions.
        NSMutableArray *toSectionIndices = [NSMutableArray new];
        NSMutableArray *sectionsToMove = [NSMutableArray new];
        [newArrangement enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSInteger index;
            if ((index = [_KCDSectionObjects indexOfObject:obj]) != NSNotFound) {
                id <KCDSection> aSectionToMove = _KCDSectionObjects[index];
                [toSectionIndices addObject:@(idx)];
                [sectionsToMove addObject:aSectionToMove];
            }
            else {
                ALog(@"Failed to lock index for section: %@", obj);
            }
        }];
        [blockSelf KCDInlineMoveSections:sectionsToMove toIndices:toSectionIndices];
    };
    
    // Now, every section that will present at the end of the transaction is in place.
    // Every section that will persist through the transaction is in its final position.
    // Sections that will be deleted are still present, and contain all of their original objects.
    
    // Next: Delete all outgoing objects.
    
    void (^deleteObjectsTransaction)() = ^{
        KCDSectionDiffLog(@"deleteObjectsTransaction");
        [blockSelf KCDInlineDeleteObjects:deletedObjects.array animation:animation];
    };
    
    // Insert incoming objects that haven't already been prospectively inserted.
    
    void (^insertObjectsTransaction)() = ^{
        KCDSectionDiffLog(@"insertObjectsTransaction");
        NSMutableArray *insertIndexPaths = [NSMutableArray new];
        NSMutableArray *insertObjects = [NSMutableArray new];
        [insertedObjects enumerateObjectsUsingBlock:^(id<KCDObject>anInsertedObject, NSUInteger idx, BOOL *stop) {
            // Verify that we haven't already inserted the object.
            if (![proactivelyInsertedObjects containsObject:anInsertedObject]) {
                NSIndexPath *targetPath = nil;
                if ((targetPath = indexPathOfObject(newArrangement, anInsertedObject, kNilOptions))) {
                    [insertObjects addObject:anInsertedObject];
                    [insertIndexPaths addObject:targetPath];
                }
                NSAssert(targetPath, @"Nil index path for object insertion: %@", anInsertedObject);
            }
        }];
        NSAssert([insertObjects count] == [insertIndexPaths count], @"Mismatch between inserted objects and paths");
        [blockSelf KCDInlineInsertObjects:insertObjects atIndexPaths:insertIndexPaths animation:animation];
    };
    
    // Move objects to intended index paths.
    
    void(^moveObjectsTransaction)() = ^{
        KCDSectionDiffLog(@"moveObjectsTransaction");
        NSMutableArray *from = [NSMutableArray new];
        NSMutableArray *to = [NSMutableArray new];
        [newArrangement enumerateObjectsUsingBlock:^(id<KCDSection>section, NSUInteger idx, BOOL *stop) {
            [section.objects enumerateObjectsUsingBlock:^(id<KCDObject>obj, NSUInteger idx, BOOL *stop) {
                NSInteger sectionIndex;
                if ((sectionIndex = [_KCDSectionObjects indexOfObject:section]) != NSNotFound) {
                    NSInteger rowIndex = [section.objects indexOfObject:obj];
                    NSIndexPath *destinationIndexPath = [NSIndexPath indexPathForRow:rowIndex inSection:sectionIndex];
#ifdef DEBUG
                    NSIndexPath *currentIndexPath = indexPathOfObject(_KCDSectionObjects, obj, kNilOptions);
                    NSAssert(currentIndexPath, @"Invalid current index path for object: %@", obj);
#endif
                    [from addObject:obj];
                    [to addObject:destinationIndexPath];
                }
                NSAssert(sectionIndex != NSNotFound, @"Failed to lock section");
            }];
        }];
        [blockSelf KCDInlineMoveObjects:from toIndexPaths:to];
    };
    
    // Delete the sections that we've held on to for moves.
    
    void (^deleteSectionsTransaction)() = ^{
        KCDSectionDiffLog(@"deleteSectionsTransaction");
        NSMutableIndexSet *sectionDeleteIndexSet = [NSMutableIndexSet new];
        [deletedSections enumerateObjectsUsingBlock:^(id<KCDSection>aDeletedSection, NSUInteger idx, BOOL *stop) {
            if ([_KCDSectionObjects containsObject:aDeletedSection]) {
                NSInteger sectionIndex;
                if ((sectionIndex = [_KCDSectionObjects indexOfObject:aDeletedSection]) != NSNotFound) {
                    KCDSectionDiffLog(@"Deleting %@", _KCDSectionObjects[sectionIndex]);
                    [sectionDeleteIndexSet addIndex:sectionIndex];
                }
                NSAssert(sectionIndex != NSNotFound, @"Could not find section to delete");
            }
        }];
        [blockSelf KCDInlineDeleteSectionsWithIndices:sectionDeleteIndexSet animation:animation];
    };
    
    [self commitUpdate:prepStorage completion:nil];
    [self commitUpdate:insertNewSectionsTransaction completion:nil];
    [self commitUpdate:deleteObjectsTransaction completion:nil];
    [self commitUpdate:moveSectionsTransaction completion:nil]; // Approximate structure
    [self commitUpdate:insertObjectsTransaction completion:nil];
    [self commitUpdate:moveObjectsTransaction completion:nil];
    [self commitUpdate:deleteSectionsTransaction completion:nil];
    [self commitUpdate:moveSectionsTransaction completion:nil];
    [self commitUpdate:^{
        [blockSelf KCDDebugVerifyArrangedObjectsStructure:newArrangement];
        blockSelf = nil;
    } completion:completion];
}

#pragma mark - Keyed Subscripting

- (id)objectForKeyedSubscript:(id <NSCopying>)key;
{
    // Note: where there are multiple sections with the same sectionName, this will return the first matching section.
    NSAssert([(id)key isKindOfClass:[NSString class]], @"Attempt to get section with non-string value section name");
    id<KCDSection>matchedSection = nil;
    if ([(id)key isKindOfClass:[NSString class]]) {
        for (id<KCDSection> aSection in _KCDSectionObjects)
        {
            if ([[aSection sectionName] isEqualToString:(NSString *)key]) {
                matchedSection = aSection;
                break;
            }
        }
    }
    return matchedSection;
}

- (void)setObject:(id)obj forKeyedSubscript:(id <NSCopying>)key;
{
    NSAssert([(id)key isKindOfClass:[NSString class]], @"Attempt to set section with non-string value section name");
    if (![(id)key isKindOfClass:[NSString class]]) {
        return;
    }
    NSAssert([obj conformsToProtocol:@protocol(KCDSection)], @"Attempt to add section that does not conform to %@", NSStringFromProtocol(@protocol(KCDSection)));
    if ([obj conformsToProtocol:@protocol(KCDMutableSection)]) {
        [(id<KCDMutableSection>)obj setSectionName:(NSString *)key];
        if ([self sectionSortDescriptors]) {
            // Determine insertion index.
            NSMutableArray *sections = [_KCDSectionObjects mutableCopy];
            [sections addObject:obj];
            [sections sortUsingDescriptors:_sectionSortDescriptors];
            NSInteger insertionIndex = [sections indexOfObject:obj];
            [_KCDSectionObjects insertObject:obj atIndex:insertionIndex];
        }
        else {
            // Add the section to the end.
            [_KCDSectionObjects addObject:obj];
        }
    }
}

#pragma mark - Utilities

void KCDSortObjectsAndIndices(NSArray ** objects, NSArray ** indices) {
    if (!objects || !indices) {
        return;
    }
    
    if ([*objects count] == [*indices count]) {
        NSMutableArray *sortedIndices = [*indices mutableCopy];
        [sortedIndices sortUsingComparator:^NSComparisonResult(NSNumber * obj1, NSNumber * obj2) {
            NSInteger one = [obj1 integerValue];
            NSInteger two = [obj2 integerValue];
            if (two > one) { return NSOrderedAscending; }
            if (one > two) { return NSOrderedDescending; }
            return NSOrderedSame;
        }];
        NSPointerArray *objectPointers = [NSPointerArray strongObjectsPointerArray];
        [sortedIndices enumerateObjectsUsingBlock:^(NSNumber *anIndexNum, NSUInteger idx, BOOL *stop) {
            NSInteger index = [*indices indexOfObject:anIndexNum];
            id anObject = [*objects objectAtIndex:index];
            [objectPointers insertPointer:(__bridge void *)anObject atIndex:idx];
        }];
        NSArray *sortedObjects = [objectPointers allObjects];
        *indices = sortedIndices;
        *objects = sortedObjects;
    }
}

void KCDSortObjectsAndIndexPaths(NSArray ** objects, NSArray ** indexPaths) {
    if (!objects || !indexPaths) {
        return;
    }
    
    if ([*objects count] == [*indexPaths count]) {
        NSMutableArray *sortedIndexPaths = [*indexPaths mutableCopy];
        [sortedIndexPaths sortUsingComparator:KCDIndexPathComparator()];
        NSPointerArray *objectPointers = [NSPointerArray strongObjectsPointerArray];
        [sortedIndexPaths enumerateObjectsUsingBlock:^(NSIndexPath *anIndexPath, NSUInteger idx, BOOL *stop) {
            NSInteger index = [*indexPaths indexOfObject:anIndexPath];
            id anObject = [*objects objectAtIndex:index];
            [objectPointers insertPointer:(__bridge void *)anObject atIndex:idx];
        }];
        NSArray *sortedObjects = [objectPointers allObjects];
        *indexPaths = sortedIndexPaths;
        *objects = sortedObjects;
    }
}

NSMutableArray * KCDMutableCopySectionsArray(NSArray *sectionObjects)
{
    NSMutableArray *copySections = [NSMutableArray new];
    [sectionObjects enumerateObjectsUsingBlock:^(id<KCDSection>obj, NSUInteger idx, BOOL *stop) {
        id<KCDSection> sectionCopy = [(id)obj copy];
        [copySections addObject:sectionCopy];
    }];
    return copySections;
}

- (void)KCDIllegalStackCheckAndAssert;
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    NSAssert(dispatch_get_current_queue() != _KCDTransactionQueue, @"Attempt to nest serial blocks.");
#pragma clang diagnostic pop
}

- (void)KCDDebugVerifyObjects:(NSArray *)objects atIndexPaths:(NSArray *)indexPaths;
{
#if DEBUG
    NSInteger count = [objects count];
    for (NSInteger x = 0; x < count; x++)
    {
        id<KCDObject>expected = objects[x];
        NSIndexPath *path = indexPaths[x];
        if ([self objectAtIndexPath:path] != expected) {
            id <KCDObject> found = [self objectAtIndexPath:path];
            DLog(@"Expected %@ at %@.%@. Found: %@", expected, @(path.section), @(path.row), found);
            id<KCDSection>section = [self sectionAtIndex:path.section];
            DLog(@"Destination section contents: %@", [(id)section valueForKeyPath:@"objects"]);
        }
        NSAssert([[self objectAtIndexPath:path] isEqual:expected], @"Object is not at correct path");
    }
#endif
}

- (void)KCDDebugVerifyArrangedObjectsStructure:(NSArray *)arrangedObjects;
{
#if DEBUG
    void (^logError)() = ^{
        DLog(@"EXPECTATION: %@", arrangedObjects);
        DLog(@"RESULT: %@", _KCDSectionObjects);
    };
    [arrangedObjects enumerateObjectsUsingBlock:^(id<KCDSection> expectationSection, NSUInteger idx, BOOL *stop) {
        id<KCDSection>resultSection = _KCDSectionObjects[idx];
        if (![resultSection isEqual:expectationSection]) {
            logError();
        }
        NSAssert([resultSection isEqual:expectationSection], @"Incorrect section");
        if (resultSection.objects.count != expectationSection.objects.count) {
            logError();
        }
        NSAssert(resultSection.objects.count == expectationSection.objects.count, @"Incorrect object count");
        [expectationSection.objects enumerateObjectsUsingBlock:^(id<KCDObject>expectationObject, NSUInteger idx, BOOL *stop) {
            id<KCDObject>resultObject = resultSection.objects[idx];
            if (![resultObject isEqual:expectationObject]) {
                logError();
            }
            NSAssert([resultObject isEqual:expectationObject], @"Incorrect object");
        }];
    }];
#endif
}


@end

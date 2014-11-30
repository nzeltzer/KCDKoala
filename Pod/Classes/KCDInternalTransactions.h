//
//  KCDInternalTransactions.h
//  KCDKoalaMobile
//
//  Created by Nicholas Zeltzer on 11/5/14.
//  Copyright (c) 2014 LawBox LLC. All rights reserved.
//

@import Foundation;

#import "KCDSectionProtocol.h"
#import "KCDObjectProtocol.h"

@protocol KCDInternalTransactions <NSObject>

#pragma mark - Inline Methods

/**
 KCDInternalTransactions describes private methods in KCDObjectController that subclasses may wish to invoke.
 
 Inline methods are not dispatched to a specific queue or associated
 with a specific group; they can safely be stacking within update blocks.
 */

#pragma mark Sections

- (void)KCDInlineAddSection:(id<KCDSection>)aSection
                  animation:(NSInteger)animation;

- (void)KCDInlineMoveSection:(id<KCDSection>)section
                     toIndex:(NSUInteger)index;

- (void)KCDInlineDeleteSections:(NSArray *)sections
                      animation:(NSInteger)animation;

- (void)KCDInlineInsertSection:(id<KCDSection>)aSection
                       atIndex:(NSUInteger)index
                     animation:(NSInteger)animation;

- (void)KCDInlineDeleteSectionsWithIndices:(NSIndexSet *)sectionIndexSet
                                 animation:(NSInteger)animation;

- (void)KCDInlineSortSectionAtIndex:(NSUInteger)index
                    usingComparator:(NSComparator)cmptr;

- (void)KCDInlineSortSectionAtIndex:(NSUInteger)index
                   usingDescriptors:(NSArray *)descriptors;

- (void)KCDInlineFilterSection:(id<KCDSection>)section
                     predicate:(NSPredicate *)predicate
                     animation:(NSInteger)animation;

- (void)KCDInlineFilterSectionAtIndex:(NSUInteger)index
                            predicate:(NSPredicate *)predicate
                            animation:(NSInteger)animation;

#pragma mark Objects

- (void)KCDInlineInsertObjects:(NSArray *)objects
                  atIndexPaths:(NSArray *)indexPaths
                     animation:(NSInteger)animation;

- (void)KCDInlineAddObjects:(NSArray *)objects
                  toSection:(id<KCDSection>)section
                  animation:(NSInteger)animation;

- (void)KCDInlineMoveObjects:(NSArray *)objects
                toIndexPaths:(NSArray *)indexPaths;

- (void)KCDInlineMoveObjectsAtIndexPaths:(NSArray *)sourcePaths
                            toIndexPaths:(NSArray *)targetPaths;

- (void)KCDInlineDeleteObjects:(NSArray *)objects
                     animation:(NSInteger)animation;

#pragma mark Uniform

- (void)KCDInlineReloadObjectsAtIndexPaths:(NSArray *)indexPaths
                                 animation:(NSInteger)animation;

- (void)KCDInlineFilterWithPredicate:(NSPredicate *)predicate
                           animation:(NSInteger)animation;

- (void)KCDInlineEnumerate:(void(^)(id<KCDObject>object, id<KCDSection>section, NSIndexPath *(^indexPath)(), BOOL *stop))block;

@end

//
//  KCDViewUpdates.h
//  KCDKoalaMobile
//
//  Created by Nicholas Zeltzer on 11/5/14.
//  Copyright (c) 2014 LawBox LLC. All rights reserved.
//

@import Foundation;

@protocol KCDViewUpdates <NSObject>

#pragma mark - Pipelining

/**
 KCDViewUpdates describes methods that KCDObjectController subclasses must implement the following to effectuate view updates.
 */

#pragma mark General

- (NSArray *)indexPathsForSelectedViews;

- (void)reloadData;

#pragma mark Sections

- (void)insertSectionsViews:(NSIndexSet*)indexSet
              withAnimation:(NSInteger)animation;

- (void)deleteSectionViews:(NSIndexSet *)indexSet
             withAnimation:(NSInteger)animation;

- (void)reloadSectionViews:(NSIndexSet *)indexSet
             withAnimation:(NSInteger)animation;

- (void)moveSectionViewAtIndex:(NSInteger)fromIndex
                toSectionIndex:(NSInteger)toIndex;

#pragma mark Objects

- (void)insertViewsAtIndexPaths:(NSArray *)indexPaths
                  withAnimation:(NSInteger)animation;

- (void)deleteViewsAtIndexPaths:(NSArray *)indexPaths
                  withAnimation:(NSInteger)animation;

- (void)reloadViewsAtIndexPaths:(NSArray *)indexPaths
                  withAnimation:(NSInteger)animation;

- (void)moveViewAtIndexPath:(NSIndexPath *)sourceIndexPath
                toIndexPath:(NSIndexPath *)targetIndexPath;

@end

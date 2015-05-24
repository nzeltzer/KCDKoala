//
//  KCDObjectController.h
//
//  Created by Nicholas Zeltzer on 11/2/11.
//  Copyright (c) 2011 CaseHunt(er). All rights reserved.
//

@import Foundation;
@protocol KCDIntrospective;

#import "KCDSectionProtocol.h"
#import "KCDObjectProtocol.h"
#import "KCDInternalTransactions.h"
#import "KCDViewUpdates.h"

#pragma mark - KCDObjectControllerDelegate

@protocol KCDObjectControllerDelegate <NSObject>

@end

#pragma mark - KCDObjectController

UIKIT_EXTERN NSString * const kKCDTransactionCount;

@interface KCDObjectController : NSObject {
@protected
    dispatch_group_t _KCDAnimationGroup; // Group for performing view updates.
    dispatch_queue_t _KCDAnimationQueue; // Serial queue for scheduling view updates.
    dispatch_queue_t _KCDTransactionQueue; // Serial queue for pre-scheduling updates.
    dispatch_group_t _KCDTransactionGroup; // Group for pre-scheduling updates.
    NSMutableArray *_KCDSectionObjects;
    NSInteger _KCDTransactionCount;
    NSTimeInterval _KCDTransactionDelay;
}

@property (nonatomic, readwrite, weak) id <KCDObjectControllerDelegate> delegate;

- (instancetype)initWithDelegate:(id<KCDObjectControllerDelegate>)delegate
                        sections:(NSArray *)KCDSections NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithDelegate:(id<KCDObjectControllerDelegate>)delegate;

/**
 Reset the object controller's sections with the provided sections.
 @note This is not a scheduled transaction, and should only be used to set the initial sections composition where it is not possible to intialize the datasource and its seed data at the same time – e.g., where you want to provide an empty object controller via a superclass. 
 */

- (void)resetSections:(NSArray *)sections;

#pragma mark - Message Forwarding

/**
 Returns an array of protocols, methods of which can be forwarded to this object's delegate, where this object does not implement the corresponding method.
 @example Return the UITableViewDelegate protocol to allow forwarding of unimplemented UITableViewDelegate methods to a data source's delegate.
 */

- (NSArray *)forwardingProtocols;


#pragma mark - Transaction Scheduling

/**
 Schedules the block on the transaction queue and provides an introspective reference to the object controller.
 @note Use this method to schedule the block for dispatch after pending transactions have completed. The block will not be sent to the animation queue or run on the main thread.
 
 */

- (void)queueTransaction:(void(^)(KCDObjectController<KCDIntrospective>*koala))action;

/**
 Schedules the block on the transaction queue.
 @note Identical to 'queueTransaction' except that it does not provide a reference to the object controller.
 
 */

- (void)queueAction:(void(^)())action;

/**
 Performs a sequence of animated transactions to restructure the current section/object structure with provided section/object structure.
 @note This method uses a sequence of animated transactions, each of which will be added to the animation queue.
 */

- (void)queueArrangement:(void(^)(KCDObjectController<KCDIntrospective>* koala, NSMutableArray *sections))transaction
               animation:(NSInteger)animation
              completion:(void(^)(KCDObjectController<KCDIntrospective>* koala))completion;


#pragma mark - Queued Transactions -

- (void)setSections:(NSArray *)sections
          animation:(NSInteger)animation
         completion:(void(^)())completion;

#pragma mark - Factory Methods

/**
 Returns a new empty section object conforming to KCDSection.
 @note This method does not insert the freshly created section object.
 */

- (id<KCDMutableSection>)newSectionWithName:(NSString *)sectionName objects:(NSArray *)objects;

/**
 Returns a new empty section object conforming to KCDSection.
 @note This method does not insert the newly created section object.
 */

+ (id<KCDMutableSection>)sectionWithName:(NSString *)sectionName objects:(NSArray *)objects;

#pragma mark - Sections

#pragma mark Inserting Sections

/**
 Adds the provided sections to the controller.
 */

- (void)addSections:(NSArray *)sections
          animation:(NSInteger)animation;

/**
 Inserts the given section at the given index.
 */

- (void)insertSection:(id<KCDSection, NSCopying>)aSection
              atIndex:(NSUInteger)index
            animation:(NSInteger)animation;

/**
 Inserts the section as the last section in the controller.
 */

- (void)addSection:(id<KCDSection, NSCopying>)section
         animation:(NSInteger)animation;

/**
 Creates and inserts a new section with at the given index.
 */

- (id<KCDSection>)insertSectionWithName:(NSString *)sectionName
                                objects:(NSArray *)objects
                                atIndex:(NSInteger)index
                              animation:(NSInteger)animation;

/**
 Creates and adds a new section to the end of the controller's managed sections.
 */

- (id<KCDSection>)addSectionWithName:(NSString *)sectionName
                             objects:(NSArray *)objects
                           animation:(NSInteger)animation;

#pragma mark Moving Sections

/**
 Move a given section to a new index.
 @note This method should be preferred to manipulating sections by index as it yields more easily predicted results.
 */

- (void)moveSection:(id<KCDSection>)sourceSection
            toIndex:(NSUInteger)targetIndex;

/**
 Moves the provided sections to the corresponding indices.
 */

- (void)moveSections:(NSArray *)sections
           toIndices:(NSArray *)indices;

/**
 Move the section at the given index to the new index.
 @note Section indices can change between call and execution.
 */

- (void)moveSectionAtIndex:(NSUInteger)fromIndex
                   toIndex:(NSUInteger)toIndex;

/**
 Moves the sections at the provided indices to the corresponding indices.
 */

- (void)moveSectionsAtIndices:(NSArray *)fromIndices
                    toIndices:(NSArray *)toIndices;

#pragma mark Deleting Sections

/**
 Deletes the section object and its children from the controller's contents.
 */

- (void)deleteSection:(id<KCDSection>)section
            animation:(NSInteger)animation;

/**
 Deletes the section at the given index, and all of the section's objects.
 */

- (void)deleteSectionAtIndex:(NSUInteger)sectionIndex
                   animation:(NSInteger)animation;

/**
 Deletes the sections at the given indices, along with all of the sections' objects.
*/

- (void)deleteSectionsWithIndices:(NSIndexSet*)sectionIndexSet
                        animation:(NSInteger)animation;

/**
 Deletes all sections and all sections' objects from the controller. 
 */

- (void)deleteAllSections:(NSInteger)animation;

#pragma mark Sorting Sections

/** Sorts the sections using the descriptors.
 @note the objects sorted will conform to KCDSection
 */

- (void)sortSectionsUsingDescriptors:(NSArray *)descriptors;

/** Sorts the sections using the comparator.
 @note the objects sorted will conform to KCDSection 
 */

- (void)sortSectionsWithComparator:(NSComparator)comparator;

#pragma mark - Objects

#pragma mark Inserting Objects

/** Inserts the object at the given index path.
 @note The index path must be valid.
 */

- (void)insertObject:(id<KCDObject>)object
         atIndexPath:(NSIndexPath*)indexPath
           animation:(NSInteger)animation;

/** Appends the given objects to the section.
 @note The section object must already be present in the controller's managed sections.
 */

- (void)addObjects:(NSArray*)objects
         toSection:(id<KCDSection>)section
         animation:(NSInteger)animation;

/** Inserts the given objects at the given index paths.
 */
- (void)insertObjects:(NSArray*)objects
         atIndexPaths:(NSArray*)indexPaths
            animation:(NSInteger)animation;

/** Appends the objects to the section at the provided index.
 */

- (void)addObjects:(NSArray*)objects // by reference
  toSectionAtIndex:(NSUInteger)index
         animation:(NSInteger)animation;

#pragma mark Moving Objects

/**
 Attempts to move the object to the destination index path.
 @param object The object that should be moved.
 @param indexPath The index path to which the object should be moved.
 @note The destination index path will be sanitized; if the destination section does not exist, the object will not be moved.
 */

- (void)moveObject:(id<KCDObject>)object // by reference
       toIndexPath:(NSIndexPath *)indexPath;

/**
 Moves the provided objects to the provided index paths.
 @param objects The objects to move.
 @param indexPath The index paths to which the objects should be moved.
 */

- (void)moveObjects:(NSArray *)objects
       toIndexPaths:(NSArray *)indexPaths;

/**
 Attempts to move the objects at the given index paths to the next index paths.
 @param sourceIndexPaths The index paths of the objects to move.
 @param targetIndexPaths The index paths to which the objects should be moved.
 @note The sequence of moves is determined by sorting the destination index paths. Section contents can change between call and execution; invalid destination paths will be sanitized.
 */

- (void)moveObjectsAtIndexPaths:(NSArray*)sourceIndexPaths // by indices
                   toIndexPaths:(NSArray*)targetIndexPaths;

#pragma mark Deleting Objects

/**
 Deletes the object with the provided animation.
 @param object The object to be deleted.
 @param animation An optional animation paramter.
 */

- (void)deleteObject:(id<KCDObject>)object // by reference
           animation:(NSInteger)animation;

/**
 Deletes the objects with the provided animation.
 @param objects The objects to be deleted.
 @param animation An optional animation paramter.
 */

- (void)deleteObjects:(NSArray*)objects // by references
            animation:(NSInteger)animation;

/**
 Deletes the objects at the provided index paths with the provided animation.
 @param indexPaths The index paths at which the objects to be deleted reside.
 @param animation An optional animation parameter.
 */

- (void)deleteObjectsAtIndexPaths:(NSArray*)indexPaths // by indices
                        animation:(NSInteger)animation;

/**
 Deletes the objects at the provided section and row with the provided animation.
 @param row The row integer
 @param section The section integer
 @param animation An optional animation parameter.
 */


- (void)deleteObjectAtSection:(NSUInteger)section
                          row:(NSUInteger)row
                    animation:(NSInteger)animation;

#pragma mark Sorting Objects

- (void)sortSection:(id<KCDSection>)section
    usingComparator:(NSComparator)cmptr
          animation:(NSInteger)animation;

- (void)sortSection:(id<KCDSection>)section
   usingDescriptors:(NSArray *)descriptors
          animation:(NSInteger)animation;

- (void)sortSectionAtIndex:(NSUInteger)sectionIndex
           usingComparator:(NSComparator)cmptr;

- (void)sortSectionAtIndex:(NSUInteger)sectionIndex
          usingDescriptors:(NSArray*)descriptors;

#pragma mark - Filtering Controller Contents

- (void)filterSectionAtIndex:(NSUInteger)sectionIndex
                   predicate:(NSPredicate*)predicate
                   animation:(NSInteger)animation;


- (void)filterWithPredicate:(NSPredicate*)predicate
                  animation:(NSInteger)animation;

#pragma mark Reloading Objects

- (void)reloadItemsAtIndexPaths:(NSArray*)indexPaths
                      animation:(NSInteger)animation;

#pragma mark Special Transactions

/**
 Dispatchs view transactions the the main thread using a paired serial queue and dispatch group.
 @note Subclasses must provide an implementation of this method.
 */

- (void)commitUpdate:(void(^)())action
          completion:(void(^)())completion;

/**
 Returns all selected cell objects.
 @note This method depends on proper implementation of 'indexPathsForSelectedRows' by the subclass.
 */

- (NSArray*)selectedObjects;


@end

#pragma mark - KCDIntrospective

@protocol KCDIntrospective <NSObject>

/**
 KCDIntrospective describes synchronous methods that can be used to inspect the contents of the controller within a transaction block.
 */

@optional

/** Returns an array of KCDSectionObjectProtocol conformant objects representing the sections contained in this controller. */

@property (nonatomic, readonly) NSArray *sections;

/** Returns an array of KCDObject conformant objects representing the objects contained in this controller. */

@property (nonatomic, readonly) NSArray *objects;

#pragma mark Introspection

/**
 Returns all of the cell objects.
 */

- (NSArray*)allObjects;

/**
 Checks if any of the data source's sections contain the given object.
 @param anObject The object to check for inclusion.
 */

- (BOOL)containsObject:(id<KCDObject>)anObject;

/**
 Returns an array of index paths for the corresponding objects.
 @param objects The objects for which the indexPaths must be determined.
 */

- (NSArray*)indexPathsForObjects:(NSArray*)objects;

/**
 Returns the index path for the corresponding object.
 @param object The object for which the indexPath must be derived.
 */

- (NSIndexPath*)indexPathForObject:(id<KCDObject>)object;

/**
 Returns the object corresponding to the provided index path.
 @param indexPath The indexPath for the requested object.
 */

- (id<KCDObject>)objectAtIndexPath:(NSIndexPath*)indexPath;

/**
 Returns the objects corresponding to the provided index paths.
 @param indexPaths The indexPaths for the requested objects.
 */

- (NSArray *)objectsForIndexPaths:(NSArray *)indexPaths;

/**
 Returns the section corresponding to the given index.
 @param sectionIndex The index that the section can be located at.
 */

- (id<KCDSection>)sectionAtIndex:(NSUInteger)sectionIndex;

/**
 Returns the index for the given section.
 */

- (NSUInteger)indexForSection:(id<KCDSection>)aSection;

#pragma mark - Enumeration

/**
 This method will be dispatched on the data source's update queue; the objects received in the block are guaranteed to be valid only
 during enumeration. The arrangement of objects within the data source should not be modified during enumeration.
 */

- (void)enumerateObjectsUsingBlock:(void(^)(id<KCDObject>object, id<KCDSection>section, NSIndexPath *(^indexPath)(), BOOL *stop))block;

@end


#pragma mark - KCDKoala Macros

// Optional debugging assert macro for non-fatal API errors.

#if KCDStrictAssertEnabled
#define KCDStrictAssert(...) NSAssert(__VA_ARGS__)
#else
#define KCDStrictAssert(...) /* */
#endif

// Koala-specific logging

#if KCDKoalaLogEnabled
#define KCDKoalaLog(...) NSLog(@"%s %@", __PRETTY_FUNCTION__, [NSString stringWithFormat:__VA_ARGS__])
#else
#define KCDKoalaLog(...) /**/
#endif

//
//  KCDSection.h
//  KCDKoala
//
//  Created by Nicholas Zeltzer on 10/29/14.
//  Copyright (c) 2014 LawBox LLC. All rights reserved.
//

@import Foundation;

#import "KCDRuntime.h"

/** 
 KCDSectionProtocol defines the interface for section container objects.
 KCDObjectController uses a private implementation of this protocol; you should not attempt to create protocol compatible objects of your own.
 */

@protocol KCDObject;

@protocol KCDSection <NSObject, NSCopying>

/**
 An ordered set in which the section stores its objects.
 */

@property (nonatomic, readonly, strong) NSOrderedSet KCDGeneric(id<KCDObject>) *objects;


/**
 @return Count of all objects contained within the section.
 */

@property (nonatomic, readonly) NSInteger count;

/**
 A string value that can be used for section indices.
 */

@property (nonatomic, readonly, copy) NSString *sectionName;


/**
 A string value that uniquely identifies this section against all others
 @note This is the primary value used for hashing and equality.
 */

@property (nonatomic, readonly) NSString *sectionIdentifier;

/**
 A string value that can be used to decorate section header views.
 */


@property (nonatomic, readonly, copy) NSString *sectionHeader;

/**
 A string value that can be used to decorate section footer views.
 */

@property (nonatomic, readonly, copy) NSString *sectionFooter;

/**
 Initialize a new section object with the designated name and objects.
 */

- (instancetype)initWithSectionName:(NSString*)sectionName
                            objects:(NSArray KCDGeneric(id<KCDObject>) *)objects;

/**
 Returns YES if the section currently contains the object.
 */

- (BOOL)containsObject:(id<KCDObject>)object;

/**
 Returns the index of the object in the section.
*/

- (NSInteger)indexOfObject:(id<KCDObject>)object;

/**
 Returns the object at the request index, or nil if the object is not present.
 */

- (id<KCDObject>)objectAtIndex:(NSInteger)index;

/** Can be an implementation of NSFastEnumeration, or as a pipe to internal storage. */

- (void)enumerateObjectsUsingBlock:(void (^)(id<KCDObject> obj, NSUInteger idx, BOOL *stop))block;

@end

@protocol KCDMutableSection <KCDSection>

/**
 NSString for decorating section header views. 
 */

@property (nonatomic, readwrite, copy) NSString *sectionHeader;

/**
 NSString for decorating section footer views.
 */

@property (nonatomic, readwrite, copy) NSString *sectionFooter;

/**
 NSString for decorating section index views.
 */

@property (nonatomic, readwrite, copy) NSString *sectionName;

/**
 A section identifier is a string value used for resolving <NSObject> isEqual and hash methods.
 @param sectionIdentifier A string to use for evaluating equality against other sections.
 @note By default, each section generates its own unique section identifier.
 */

- (void)setSectionIdentifier:(NSString *)sectionIdentifier;

/**
 Adds the object to the section.
 @param index. On return, the value of the index at which the object was inserted.
 */

- (void)addObject:(id<KCDObject>)object
            index:(NSInteger*)index;

/**
 Removes the objects from the section.
 */

- (void)removeObject:(id<KCDObject>)object;

/**
 Attempts to insert the object at the selected index.
 @param index The index that the object should be inserted at; on completion: the index the object was actually inserted at.
 @note The index will be normalized to the section's bounds and sort descriptor.
 */

- (BOOL)insertObject:(id<KCDObject>)object
             atIndex:(inout NSInteger *)index;

/**
 Removes the object at the given index.
 */

- (BOOL)removeObjectAtIndex:(NSInteger)index;

/**
 Removes all objects from the section.
 */

- (void)removeAllObjects;

/**
 Returns a mutable copy of the section container.
 @param includeObjects If NO, the copy will not include any of the objects in the original section.
 */

- (id<KCDMutableSection>)mutableCopyWithObjects:(BOOL)includeObjects;

@end

/**
 The KCDSortableSection describes behavior that should not be exposed in the public
 API for a section object. KCDSection implements this protocol in its class extension, and will
 respond correctly to conformsToProtocol: messages.
 */

@protocol KCDSortableSection <KCDMutableSection>

/** 
 The predicate used to filter the contents of the section.
 @note Setting the predicate will affect the contents of the objects accessor returned from the section object. 
 */

@property (nonatomic, readwrite, copy) NSPredicate *predicate;
@property (nonatomic, readwrite, strong) NSArray *sortDescriptors; // experimental.

#pragma mark Sorting

- (void)setSortDescriptors:(NSArray KCDGeneric(NSSortDescriptor *) *)sortDescriptors
                oldIndices:(NSIndexSet **)oldIndices
                newIndices:(NSIndexSet **)newIndices;

- (void)sortUsingDescriptors:(NSArray KCDGeneric(NSSortDescriptor *) *)sortDescriptors
                  oldIndexes:(NSArray **)oldIndexes
                  newIndexes:(NSArray **)newIndexes;

- (void)sortUsingComparator:(NSComparator)cmptr;

- (void)sortUsingDescriptors:(NSArray KCDGeneric(NSSortDescriptor *) *)sortDescriptors;

@end
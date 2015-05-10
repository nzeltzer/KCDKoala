//
//  KCDSectionContainer.m
//  KCDKoala
//
//  Created by Nicholas Zeltzer on 11/2/11.

#import "KCDSectionContainer.h"
#import "KCDSectionProtocol.h"
#import "KCDUtilities.h"
#import "KCDObjectController.h"

#ifndef VLog
#define VLog(...) /**/
#endif

// Private adoption of the KCDSortableSection

@interface KCDSectionContainer () <KCDSortableSection>

@property (nonatomic, readwrite, strong) NSMutableOrderedSet *objects;
@property (nonatomic, readwrite, strong) NSMutableOrderedSet *unfilteredObjects;
@property (nonatomic, readwrite, strong) NSMutableOrderedSet *filteredObjects;
@property (nonatomic, readonly, copy) NSString *sectionIdentifier;

@end

@implementation KCDSectionContainer

@synthesize sectionName = _sectionName;
@synthesize sectionHeader = _sectionHeader;
@synthesize sectionFooter = _sectionFooter;
@synthesize sectionIdentifier = _sectionIdentifier;
@synthesize predicate = _predicate;
@synthesize sortDescriptors = _sortDescriptors;

@dynamic objects;

#pragma mark - Initialization

- (instancetype)initWithSectionName:(NSString*)sectionName
                            objects:(NSArray*)objects;
{
    self = [super init];
    if (self) {
        /*
        NSAssert(sectionName, @"Attempt to create section with nil value for sectionName");
         */
        _unfilteredObjects = [NSMutableOrderedSet orderedSetWithArray:objects];
        _sectionName = sectionName;
        _sectionHeader = sectionName;
        _sectionIdentifier = KCDNewUniqueIdentifier();
        NSAssert([self unfilteredObjects], @"Section Objects is nil!");
    }
    return self;
}

- (id<KCDMutableSection>)mutableCopyWithObjects:(BOOL)includeObjects;
{
    KCDSectionContainer * sectionCopy = [self copy];
    if (!includeObjects) {
        [sectionCopy.unfilteredObjects removeAllObjects];
        [sectionCopy.filteredObjects removeAllObjects];
    }
    return sectionCopy;
}

- (void)setSectionIdentifier:(NSString *)sectionIdentifier;
{
    _sectionIdentifier = [sectionIdentifier copy];
}

#pragma mark - Adding/Removing

- (NSInteger)indexOfObject:(id<KCDObject>)object;
{
    return [self.objects indexOfObject:object];
}

- (void)addObject:(id<KCDObject>)object
            index:(NSInteger*)index;
{
    NSUInteger insertionIndex = [self.objects count];
    NSInteger sortedIndex;
    if ((sortedIndex = [self indexForSortedInsertion:object]) != NSNotFound) {
        insertionIndex = sortedIndex;
    }
    NSAssert(![self.objects containsObject:object], @"Attempt to insert an object that is already present");
    [self.objects insertObject:object atIndex:insertionIndex];
    if (index)
    {
        *index = insertionIndex;
    }
}

- (void)removeObject:(id<KCDObject>)object;
{
    if (!object) {
        return;
    }
    NSAssert([self.objects containsObject:object], @"Section does not contain object: %@", object);
    [self.objects removeObject:object];
}

- (BOOL)insertObject:(id<KCDObject>)object atIndex:(inout NSInteger *)index;
{
    NSAssert(object, @"Attempt to pass nil object");
    NSAssert(index, @"Attempt to pass NULL index");
    NSAssert(![self.objects containsObject:object], @"Attempt to insert an object that is already present");
    if (!object || !index || [self.objects containsObject:object]) {
        if ([self.objects containsObject:object]) {
            NSLog(@"Illegal attempt to insert an object that is already present: %@", object);
        }
        if (!object) {
            NSLog(@"Illegal attempt to insert nil object");
        }
        if (!index) {
            NSLog(@"Illegal attempt to pass NULL index");
        }
        return NO;
    }
    NSInteger targetIndex;
    targetIndex = MIN(*index, [self.objects count]);
    NSInteger sortedIndex;
    if ((sortedIndex = [self indexForSortedInsertion:object]) != NSNotFound) {
        targetIndex = sortedIndex;
    } else if (targetIndex != *index) {
        KCDStrictAssert(NO, @"Incorrect insertion index");
        KCDKoalaLog(@"Requested index %@ out of bounds; inserted at %@", @(*index), @(targetIndex));
    }
    [self.objects insertObject:object atIndex:targetIndex];
    *index = targetIndex;
    NSAssert([self.objects objectAtIndex:targetIndex] == object, @"Object is not at the intended index");
    return YES;
}

- (BOOL)removeObjectAtIndex:(NSInteger)index;
{
    if (index < [self.objects count])
    {
        [self.objects removeObjectAtIndex:index];
        return YES;
    }
    return NO;
}

- (void)removeAllObjects;
{
    [self.filteredObjects removeAllObjects];
    [self.unfilteredObjects removeAllObjects];
}

- (NSInteger)indexForSortedInsertion:(id<KCDObject>)object;
{
    NSInteger index = NSNotFound;
    if ([self sortDescriptors]) {
        NSMutableOrderedSet *sortable = [self.objects mutableCopy];
        [sortable addObject:object];
        [sortable sortUsingDescriptors:self.sortDescriptors];
        index = [sortable indexOfObject:object];
    }
    return index;
}

#pragma mark - Instrospection

- (BOOL)isEqualToSection:(id<KCDSection>)section;
{
    if ([section isKindOfClass:[self class]]) {
        KCDSectionContainer *container = (KCDSectionContainer *)section;
        if (![self isEqual:container]) {
            // Perform basic equality check before moving onto section contents.
            return NO;
        }
        if (container.objects.count != self.objects.count) {
            return NO;
        }
        if (![container.filteredObjects isEqualToOrderedSet:self.filteredObjects]) {
            return NO;
        }
        if (![container.unfilteredObjects isEqualToOrderedSet:self.unfilteredObjects]) {
            return NO;
        }
        return YES;
    }
    return NO;
}

- (BOOL)containsObject:(id<KCDObject>)object;
{
    return [self.objects containsObject:object];
}

- (id<KCDObject>)objectAtIndex:(NSInteger)index;
{
    if (index < [self.objects count]) {
        id <KCDObject> object = [self.objects objectAtIndex:index];
        return object;
    }
    return nil;
}

- (void)enumerateObjectsUsingBlock:(void (^)(id<KCDObject> obj, NSUInteger idx, BOOL *stop))block;
{
    [self.objects enumerateObjectsUsingBlock:block];
}

#pragma mark - Sorting

- (void)setSortDescriptors:(NSArray *)sortDescriptors
                oldIndices:(NSIndexSet **)oldIndices
                newIndices:(NSIndexSet **)newIndices;
{
    _sortDescriptors = sortDescriptors;
    NSArray *new, *old;
    [self sortUsingDescriptors:sortDescriptors oldIndexes:&old newIndexes:&new];
    if (newIndices) {
        NSMutableIndexSet *newSet = [NSMutableIndexSet new];
        for (NSNumber *aNo in new)
        {
            [newSet addIndex:aNo.integerValue];
        }
        *newIndices = newSet;
    }
    if (oldIndices) {
        NSMutableIndexSet *oldSet = [NSMutableIndexSet new];
        for (NSNumber *aNo in old)
        {
            [oldSet addIndex:aNo.integerValue];
        }
        *oldIndices = oldSet;
    }
}

- (void)sortUsingDescriptors:(NSArray *)sortDescriptors 
                  oldIndexes:(NSArray**)oldIndices
                  newIndexes:(NSArray**)newIndices;
{
    
    NSMutableArray *old = [NSMutableArray new];
    NSMutableArray *new = [NSMutableArray new];
    NSMutableOrderedSet *oldOrder = nil;
    NSMutableOrderedSet *newOrder = [self objects];
    
    // Collect old indices
    
    if (oldIndices || newIndices) {
        oldOrder = [self.objects mutableCopy];
        [oldOrder enumerateObjectsUsingBlock:^(id<KCDObject>obj, NSUInteger idx, BOOL *stop) {
            [old addObject:@(idx)];
        }];
        if (oldIndices) {
            *oldIndices = old;
        }
    }
    
    // Sort the new order.
    
    [newOrder sortUsingDescriptors:sortDescriptors];
    
    // Collect new indices
    
    if (newIndices) {
        [oldOrder enumerateObjectsUsingBlock:^(id<KCDObject>obj, NSUInteger idx, BOOL *stop) {
            NSUInteger newIndex = [newOrder indexOfObject:obj];
            [new addObject:@(newIndex)];
        }];
        *newIndices = new;
    }
    
    // TODO: Sort filtered/unfiltered objects.
    [self setUnfilteredObjects:newOrder];
}

- (void)sortUsingComparator:(NSComparator)cmptr;
{
    [self.objects sortUsingComparator:cmptr];
}

- (void)sortUsingDescriptors:(NSArray*)sortDescriptors;
{
    [self.objects sortUsingDescriptors:sortDescriptors];
}

// Predicates affect adding objects, etc. 
// Does not handle inserts/delete animation: datasource must reload data for section.

- (NSMutableOrderedSet *)filteredObjectsWithPredicate:(NSPredicate*)predicate;
{
    NSMutableOrderedSet *filteredObjects = [self.unfilteredObjects mutableCopy];
    [filteredObjects filterUsingPredicate:predicate];
    return filteredObjects;
}

#pragma mark - Accessors

- (NSMutableOrderedSet *)objects;
{
    // If a filter has been applied to this section, return the filtered objects.
    return ([self filteredObjects]) ? [self filteredObjects] : [self unfilteredObjects];
}

- (void)setPredicate:(NSPredicate *)predicate;
{
    if (predicate != _predicate) {
        _predicate = predicate;
        // If clearing predicate, also clear filtered objects.
        [self setFilteredObjects:(predicate) ? [self filteredObjectsWithPredicate:predicate] : nil];
    }
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone;
{
    KCDSectionContainer *copy = [[[self class] alloc] initWithSectionName:_sectionName objects:nil];
    copy->_unfilteredObjects = [_unfilteredObjects mutableCopy];
    copy->_filteredObjects = [_filteredObjects mutableCopy];
    copy->_predicate = [_predicate copy];
    copy->_sectionName = [_sectionName copy];
    copy->_sectionHeader = [_sectionHeader copy];
    copy->_sectionFooter = [_sectionFooter copy];
    copy->_sectionIdentifier = [_sectionIdentifier copy];
    copy->_sortDescriptors = [_sortDescriptors copy];
    return copy;
}

#pragma mark - Foundation

- (id)objectAtIndexedSubscript:(NSUInteger)idx;
{
    // Note objects is dynamic
    return self.objects[idx];
}
- (void)setObject:(id)obj atIndexedSubscript:(NSUInteger)idx;
{
    // Note: objects is dynamic
    self.objects[idx] = obj;
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object;
{
    // Copies of section objects must be able able to pass isEqual comparisons to their originals _without_ regard to object contents.
    if ([object isKindOfClass:[self class]]) {
        return [((KCDSectionContainer *)object)->_sectionIdentifier isEqualToString:_sectionIdentifier];
    }
    return [super isEqual:object];
}

- (NSUInteger)hash;
{
    return [_sectionIdentifier hash];
}

- (NSString*)description;
{
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@ ", NSStringFromClass([self class])];
    if ([self sectionName]) {
        [description appendFormat:@"(%@) ", self.sectionName];
    }
    [description appendFormat:@"[%@]", @([self.objects count])];
    [description appendFormat:@" %p>", self];
    return description;
}

@end

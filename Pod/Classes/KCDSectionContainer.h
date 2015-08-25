//
//  KCDSectionContainer.h
//
//  Created by Nicholas Zeltzer on 11/2/11.
//

@import Foundation;

#import "KCDObjectProtocol.h"
#import "KCDSectionProtocol.h"

/**
 KCDSectionContainer is a private implementation of the KCDSortableSection protocol that is used by KCDObjectController internals. 
 
 API consumers should never interact with KCDSectionContainers directly as instances of this class – instead interaction should be limited to the API described by the appropriate protocol assigned to the section objects as returned by the object controller.
 */

@interface KCDSectionContainer : NSObject <KCDSection>

#pragma mark Initialization

- (instancetype)initWithSectionName:(NSString*)sectionName
                            objects:(NSArray KCDGeneric(id<KCDObject>) *)objects NS_DESIGNATED_INITIALIZER;

#pragma mark Introspection

- (BOOL)containsObject:(id<KCDObject>)object;

- (NSInteger)indexOfObject:(id<KCDObject>)object;

- (id<KCDObject>)objectAtIndex:(NSInteger)index;

/**
 Perform a deep comparison to another section object, including the contents of the section.
 */

- (BOOL)isEqualToSection:(id<KCDSection>)section;

#pragma mark Enumeration

/**
 This is merely a pipe to the identically-named method on NSOrderedSet. This implementation does not implement NSFastEnumeration internally.
 */

- (void)enumerateObjectsUsingBlock:(void (^)(id<KCDObject> obj, NSUInteger idx, BOOL *stop))block;

@end

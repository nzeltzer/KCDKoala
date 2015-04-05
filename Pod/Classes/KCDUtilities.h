//
//  KCDUtilities.h
//  KCDKoala
//
//  Created by Nicholas Zeltzer on 10/30/14.
//  Copyright (c) 2014 LawBox LLC. All rights reserved.
//

@import Foundation;
#if TARGET_OS_IPHONE
@import UIKit;
#else
@import AppKit;
#endif

#define KCDStrictAssertEnabled 0
#define KCDKoalaLogEnabled 0

@protocol KCDMutableSection;

/** 
 Utility functions for KCDKoala
 */

@interface KCDUtilities : NSObject

BOOL KCDProtocolIncludesSelector(Protocol *aProtocol, SEL aSelector);
BOOL KCDProtocolIncludesSelectorWithOptions(Protocol *aProtocol, SEL aSelector, BOOL required, BOOL instance);

NSComparator KCDIndexPathComparator();

/**
 Demo and Default Value Utilities.
 */

NSArray *KCDRandomObjects(Class objectClass, NSInteger minimumObjects);
NSArray *KCDRandomSections(Class objectClass, NSInteger minimumSections, NSInteger minimumObjects);
NSArray *KCDRandomObjectsWithIdentifier(Class objectClass, NSString *identifier, NSInteger minimumObjects);
NSArray *KCDRandomSectionsWithIdentifier(Class objectClass, NSString *identifier, NSInteger minimumSections, NSInteger minimumObjects);
NSString *KCDNewUniqueIdentifier();
NSString *KCDRandomTitle();
id<KCDMutableSection> KCDNewSectionWithNameAndObjects(NSString *sectionName, NSArray *objects);

#if TARGET_OS_IPHONE
UIColor * KCDRandomColor();
#else
NSColor * KCDRandomColor();
#endif

@end

#if !TARGET_OS_IPHONE

/**
 Bring the NSIndexPath API into conformance with the iOS extended version.
 */

@interface NSIndexPath (KCDKoala)

+ (NSIndexPath *)indexPathForRow:(NSInteger)row inSection:(NSInteger)section;

@property (nonatomic, readonly) NSInteger section;
@property (nonatomic, readonly) NSInteger row;

@end

#endif

@interface NSMutableArray (KCDKoala)

- (BOOL)KCDArrayMoveObjectAtIndex:(NSInteger)index toIndex:(NSInteger)toIndex;

@end
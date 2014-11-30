//
//  KCDUtilities.m
//  KCDKoala
//
//  Created by Nicholas Zeltzer on 10/30/14.
//  Copyright (c) 2014 LawBox LLC. All rights reserved.
//

#import "KCDUtilities.h"
#import "KCDSectionProtocol.h"
#import "KCDObjectProtocol.h"
#import "KCDObjectController.h"
#import "KCDAbstractObject.h"
#import "KCDSectionContainer.h"
#import <objc/runtime.h>





#pragma mark - KCDUtiltiies

@implementation KCDUtilities

NSComparator KCDIndexPathComparator()
{
    NSComparator indexPathComparator = ^NSComparisonResult(NSIndexPath *indexPath1, NSIndexPath *indexPath2) {
        if (indexPath1.section > indexPath2.section) {
            return NSOrderedDescending;
        }
        if (indexPath2.section > indexPath1.section) {
            return NSOrderedAscending;
        }
        if (indexPath1.row > indexPath2.row) {
            return NSOrderedDescending;
        }
        if (indexPath2.row > indexPath1.row) {
            return NSOrderedAscending;
        }
        return NSOrderedSame;
    };
    return indexPathComparator;
}

NSString *KCDNewUniqueIdentifier()
{
    CFUUIDRef newUUID = CFUUIDCreate(kCFAllocatorDefault);
    NSString *UUIDString = (__bridge_transfer NSString *)CFUUIDCreateString(kCFAllocatorDefault, newUUID);
    CFRelease(newUUID);
    return UUIDString;
}

BOOL KCDProtocolIncludesSelectorWithOptions(Protocol *aProtocol, SEL aSelector, BOOL required, BOOL instance)
{
    unsigned int protocolMethodCount = 0;
    BOOL isRequiredMethod = required;
    BOOL isInstanceMethod = instance;
    struct objc_method_description *protocolMethodList;
    BOOL includesSelector = NO;
    
    protocolMethodList = protocol_copyMethodDescriptionList(aProtocol, isRequiredMethod, isInstanceMethod, &protocolMethodCount);
    
    for (NSUInteger m = 0; m < protocolMethodCount; m++)
    {
        struct objc_method_description aMethodDescription = protocolMethodList[m];
        SEL aMethodSelector = aMethodDescription.name;
        if (aMethodSelector == aSelector)
        {
            includesSelector = YES;
            break;
        }
    }
    free(protocolMethodList);
    return includesSelector;
}

BOOL KCDProtocolIncludesSelector(Protocol *aProtocol, SEL aSelector)
{
    // Brute force check on protocol methods.
    if (KCDProtocolIncludesSelectorWithOptions(aProtocol, aSelector, YES, YES))
    {
        return YES;
    }
    else if (KCDProtocolIncludesSelectorWithOptions(aProtocol, aSelector, NO, NO))
    {
        return YES;
    }
    else if (KCDProtocolIncludesSelectorWithOptions(aProtocol, aSelector, NO, YES))
    {
        return YES;
    }
    else if (KCDProtocolIncludesSelectorWithOptions(aProtocol, aSelector, YES, NO))
    {
        return YES;
    }
    return NO;
}

id<KCDMutableSection> KCDNewSectionWithNameAndObjects(NSString *sectionName, NSArray *objects)
{
    return (id<KCDMutableSection>)[[KCDSectionContainer alloc] initWithSectionName:sectionName objects:objects];
}

#pragma mark - Demo Content


NSString * KCDRandomTitle() {
    static NSArray *strings = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        strings = @[
                    @"11 Bananas",
                    @"23 Cans of Koala",
                    @"39 Absurdities",
                    @"41 Waffles",
                    @"55 Cookbooks",
                    @"6 Little Mice",
                    @"71 Bugs",
                    @"89 Eggs",
                    @"91 Porcupines",
                    @"A Polar Bear in Armor",
                    @"Beer Bread",
                    @"Cat-Proof Curtains",
                    @"Coffee Beans Behind The Counter",
                    @"Comets That Smell Like Goats",
                    @"Crumpled Scrolls",
                    @"Dogs That Play Accordians Really, Really Well",
                    @"Escaped Goats and Magic Mice",
                    @"Fifty Forgotten Grues",
                    @"Graham Crackers That Were Left In The Rain",
                    @"Houses Made With Recycled Programming Instruction Manuals",
                    @"Independent Mooses Federation",
                    @"Joyful Runway Models",
                    @"Kafka Would Cry If He Knew What You Were Doing Now",
                    @"Lemurian Tribal Sandals",
                    @"Lost Clown Shoes",
                    @"Matchstick Cars With Enormous Outboard Motors",
                    @"Mice That Call In Prank Pizza Deliveries To Your House",
                    @"Novelty Religious Artifacts",
                    @"Office Plants That Get Away From You",
                    @"Oranges",
                    @"Porcupine Voting Rights",
                    @"Questions That The Wrong People Answer Correctly",
                    @"Revolting Squirrels",
                    @"Roasted Apples With Blue Cheese",
                    @"Short Handles on Long Bags",
                    @"The @ Symbol is attacking you!",
                    @"The Batteries That Weren't Included",
                    @"Tiny People With Big Hands",
                    @"Universal Toothpick Distributors Annual Shark Meet and Greet",
                    @"Voltron Idols Made From He-Man Action Figure Parts",
                    @"Water Beds and Porcupines",
                    @"Xanadu Has Rooms For Let",
                    @"Yaks with Sandals",
                    @"Zebras Waiting For Taxis in the Rain"
                    ];
    });
    NSInteger index = arc4random() % [strings count];
    return strings[index];
}


#if TARGET_OS_IPHONE
UIColor * KCDRandomColor() {
    CGFloat (^randomValue)() = ^CGFloat(){
        return ((double)(arc4random() % 255))/255.0f;
    };
    return [UIColor colorWithRed:randomValue()
                           green:randomValue()
                            blue:randomValue()
                           alpha:1];
}
#else
NSColor * KCDRandomColor() {
    CGFloat (^randomValue)() = ^CGFloat(){
        return ((double)(arc4random() % 255))/255.0f;
    };
    return [NSColor colorWithCalibratedRed:randomValue()
                                     green:randomValue()
                                      blue:randomValue()
                                     alpha:1];
}
#endif

NSArray *KCDRandomSectionsWithIdentifier(Class objectClass, NSString *identifier, NSInteger minimumSections, NSInteger minimumObjects)
{
    NSMutableArray *cellSections = [NSMutableArray new];
    NSInteger count = (arc4random() % 10);
    count = MAX(count, minimumSections);
    for (NSInteger x = 0; x < count; x++)
    {
        NSString *sectionName = KCDRandomTitle();
        id<KCDMutableSection> aSection = [KCDObjectController sectionWithName:sectionName objects:KCDRandomObjectsWithIdentifier(objectClass, identifier, minimumObjects)];
        aSection.sectionHeader = [NSString stringWithFormat:@"[%@]", [sectionName uppercaseString]];
        aSection.sectionName = sectionName;
        aSection.sectionFooter = [NSString stringWithFormat:@"{%@}", [sectionName lowercaseString]];
        [cellSections addObject:aSection];
    }
    return cellSections;
}

NSArray *KCDRandomSections(Class objectClass, NSInteger minimumSections, NSInteger minimumObjects)
{
    NSMutableArray *cellSections = [NSMutableArray new];
    NSInteger count = (arc4random() % 10) + minimumSections;
    for (NSInteger x = 0; x < count; x++)
    {
        NSString *sectionName = KCDRandomTitle();
        id<KCDMutableSection> aSection = [KCDObjectController sectionWithName:sectionName objects:KCDRandomObjects(objectClass, minimumObjects)];
        aSection.sectionHeader = [NSString stringWithFormat:@"[%@]", [sectionName uppercaseString]];
        aSection.sectionName = sectionName;
        aSection.sectionFooter = [NSString stringWithFormat:@"{%@}", [sectionName lowercaseString]];
        [cellSections addObject:aSection];
    }
    return cellSections;
}

NSArray *KCDRandomObjectsWithIdentifier(Class objectClass, NSString *identifier, NSInteger minimumObjects)
{
    NSMutableArray *cellObjects = [NSMutableArray new];
    NSInteger count = (arc4random() % 10);
    count = MAX(count, minimumObjects);
    Class KCDObjectClass = (objectClass) ? objectClass : [KCDAbstractObject class];
    for (NSInteger x = 0; x < count; x++)
    {
        KCDAbstractObject * aCellObject = [[KCDObjectClass alloc]
                                       initWithIdentifier:identifier];
        if ([aCellObject respondsToSelector:@selector(setTitle:)]) {
            aCellObject.title = KCDRandomTitle();
        }
        [cellObjects addObject:aCellObject];
    }
    return cellObjects;
}

NSArray *KCDRandomObjects(Class objectClass, NSInteger minimumObjects)
{
    NSMutableArray *cellObjects = [NSMutableArray new];
    NSInteger count = (arc4random() % 10) + minimumObjects;
    Class KCDObjectClass = (objectClass) ?
    objectClass :
    [KCDAbstractObject class];
    for (NSInteger x = 0; x < count; x++)
    {
        KCDAbstractObject * aCellObject = [[KCDObjectClass alloc] init];
        if ([aCellObject respondsToSelector:@selector(setTitle:)]) {
            aCellObject.title = KCDRandomTitle();
        }
        [cellObjects addObject:aCellObject];
    }
    return cellObjects;
}

@end

@implementation NSMutableArray (KCDKoala)

- (BOOL)KCDMoveObjectAtIndex:(NSInteger)index toIndex:(NSInteger)toIndex;
{
    if (toIndex < self.count) {
        id obj = self[index];
        [self removeObjectAtIndex:index];
        [self insertObject:obj atIndex:toIndex];
        return YES;
    }
    return NO;
}

@end

#if !TARGET_OS_IPHONE

@implementation NSIndexPath (KCDKoala)

const char * kKCDIndexPathRow = "kKCDIndexPathRow";
const char * kKCDIndexPathSection = "kKCDIndexPathSection";

- (NSInteger)section;
{
    return [objc_getAssociatedObject(self, kKCDIndexPathSection) integerValue];
}

- (NSInteger)row;
{
    return [objc_getAssociatedObject(self, kKCDIndexPathRow) integerValue];
}

- (void)setSection:(NSInteger)section;
{
    objc_setAssociatedObject(self, kKCDIndexPathSection, @(section), OBJC_ASSOCIATION_RETAIN);
}

- (void)setRow:(NSInteger)row;
{
    objc_setAssociatedObject(self, kKCDIndexPathRow, @(row), OBJC_ASSOCIATION_RETAIN);
}

+ (NSIndexPath *)indexPathForRow:(NSInteger)row inSection:(NSInteger)section;
{
    NSIndexPath *indexPath = [[NSIndexPath alloc] initWithIndex:row];
    indexPath.section = section;
    indexPath.row = row;
    return indexPath;
}

@end
#endif

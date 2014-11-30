//
//  KCDObjectController (KCDDemoApp)
//  KCDKoala
//
//  Created by Nicholas Zeltzer on 10/29/14.
//  Copyright (c) 2014 Nicholas Zeltzer
//

#import "KCDObjectController+KCDDemoApp.h"
#import "KCDDemoTableViewCell.h"
#import "KCDDemoCollectionViewCell.h"
#import "KCDDemoObject.h"
#import "KCDDemoReusableView.h"

@implementation KCDObjectController (KCDDemoApp)

#ifndef DLog
#ifdef DEBUG
// Debug build logging.
#define DLog(...) NSLog(@"%s %@", __PRETTY_FUNCTION__, [NSString stringWithFormat:__VA_ARGS__])
#else
#define DLog(...) /**/
#endif
#endif


- (void)KCDDemoDiffForever:(NSString *)identifier;
{
    // Warning: a transaction delay will delay deallocation of the controller.
    self->_KCDTransactionDelay = ([self isKindOfClass:[KCDTableViewDataSource class]]) ? 0.3 : 0.0f;
    KCDObjectController *__weak weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [weakSelf KCDDemoDiff:identifier completion:^{
            [weakSelf KCDDemoDiffForever:identifier];
        }];
    });
}

- (void)KCDDemoShuffleForever;
{
    // Warning: a transaction delay will delay deallocation of the controller.
    self->_KCDTransactionDelay = ([self isKindOfClass:[KCDTableViewDataSource class]]) ? 0.3 : 0.0f;
    KCDObjectController *__weak weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [weakSelf KCDDemoShuffle:^{
            [weakSelf KCDDemoShuffleForever];
        }];
    });
}

- (void)KCDDemoAPIForever:(NSString *)identifier;
{
    // Warning: a transaction delay will delay deallocation of the controller.
    self->_KCDTransactionDelay = ([self isKindOfClass:[KCDTableViewDataSource class]]) ? 0.3 : 0.0f;
    KCDObjectController *__weak weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [weakSelf KCDDemoAPI:identifier completion:^{
            [weakSelf KCDDemoAPIForever:identifier];
        }];
    });
}

#pragma mark - API Walkthrough

- (void)KCDDemoAPI:(NSString *)identifier
        completion:(void(^)())completion;
{
    Class KCDObjectClass = [KCDDemoObject class];
    [self queueTransaction:^(KCDObjectController *koala) {
        [koala insertSectionWithName:@"Section One" objects:nil atIndex:0 animation:0];
        NSArray *randomObjects1 = KCDRandomObjectsWithIdentifier(KCDObjectClass, identifier, 5);
        [koala insertSectionWithName:@"Section Zero" objects:randomObjects1 atIndex:0 animation:0];
        NSArray *randomObjects2 = KCDRandomObjectsWithIdentifier(KCDObjectClass, identifier, 5);
        [koala addSectionWithName:@"Section Two" objects:randomObjects2 animation:0];
        [koala deleteSectionAtIndex:0 animation:0];
        [koala deleteSectionAtIndex:1 animation:0];
        [koala deleteSectionAtIndex:0 animation:0];
        id<KCDSection> newSectionB = [koala newSectionWithName:@"Section B" objects:KCDRandomObjectsWithIdentifier(KCDObjectClass, identifier, 5)];
        [koala addSection:newSectionB animation:0];
        id<KCDSection> newSectionA = [koala newSectionWithName:@"Section A" objects:KCDRandomObjectsWithIdentifier(KCDObjectClass, identifier, 5)];
        [koala insertSection:newSectionA atIndex:0 animation:0];
        id<KCDSection>newSectionC = [koala newSectionWithName:@"Section C" objects:KCDRandomObjectsWithIdentifier(KCDObjectClass, identifier, 5)];
        [koala insertSection:newSectionC atIndex:0 animation:0];
        [koala moveSection:newSectionC toIndex:2];
        [koala moveSection:newSectionB toIndex:2];
        [koala moveSection:newSectionA toIndex:2];
        [koala moveSections:@[newSectionA, newSectionB, newSectionC] toIndices:@[@(0), @(1), @(2)]];
        [koala moveSectionsAtIndices:@[@(0), @(1), @(2)] toIndices:@[@(2), @(1), @(0)]];
        id<KCDSection>newSectionD = [koala newSectionWithName:@"Section D" objects:KCDRandomObjectsWithIdentifier(KCDObjectClass, identifier, 5)];
        [koala insertSection:newSectionD atIndex:0 animation:0];
        [koala sortSectionsWithComparator:^NSComparisonResult(id<KCDSection> obj1, id<KCDSection> obj2) {
            return [[obj1 sectionName] localizedCaseInsensitiveCompare:[obj2 sectionName]];
        }];
        [koala deleteAllSections:0];
    
        // Test object methods.
        
        [koala queueTransaction:^(KCDObjectController *koala) {
            [koala insertSectionWithName:@"Section One" objects:nil atIndex:0 animation:0];
            NSArray *randomObjects1 = KCDRandomObjectsWithIdentifier(KCDObjectClass, identifier, 5);
            [koala insertSectionWithName:@"Section Zero" objects:randomObjects1 atIndex:0 animation:0];
            NSArray *randomObjects2 = KCDRandomObjectsWithIdentifier(KCDObjectClass, identifier, 5);
            [koala addSectionWithName:@"Section Two" objects:randomObjects2 animation:0];
            NSArray *randomObjects3 = KCDRandomObjectsWithIdentifier(KCDObjectClass, identifier, 5);
            [koala addSectionWithName:@"Section Three" objects:randomObjects3 animation:0];
            NSArray *randomObjectsA = KCDRandomObjectsWithIdentifier(KCDObjectClass, identifier, 5);
            [randomObjectsA enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                [koala insertObject:obj atIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animation:0];
            }];
            [randomObjectsA enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                [koala deleteObject:obj animation:UITableViewRowAnimationLeft];
            }];
            // Moves
            [koala addObjects:randomObjectsA toSectionAtIndex:0 animation:0];
            [randomObjectsA enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                [koala moveObject:obj
                      toIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];
            }];
            NSMutableArray *indexPaths = [NSMutableArray new];
            [randomObjectsA enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                [indexPaths addObject:[NSIndexPath indexPathForRow:idx inSection:0]];
            }];
            [koala moveObjects:randomObjectsA toIndexPaths:indexPaths];
            [koala moveObjectsAtIndexPaths:indexPaths toIndexPaths:[indexPaths.reverseObjectEnumerator allObjects]];
            
            // Test arrangement transactions
            
            [koala queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
                NSArray *oldSections = [[koala sections] copy];
                id<KCDSection>sectionA = [koala newSectionWithName:@"Section Alpha" objects:KCDRandomObjectsWithIdentifier(KCDObjectClass, identifier, 10)];
                [koala insertSection:sectionA atIndex:0 animation:0];
                id<KCDMutableSection> newSectionA = [(id)sectionA copy];
                [sectionA.objects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    if (idx % 2 == 0) {
                        [newSectionA removeObject:obj];
                    }
                }];
                [oldSections enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    [koala setSections:@[obj] animation:0 completion:nil];
                }];
                [koala setSections:@[newSectionA] animation:0 completion:nil];
                [koala setSections:@[sectionA] animation:0 completion:nil];
                [koala setSections:@[newSectionA] animation:0 completion:nil];
                [newSectionA.objects.reverseObjectEnumerator.allObjects enumerateObjectsUsingBlock:^(id<KCDObject> obj, NSUInteger idx, BOOL *stop) {
                    [koala deleteObject:obj
                              animation:UITableViewRowAnimationRight];
                }];
                [koala deleteSection:newSectionA animation:UITableViewRowAnimationFade];
                [koala deleteAllSections:UITableViewRowAnimationFade];
                [koala queueAction:completion];
            }];
        }];
    }];
}

#pragma mark - Rearrangement

- (void)KCDDemoDiff:(NSString *)identifier
         completion:(void(^)())completion;
{
    
    // Create a copy of the controller's contents and randomly move, delete, and add sections and objects.
    // Then animate a transaction between the original contents and rearragned contents.
    
    [self queueArrangement:^(KCDObjectController<KCDIntrospective>*koala, NSMutableArray *newArrangement) {
        // Replace one section.
        if (koala.sections.count > 0) {
            id<KCDSection>newSection1 = [KCDRandomSectionsWithIdentifier([KCDDemoObject class], identifier, 1, 1) firstObject];
            [newArrangement replaceObjectAtIndex:0 withObject:newSection1];
            // Insert one section
            id<KCDSection>newSection2 = [KCDRandomSectionsWithIdentifier([KCDDemoObject class], identifier, 1, 1) firstObject];
            [newArrangement insertObject:newSection2 atIndex:arc4random() % newArrangement.count];
            // Shuffle sections up to three times.
            [newArrangement KCDMoveObjectAtIndex:arc4random() % newArrangement.count toIndex:arc4random() % newArrangement.count];
            [newArrangement KCDMoveObjectAtIndex:arc4random() % newArrangement.count toIndex:arc4random() % newArrangement.count];
            [newArrangement KCDMoveObjectAtIndex:arc4random() % newArrangement.count toIndex:arc4random() % newArrangement.count];
        }
        // Delete random objects from the sections
        [newArrangement enumerateObjectsUsingBlock:^(id<KCDMutableSection>section, NSUInteger idx, BOOL *stop) {
            NSInteger objectCount = [section.objects count];
            if (objectCount > 0) {
                // Randomly add an object
                if (arc4random() % objectCount % 2 == 0) {
                    // Randomly add a new object.
                    KCDDemoObject * newObject = [[KCDDemoObject alloc] initWithIdentifier:identifier];
                    newObject.title = KCDRandomTitle();
                    [section addObject:newObject index:NULL];
                }
                // Randomly move an object within a section
                if (arc4random() % objectCount % 3 == 0) {
                    id<KCDObject> randomObject = [section objectAtIndex:arc4random() % objectCount];
                    [section removeObject:randomObject];
                    NSInteger randomRow = arc4random() % objectCount;
                    [section insertObject:randomObject atIndex:&randomRow];
                }
                if (arc4random() % objectCount % 2 == 0) {
                    // Randomly remove an object.
                    [section removeObjectAtIndex:arc4random() % objectCount];
                }
            }
        }];
        if (newArrangement.count > 0) {
            // Randomly move objects between random sections.
            for (NSInteger x = 0; x < newArrangement.count; x++) {
                id<KCDMutableSection>fromSection = newArrangement[arc4random() % newArrangement.count];
                id<KCDMutableSection>toSection = newArrangement[arc4random() % newArrangement.count];
                if (fromSection.objects.count > 0) {
                    id<KCDObject> object = fromSection[arc4random()%fromSection.objects.count];
                    [fromSection removeObject:object];
                    NSInteger row = (toSection.objects.count > 0) ? arc4random() % toSection.objects.count : 0;
                    [toSection insertObject:object atIndex:&row];
                }
            }
        }
        // Randomly delete a section
        if ([newArrangement count] > 0) {
            NSInteger deleteASection = arc4random() % [newArrangement count];
            if (deleteASection % 2 == 0) {
                NSInteger sectionIndexToDelete = arc4random() % [newArrangement count];
                [newArrangement removeObjectAtIndex:sectionIndexToDelete];
            }
        }
    }
                 animation:0
                completion:completion];
}

#pragma mark - Shuffle

- (void)KCDDemoShuffle:(void(^)())completionHandler;
{
    
    KCDObjectController *__weak weakSelf = self;
    
    void (^shuffleItems)() = ^{
        // Randomly move an item
        [weakSelf queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
            if (koala.sections.count > 0) {
                NSIndexPath *fromIndexPath = [koala randomFromIndexPath:koala];
                NSIndexPath *toIndexPath = [koala randomToIndexPath:koala];
                [koala moveObjectsAtIndexPaths:@[fromIndexPath]
                                  toIndexPaths:@[toIndexPath]];
            }
        }];
    };
    
    void (^shuffleSections)() = ^{
        // Randomly move a section
        [weakSelf queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
            NSInteger sectionCount = [koala.sections count];
            if (sectionCount > 1) {
                NSInteger randomFromIndex = arc4random() % sectionCount;
                NSInteger randomToIndex = arc4random() % sectionCount;
                id<KCDSection> aSection = [koala sectionAtIndex:randomFromIndex];
                [koala moveSection:aSection toIndex:randomToIndex];
                [koala KCDemoSortSectionAlphabeticallyAtIndex:0];
            }
        }];
    };
    
    void (^shuffle)() = ^{
        if ((arc4random() % 10) % 2 == 0) {
            shuffleSections();
        }
        else {
            shuffleItems();
        }
        [weakSelf queueAction:completionHandler];
    };
    
    shuffle();
}

#pragma mark - Utilities

- (NSIndexPath *)randomToIndexPath:(KCDObjectController<KCDIntrospective>*)koala;
{
    KCDObjectController<KCDIntrospective>*__weak weakSelf = koala;
    NSUInteger randomSectionIndex = arc4random() % [weakSelf.sections count];
    NSUInteger objectCount = [[[weakSelf sectionAtIndex:randomSectionIndex] objects] count];
    NSUInteger randomIndex = 0;
    if (objectCount != 0)
    {
        randomIndex = arc4random() %  objectCount;
    }
    NSIndexPath *endIndexPath = [NSIndexPath indexPathForRow:randomIndex inSection:randomSectionIndex];
    return endIndexPath;
}

- (NSIndexPath *)randomFromIndexPath:(KCDObjectController<KCDIntrospective>*)koala;
{
    KCDObjectController<KCDIntrospective>*__weak weakSelf = koala;
    NSUInteger objectCountAtStartSection = 0;
    NSIndexPath *startIndexPath = nil;
    if (weakSelf.sections.count > 0) {
        while (objectCountAtStartSection == 0)
        {
            NSUInteger randomStartSection = arc4random() % [weakSelf.sections count];
            objectCountAtStartSection = [[[weakSelf sectionAtIndex:randomStartSection] objects] count];
            if (objectCountAtStartSection != 0)
            {
                NSUInteger randomStartIndex = arc4random() % objectCountAtStartSection;
                startIndexPath = [NSIndexPath indexPathForRow:randomStartIndex inSection:randomStartSection];
            }
        }
    }
    else {
        startIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    }
    return startIndexPath;
}

- (void)KCDemoSortSectionAlphabeticallyAtIndex:(NSInteger)index;
{
    KCDObjectController *__weak weakSelf = self;
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES comparator:^NSComparisonResult(NSString * obj1, NSString * obj2) {
        return [obj1 localizedCaseInsensitiveCompare:obj2];
    }];
    [weakSelf sortSectionAtIndex:index usingDescriptors:@[sort]];
}

@end
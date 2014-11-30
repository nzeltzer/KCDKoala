//
//  KCDKoalaMobile_Tests.m
//  KCDKoalaMobile Tests
//
//  Created by Nicholas Zeltzer on 11/2/14.
//  Copyright (c) 2014 LawBox LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "KCDKoala.h"

@interface KCDKoalaMobile_Tests : XCTestCase

@property (nonatomic, readwrite, strong) KCDObjectController *objectController;
@property (nonatomic, readwrite, strong) UITableView *tableView;

@end

@implementation KCDKoalaMobile_Tests

- (void)setUp {
    [super setUp];
    // KCDObjectController is abstract, so we use a designated subclass.
    self.objectController = ({
        KCDTableViewDataSource *source = [[KCDTableViewDataSource alloc] initWithDelegate:nil];
        // By default, KCDTableViewDataSource enforces a 1/4 second delay between animations.
        source.transactionStaggerDuration = 0.0f;
        // The controller will not commit transactions absent a view.
        self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
        source.tableView = self.tableView;
        source;
    });
}

- (void)populateControllerWithSections:(NSInteger)minimumSectionCount objects:(NSInteger)minimumObjectsCount;
{
    NSArray *randomSections = KCDRandomSections([KCDAbstractObject class], minimumSectionCount, minimumObjectsCount);
    [randomSections enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [self.objectController insertSection:obj atIndex:0 animation:0];
    }];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    self.objectController = nil;
    XCTAssertTrue(_objectController == nil, @"Datasource did not release");
    [super tearDown];
}

- (void)testInterestedTransation;
{
    KCDObjectController *__weak weakController = [self objectController];
    
    XCTestExpectation *interested = [self expectationWithDescription:nil];
    
    KCDSectionContainer *sectionOne = [[KCDSectionContainer alloc] initWithSectionName:@"Section One" objects:nil];
    KCDSectionContainer *sectionTwo = [[KCDSectionContainer alloc] initWithSectionName:@"Section Two" objects:nil];
    
    [weakController insertSection:sectionOne
                          atIndex:0 animation:0];
    
    [weakController insertSection:sectionTwo
                          atIndex:1 animation:0];
    
    KCDAbstractObject *object1 = [[KCDAbstractObject alloc] init];
    KCDAbstractObject *object2 = [[KCDAbstractObject alloc] init];
    
    object1.title = @"Object One";
    object2.title = @"Object Two";
    
    NSIndexPath *fsfo = [NSIndexPath indexPathForRow:0 inSection:0];
    NSIndexPath *ssfo = [NSIndexPath indexPathForRow:0 inSection:1];
    
    // Insert obj1 then obj2
    [weakController insertObject:object1 atIndexPath:fsfo animation:0];
    [weakController insertObject:object2 atIndexPath:ssfo animation:0];
    [weakController queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
        XCTAssert(object1 == [koala objectAtIndexPath:fsfo]);
        XCTAssert(object2 == [koala objectAtIndexPath:ssfo]);
    }];
    
    // Move 0.0 to 1.0, then 1.1 to 0.0
    [weakController moveObjectsAtIndexPaths:@[fsfo] toIndexPaths:@[ssfo]];
    [weakController moveObjectsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:1]] toIndexPaths:@[fsfo]];
    [weakController queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
        XCTAssert(object1 == [koala objectAtIndexPath:ssfo]);
        XCTAssert(object2 == [koala objectAtIndexPath:fsfo]);
    }];
    
    // Move obj1 to 0.0, then obj2 to 0.0
    [weakController moveObject:object2 toIndexPath:fsfo];
    [weakController moveObject:object1 toIndexPath:fsfo];
    [weakController queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
        XCTAssert(object1 == [koala objectAtIndexPath:fsfo]);
        XCTAssert(object2 == [koala objectAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]]);
    }];
    
    // Because we used addSection:objects:animation:completion, an
    // asynchronous method, to create the sections, we can't access
    // the section objects in this scope: we have to use indices
    // to move them. 
    
    // Move section 0 to 1
    [weakController moveSectionAtIndex:0 toIndex:1];
    [weakController queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
        XCTAssert([[[koala sectionAtIndex:1] sectionName] isEqualToString:@"Section One"]);
    }];
    
    // Move obj2 to 0.0
    [weakController moveObject:object2 toIndexPath:fsfo];
    [weakController queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
        XCTAssert(object2 == [koala objectAtIndexPath:fsfo]);
    }];
    
    // Move obj1 to 0.0
    [weakController moveObject:object1 toIndexPath:fsfo];
    [weakController queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
        XCTAssert(object1 == [koala objectAtIndexPath:fsfo]);
    }];
    
    // Move obj2 to 0.0
    [weakController moveObject:object2 toIndexPath:fsfo];
    [weakController queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
        XCTAssert(object2 == [koala objectAtIndexPath:fsfo]);
    }];
    
    // Move Section 0 to 1
    [weakController moveSectionAtIndex:1 toIndex:0];
    [weakController queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
        XCTAssert(object1 == [koala objectAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:1]]);
        XCTAssert(object2 == [koala objectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]]);
    }];

    [weakController queueTransaction:^(KCDObjectController *koala) {
        [interested fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5 handler:nil];
}

- (void)testNestedScheduling;
{
    // You can nest actions to preserve the order of elements.
    XCTestExpectation *expect = [self expectationWithDescription:nil];
    KCDObjectController *controller = [self objectController];
    NSArray *randomSections = KCDRandomSections([KCDAbstractObject class], 5, 5);
    [controller addSections:randomSections animation:0];
    [controller queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
        // The koala reference is weak.
        id <KCDSection> section2 = [koala sectionAtIndex:2];
        id <KCDSection> section4 = [koala sectionAtIndex:4];
        [koala moveSectionAtIndex:2 toIndex:3];
        [koala queueAction:^ {
            XCTAssert([koala sectionAtIndex:3] == section2);
            [koala moveSectionAtIndex:4 toIndex:0];
            [koala queueAction:^{
                XCTAssert([koala sectionAtIndex:0] == section4);
                [koala queueAction:^{
                    [expect fulfill];
                }];
            }];
        }];
    }];

    [self waitForExpectationsWithTimeout:5 handler:nil];
    self.objectController = nil;
    XCTAssert(!_objectController);
}

- (void)testSectionDiffing;
{
    XCTestExpectation *expectation = [self expectationWithDescription:nil];
    [self populateControllerWithSections:5 objects:5];
    NSMutableArray *newArrangement = [NSMutableArray new];
    [self.objectController queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
        [koala.sections enumerateObjectsUsingBlock:^(id<KCDSection> obj, NSUInteger idx, BOOL *stop) {
            [newArrangement addObject:[(id)obj copy]];
        }];
        NSMutableArray *insertedObjects = [NSMutableArray new];
        for (NSInteger i = 0; i < [newArrangement count]; i++) {
            KCDAbstractObject *newObject = [[KCDAbstractObject alloc] init];
            newObject.title = KCDRandomTitle();
            [insertedObjects addObject:newObject];
        }
        NSMutableArray *movedObjects = [NSMutableArray new];
        [newArrangement enumerateObjectsUsingBlock:^(id<KCDMutableSection> obj, NSUInteger idx, BOOL *stop) {
            id<KCDObject> firstObject = [obj objectAtIndex:0];
            [movedObjects addObject:firstObject];
            [obj removeObject:firstObject];
            NSInteger index = 3;
            [obj insertObject:insertedObjects[idx] atIndex:&index];
            [obj removeObject:[obj.objects lastObject]];
        }];
        id<KCDSection> lastSection = [newArrangement lastObject];
        [newArrangement removeObject:lastSection];
        [newArrangement insertObject:lastSection atIndex:0];
        id<KCDSection> newSection = [self.objectController newSectionWithName:@"New Section" objects:movedObjects];
        [newArrangement insertObject:newSection atIndex:3];
        [newArrangement removeObject:newArrangement.lastObject];
    }];
    
    [self.objectController queueTransaction:^(KCDObjectController * koala) {
        [koala queueArrangement:^(KCDObjectController<KCDIntrospective>* koala, NSMutableArray *sections) {
            [sections removeAllObjects];
            [sections addObjectsFromArray:newArrangement];
        } animation:0 completion:nil];
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:15 handler:nil];
}

- (void)testArrangedObjectsTransitioning;
{
    
    XCTestExpectation *expectation = [self expectationWithDescription:nil];
    
    __block NSArray *newArrangement = nil;
    __block NSArray *oldArrangement = nil;
    
    [self.objectController queueTransaction:^(KCDObjectController * koala) {
        
        NSArray *sections = KCDRandomSections(Nil, 5, 5);
        NSMutableArray *rearrangedSections = [sections mutableCopy];
        [sections enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [rearrangedSections addObject:[(id)obj copy]];
        }];
        
        // Delete some sections
        [sections enumerateObjectsUsingBlock:^(id<KCDSection> obj, NSUInteger idx, BOOL *stop) {
            if ((arc4random() % 10) % 2 == 0 && [rearrangedSections count] > 1) {
                [rearrangedSections removeObject:obj];
            }
        }];
        
        // Create some sections
        
        NSInteger insertCount = arc4random() % 5;
        for (NSInteger x = 0; x < insertCount; x++)
        {
            id<KCDMutableSection>newSection = [self.objectController newSectionWithName:[NSString stringWithFormat:@"New Section %@", @(x)] objects:nil];
            if ((arc4random() % 10) % 2 == 0) {
                // Randomly add some random objects.
                NSInteger objectCount = arc4random() % 10;
                for (NSInteger o = 0; o < objectCount; o++)
                {
                    KCDAbstractObject *newObject = [[KCDAbstractObject alloc] init];
                    newObject.title = KCDRandomTitle();
                    [newSection addObject:newObject index:NULL];
                }
            }
            NSInteger insertIndex = arc4random() % [rearrangedSections count];
            [rearrangedSections insertObject:newSection atIndex:insertIndex];
        }
        
        // Add some objects to existing sections
        
        [rearrangedSections enumerateObjectsUsingBlock:^(id<KCDMutableSection> obj, NSUInteger idx, BOOL *stop) {
            if (arc4random() % 2 == 0) {
                KCDAbstractObject *newObject = [[KCDAbstractObject alloc] init];
                newObject.title = KCDRandomTitle();
                [obj addObject:newObject index:NULL];
            }
        }];
        
        // Delete some objects
        
        [rearrangedSections enumerateObjectsUsingBlock:^(id<KCDMutableSection> obj, NSUInteger idx, BOOL *stop) {
            if (obj.objects.count > 0) {
                NSInteger deleteIndex = arc4random() % obj.objects.count;
                [obj removeObjectAtIndex:deleteIndex];
            }
        }];
        
        // Move some sections
        
        if (rearrangedSections.count > 0) {
            
            for (NSInteger x = 0; x < [rearrangedSections count]; x++)
            {
                if ((arc4random() % 10) % 2 == 0) {
                    NSInteger toIndex = arc4random() % [rearrangedSections count];
                    NSInteger fromIndex = arc4random() % [rearrangedSections count];
                    id<KCDSection>sectionToMove = rearrangedSections[fromIndex];
                    [rearrangedSections removeObjectAtIndex:fromIndex];
                    [rearrangedSections insertObject:sectionToMove atIndex:toIndex];
                }
            }
        }
        oldArrangement = sections;
        newArrangement = sections;
    }];
    
    [self.objectController addSections:oldArrangement animation:0];

    
    [self.objectController queueArrangement:^(KCDObjectController<KCDIntrospective> *koala, NSMutableArray *sections) {
        [sections removeAllObjects];
        [sections addObjectsFromArray:newArrangement];
    }
                                       animation:0
                                      completion:^(KCDObjectController<KCDIntrospective>* koala) {
                                          void (^logFailure)() = ^{
                                              NSLog(@"EXPECTATION: %@", newArrangement);
                                              NSLog(@"RESULT: %@", [koala sections]);
                                          };
                                          [newArrangement enumerateObjectsUsingBlock:^(id<KCDSection> expectationSection, NSUInteger idx, BOOL *stop) {
                                              id<KCDSection>resultSection = koala.sections[idx];
                                              if (![resultSection isEqual:expectationSection] ||
                                                  resultSection.objects.count != expectationSection.objects.count)
                                              {
                                                  logFailure();
                                              }
                                              XCTAssert([resultSection isEqual:expectationSection], @"Incorrect section");
                                              XCTAssert(resultSection.objects.count == expectationSection.objects.count, @"Incorrect object count");
                                              [expectationSection.objects enumerateObjectsUsingBlock:^(id<KCDObject>expectationObject, NSUInteger idx, BOOL *stop) {
                                                  id<KCDObject>resultObject = resultSection.objects[idx];
                                                  if (resultObject != resultSection.objects[idx]) {
                                                      logFailure();
                                                  }
                                                  XCTAssert([resultObject isEqual:expectationObject], @"Incorrect object");
                                              }];
                                          }];
                                          [expectation fulfill];
                                      }];
    
    [self waitForExpectationsWithTimeout:15 handler:nil];
}

#pragma mark - Adding Sections

- (void)testInsertSectionAtIndex;
{
    XCTestExpectation *expectation = [self expectationWithDescription:nil];
    KCDObjectController *controller = [self objectController];
    id<KCDSection>first = [KCDObjectController sectionWithName:@"First" objects:nil];
    [controller insertSection:first atIndex:0 animation:0];
    [controller queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
        XCTAssert([koala.sections[0] isEqual:first]);
    }];
    id<KCDSection>second = [KCDObjectController sectionWithName:@"Second" objects:nil];
    [controller insertSection:second atIndex:1 animation:0];
    [controller queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
        XCTAssert([koala.sections[1] isEqual:second]);
    }];
    id<KCDSection>third = [KCDObjectController sectionWithName:@"Third" objects:nil];
    [controller insertSection:third atIndex:2 animation:0];
    [controller queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
        XCTAssert([koala.sections[2] isEqual:third]);
    }];
    id<KCDSection>fourth = [KCDObjectController sectionWithName:@"Fourth" objects:nil];
    [controller insertSection:fourth atIndex:1 animation:0];
    [controller queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
        XCTAssert([koala.sections[1] isEqual:fourth]);
    }];
    [controller insertSection:fourth atIndex:0 animation:0]; // Inserting previously-present
    [controller queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
        XCTAssert([koala.sections[0] isEqual:fourth]);
    }];
    id<KCDSection>sixth = [KCDObjectController sectionWithName:@"Sixth" objects:nil];
    [controller insertSection:sixth atIndex:99 animation:0]; // Out of bounds
    [controller queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
        XCTAssert([koala.sections.lastObject isEqual:sixth]);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5 handler:nil];
}

- (void)testAddSection;
{
    XCTestExpectation *expectation = [self expectationWithDescription:nil];
    KCDObjectController *controller = [self objectController];
    id<KCDSection>first = [KCDObjectController sectionWithName:@"First" objects:nil];
    id<KCDSection>second = [KCDObjectController sectionWithName:@"Second" objects:nil];
    id<KCDSection>third = [KCDObjectController sectionWithName:@"Third" objects:nil];
    [controller addSection:first animation:0];
    [controller queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
        XCTAssert([koala.sections[0] isEqual:first]);
    }];
    [controller addSection:second animation:0];
    [controller queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
        XCTAssert([koala.sections[1] isEqual:second]);
    }];
    [controller addSection:third animation:0];
    [controller queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
        XCTAssert([koala.sections[2] isEqual:third]);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5 handler:nil];
}

#pragma mark Deleting Sections


- (void)testDeleteSectionByReference;
{
    XCTestExpectation *expectation = [self expectationWithDescription:nil];
    KCDObjectController *controller = [self objectController];
    NSArray *randomSections = KCDRandomSections([KCDAbstractObject class], 10, 0);
    [controller addSections:randomSections animation:0];
    [randomSections enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [controller queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
            XCTAssert([koala.sections containsObject:obj]);
        }];
        [controller deleteSection:obj animation:0];
        [controller queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
            XCTAssert(![koala.sections containsObject:obj]);
        }];
    }];
    [controller queueAction:^{
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)testDeleteSectionByIndex;
{
    XCTestExpectation *expectation = [self expectationWithDescription:nil];
    KCDObjectController *controller = [self objectController];
    NSArray *randomSections = KCDRandomSections([KCDAbstractObject class], 10, 0);
    [controller addSections:randomSections animation:0];
    [controller deleteSectionAtIndex:0 animation:0];
    [controller queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
        XCTAssert(koala.sections.count == randomSections.count-1);
        XCTAssert(![koala.sections containsObject:randomSections[0]]);
        XCTAssert([randomSections[1] isEqual:koala.sections[0]]);
        XCTAssert([koala.sections[0] isEqual:randomSections[1]]);
    }];
    [controller deleteSectionAtIndex:2 animation:0];
    [controller queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
        XCTAssert(koala.sections.count == randomSections.count-2);
        XCTAssert(![koala.sections containsObject:randomSections[3]]);
        XCTAssert([koala.sections[0] isEqual:randomSections[1]]);
        XCTAssert([koala.sections[1] isEqual:randomSections[2]]);
        XCTAssert([koala.sections[2] isEqual:randomSections[4]]);
    }];
    [controller deleteSectionAtIndex:999 animation:0];
    [controller queueAction:^{
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)testDeleteSectionsWithIndices;
{
    XCTestExpectation *expectation = [self expectationWithDescription:nil];
    KCDObjectController *controller = [self objectController];
    NSArray *randomSections = KCDRandomSections([KCDAbstractObject class], 10, 0);
    [controller addSections:randomSections animation:0];
    [controller deleteSectionsWithIndices:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 5)] animation:0];
    [randomSections enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        id<KCDObject>aSection = randomSections[idx];
        if (idx < 5) {
            [controller queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
                XCTAssert(![koala.sections containsObject:aSection]);
            }];
        }
        else {
            [controller queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
                XCTAssert([koala.sections containsObject:aSection]);
            }];
        }
    }];
    [controller deleteSectionsWithIndices:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, randomSections.count-5)] animation:0];
    [controller queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
        XCTAssert(koala.sections.count == 0);
    }];
    [controller addSections:randomSections animation:0];
    NSMutableIndexSet *indexSet = [NSMutableIndexSet new];
    [indexSet addIndex:0];
    [indexSet addIndex:1];
    [indexSet addIndex:4];
    [indexSet addIndex:7];
    [indexSet addIndex:9];
    NSMutableArray *randomWithDeletions = [randomSections mutableCopy];
    [randomWithDeletions removeObjectsAtIndexes:indexSet];
    [controller deleteSectionsWithIndices:indexSet animation:0];
    [randomWithDeletions enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [controller queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
            XCTAssert([koala.sections[idx] isEqual:obj]);
        }];
    }];
    [controller deleteSectionsWithIndices:[NSIndexSet indexSetWithIndex:9999] animation:0];
    [controller queueAction:^{
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5 handler:nil];
}

- (void)testDeleteAllSections;
{
    XCTestExpectation *expectation = [self expectationWithDescription:nil];
    KCDObjectController *controller = [self objectController];
    NSArray *randomSections = KCDRandomSections([KCDAbstractObject class], 10, 0);
    [controller addSections:randomSections animation:0];
    [controller deleteAllSections:0];
    [controller queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
        XCTAssert(koala.sections.count == 0);
    }];
    [controller queueAction:^{
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5 handler:nil];
}

- (void)testDeleteSections;
{
    XCTestExpectation *expectation = [self expectationWithDescription:nil];
    NSArray *randomSections = KCDRandomSections([KCDAbstractObject class], 5, 0); // min of five section
    KCDObjectController *controller = [self objectController];
    
    // Delete by reference.
    
    [controller addSections:randomSections animation:0];
    [randomSections enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [controller deleteSection:obj animation:0];
        [controller queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
            XCTAssert(![koala.sections containsObject:obj]);
        }];
    }];
    
    // Forwards
    
    [controller addSections:randomSections animation:0];
    [controller queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
        [randomSections enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            XCTAssert([obj isEqual:koala.sections[idx]]);
        }];
    }];
    [randomSections enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [controller deleteSectionAtIndex:0 animation:0];
        [controller queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
            XCTAssert(![koala.sections containsObject:obj]);
        }];
    }];
    
    // Backwards
    
    [controller addSections:randomSections animation:0];
    [randomSections enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [controller deleteSectionAtIndex:idx animation:0];
    }];
    [controller queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
        XCTAssert(koala.sections.count == 0);
    }];
    
    // Out of bounds
    
    [controller addSections:randomSections animation:0];
    [controller deleteSectionAtIndex:99 animation:0]; // Out of bounds
    [controller queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
        XCTAssert(koala.sections.count == randomSections.count);
    }];
    
    // Excessive range
    
    [controller deleteSectionsWithIndices:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, randomSections.count * 2)] animation:0];
    [controller queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
        XCTAssert(koala.sections.count == 0);
    }];
    
    // Delete middle range
    [controller addSections:randomSections animation:0];
    [controller deleteSectionsWithIndices:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(2, 2)] animation:0]; // Deleting 2, 3
    [controller queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
        XCTAssert([koala.sections[0] isEqual:randomSections[0]]);
        XCTAssert([koala.sections[1] isEqual:randomSections[1]]);
        XCTAssert(![koala.sections containsObject:randomSections[2]]);
        XCTAssert(![koala.sections containsObject:randomSections[3]]);
        XCTAssert([koala.sections[2] isEqual:randomSections[4]]);
    }];
    
    // Optimistic range
    
    [controller addSections:randomSections animation:0];
    [controller deleteSectionsWithIndices:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(2, 100)] animation:0]; // Out of bounds
    [controller queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
        XCTAssert([koala.sections[0] isEqual:randomSections[0]]);
        XCTAssert([koala.sections[1] isEqual:randomSections[1]]);
        XCTAssert(koala.sections.count == 2);
    }];
    [controller queueAction:^{
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:15 handler:nil];
}

#pragma mark Creating Sections

- (void)testInsertSectionWithName;
{
    XCTestExpectation *expectation = [self expectationWithDescription:nil];
    KCDObjectController *controller = [self objectController];
    NSArray *random1 = KCDRandomObjects([KCDAbstractObject class], 5);
    NSArray *random2 = KCDRandomObjects([KCDAbstractObject class], 5);
    NSArray *random3 = KCDRandomObjects([KCDAbstractObject class], 5);
    NSArray *random4 = KCDRandomObjects([KCDAbstractObject class], 5);
    NSArray *random5 = KCDRandomObjects([KCDAbstractObject class], 5);
    [controller insertSectionWithName:@"Three" objects:random3 atIndex:0 animation:0];
    [controller queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
        XCTAssert(koala.sections.count == 1);
        id<KCDSection>section0 = koala.sections[0];
        XCTAssert([section0.sectionName isEqualToString:@"Three"]);
        [random3 enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            XCTAssert(obj == section0.objects[idx]);
        }];
    }];
    [controller insertSectionWithName:@"One" objects:random1 atIndex:0 animation:0];
    [controller queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
        XCTAssert(koala.sections.count == 2);
        id<KCDSection>section0 = koala.sections[0];
        XCTAssert([section0.sectionName isEqualToString:@"One"]);
        id<KCDSection>section1 = koala.sections[1];
        XCTAssert([section1.sectionName isEqualToString:@"Three"]);
        [random1 enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            XCTAssert(obj == section0.objects[idx]);
        }];
        [random3 enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            XCTAssert(obj == section1.objects[idx]);
        }];
    }];
    [controller insertSectionWithName:@"Two" objects:random2 atIndex:1 animation:0];
    [controller queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
        XCTAssert(koala.sections.count == 3);
        id<KCDSection>section0 = koala.sections[0];
        XCTAssert([section0.sectionName isEqualToString:@"One"]);
        id<KCDSection>section1 = koala.sections[1];
        XCTAssert([section1.sectionName isEqualToString:@"Two"]);
        id<KCDSection>section2 = koala.sections[2];
        XCTAssert([section2.sectionName isEqualToString:@"Three"]);
        [random1 enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            XCTAssert(obj == section0.objects[idx]);
        }];
        [random2 enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            XCTAssert(obj == section1.objects[idx]);
        }];
        [random3 enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            XCTAssert(obj == section2.objects[idx]);
        }];
    }];
    [controller insertSectionWithName:@"Four" objects:random4 atIndex:3 animation:0];
    [controller queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
        XCTAssert(koala.sections.count == 4);
        id<KCDSection>section0 = koala.sections[0];
        XCTAssert([section0.sectionName isEqualToString:@"One"]);
        id<KCDSection>section1 = koala.sections[1];
        XCTAssert([section1.sectionName isEqualToString:@"Two"]);
        id<KCDSection>section2 = koala.sections[2];
        XCTAssert([section2.sectionName isEqualToString:@"Three"]);
        id<KCDSection>section3 = koala.sections[3];
        XCTAssert([section3.sectionName isEqualToString:@"Four"]);
    }];
    
    // Insert out of bounds.
    [controller insertSectionWithName:@"Five" objects:random5 atIndex:99 animation:0];
    [controller queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
        XCTAssert(koala.sections.count == 5);
        id<KCDSection>section0 = koala.sections[0];
        XCTAssert([section0.sectionName isEqualToString:@"One"]);
        id<KCDSection>section1 = koala.sections[1];
        XCTAssert([section1.sectionName isEqualToString:@"Two"]);
        id<KCDSection>section2 = koala.sections[2];
        XCTAssert([section2.sectionName isEqualToString:@"Three"]);
        id<KCDSection>section3 = koala.sections[3];
        XCTAssert([section3.sectionName isEqualToString:@"Four"]);
        id<KCDSection>section4 = koala.sections[4];
        XCTAssert([section4.sectionName isEqualToString:@"Five"]);
        [random5 enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            XCTAssert(obj == section4.objects[idx]);
        }];
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)testAddSectionWithName;
{
    XCTestExpectation *expectation = [self expectationWithDescription:nil];
    KCDObjectController *controller = [self objectController];
    NSArray *random1 = KCDRandomObjects([KCDAbstractObject class], 5);
    NSArray *random2 = KCDRandomObjects([KCDAbstractObject class], 5);
    [controller addSectionWithName:@"One" objects:random1 animation:0];
    [controller queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
        id<KCDSection>section0 = koala.sections[0];
        XCTAssert(koala.sections.count == 1);
        XCTAssert([section0.sectionName isEqualToString:@"One"]);
        [random1 enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            XCTAssert(obj == section0.objects[idx]);
        }];
    }];
    [controller addSectionWithName:@"Two" objects:random2 animation:0];
    [controller queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
        id<KCDSection>section0 = koala.sections[0];
        id<KCDSection>section1 = koala.sections[1];
        XCTAssert(koala.sections.count == 2);
        XCTAssert([section0.sectionName isEqualToString:@"One"]);
        XCTAssert([section1.sectionName isEqualToString:@"Two"]);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5 handler:nil];
}

#pragma mark Moving Sections

- (void)testMoveSectionToIndex;
{
    XCTestExpectation *expectation = [self expectationWithDescription:nil];
    KCDObjectController *controller = [self objectController];
    NSArray *randomSections = KCDRandomSections([KCDAbstractObject class], 5, 0);
    [controller addSections:randomSections animation:0];
    [controller moveSection:randomSections[0] toIndex:4];
    [controller queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
        XCTAssert([koala.sections[4] isEqual:randomSections[0]]);
        XCTAssert([koala.sections[0] isEqual:randomSections[1]]);
    }];
    [controller moveSection:randomSections[4] toIndex:0];
    [controller queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
        XCTAssert([koala.sections[0] isEqual:randomSections[4]]);
        XCTAssert([koala.sections[1] isEqual:randomSections[1]]);
    }];
    [randomSections enumerateObjectsWithOptions:NSEnumerationReverse
                                     usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [controller moveSection:obj toIndex:0];
        [controller queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
            XCTAssert([koala.sections[0] isEqual:obj]);
        }];
    }];
    [randomSections enumerateObjectsWithOptions:NSEnumerationReverse
                                     usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                                         [controller queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
                                             XCTAssert([koala.sections[idx] isEqual:obj]);
                                         }];
                                     }];
    [controller queueAction:^{
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5 handler:nil];
}

- (void)testMoveSectionAtIndexToIndex;
{
    XCTestExpectation *expectation = [self expectationWithDescription:nil];
    KCDObjectController *controller = [self objectController];
    NSArray *randomSections = KCDRandomSections([KCDAbstractObject class], 5, 0);
    [controller addSections:randomSections animation:0];
    [controller moveSectionAtIndex:0 toIndex:4];
    [controller queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
        XCTAssert([koala.sections[4] isEqual:randomSections[0]]);
        XCTAssert([koala.sections[0] isEqual:randomSections[1]]);
    }];
    [controller moveSectionAtIndex:4 toIndex:0];
    [controller queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
        XCTAssert([koala.sections[0] isEqual:randomSections[0]]);
        XCTAssert([koala.sections[1] isEqual:randomSections[1]]);
    }];
    [randomSections enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [controller queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
            XCTAssert([koala.sections[idx] isEqual:obj]);
        }];
    }];
    [randomSections enumerateObjectsWithOptions:NSEnumerationReverse
                                     usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                                         __block id<KCDSection>section = nil;
                                         [controller queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
                                             section = koala.sections[idx];
                                         }];
                                         [controller moveSectionAtIndex:idx toIndex:0];
                                         [controller queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
                                             XCTAssert([section isEqual:koala.sections[0]]);
                                         }];
                                     }];
    [controller queueAction:^{
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5 handler:nil];
}

- (void)testMoveSectionsToIndices;
{
    XCTestExpectation *expectation = [self expectationWithDescription:nil];
    KCDObjectController *controller = [self objectController];
    NSArray *randomSections = KCDRandomSections([KCDAbstractObject class], 5, 0);
    [controller addSections:randomSections animation:0];
    NSMutableArray *indices = [NSMutableArray new];
    for (NSInteger x = 0; x < randomSections.count; x++)
    {
        [indices addObject:@(x)];
    }
    NSArray *reversedIndices = [indices.reverseObjectEnumerator allObjects];
    [controller moveSections:randomSections toIndices:reversedIndices];
    NSArray *reversedSections = [randomSections.reverseObjectEnumerator allObjects];
    [reversedIndices enumerateObjectsUsingBlock:^(NSNumber *anIndex, NSUInteger idx, BOOL *stop) {
        [controller queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
            XCTAssert([[koala sectionAtIndex:anIndex.integerValue] isEqual:reversedSections[anIndex.integerValue]]);
        }];
    }];
    
    [controller queueAction:^{
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5 handler:nil];
}

- (void)testMoveSectionsAtIndicesToIndices;
{
    XCTestExpectation *expectation = [self expectationWithDescription:nil];
    KCDObjectController *controller = [self objectController];
    NSArray *randomSections = KCDRandomSections([KCDAbstractObject class], 5, 0);
    [controller addSections:randomSections animation:0];
    NSMutableArray *indices = [NSMutableArray new];
    for (NSInteger x = 0; x < randomSections.count; x++)
    {
        [indices addObject:@(x)];
    }
    NSArray *reversedIndices = [indices.reverseObjectEnumerator allObjects];
    [controller moveSectionsAtIndices:indices toIndices:reversedIndices];
    NSArray *reversedSections = [randomSections.reverseObjectEnumerator allObjects];
    [reversedIndices enumerateObjectsUsingBlock:^(NSNumber *anIndex, NSUInteger idx, BOOL *stop) {
        [controller queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
            XCTAssert([[koala sectionAtIndex:anIndex.integerValue] isEqual:reversedSections[anIndex.integerValue]]);
        }];
    }];
    
    [controller queueAction:^{
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5 handler:nil];
}

#pragma mark Sorting Sections


- (void)testSectionSortingWithDescriptors;
{
    XCTestExpectation *expectation = [self expectationWithDescription:nil];
    KCDObjectController *controller = [self objectController];
    NSArray *randomSections = KCDRandomSections([KCDAbstractObject class], 5, 0);
    [controller addSections:randomSections animation:0];
    NSMutableArray *sortedSections = [randomSections mutableCopy];
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"sectionName" ascending:YES];
    [sortedSections sortUsingDescriptors:@[sort]];
    [controller sortSectionsUsingDescriptors:@[sort]];
    [controller queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
        [koala.sections enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            XCTAssert([obj isEqual:sortedSections[idx]]);
        }];
    }];
    [controller queueAction:^{
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5 handler:nil];
}

- (void)testSectionSortingWithComparator;
{
    XCTestExpectation *expectation = [self expectationWithDescription:nil];
    KCDObjectController *controller = [self objectController];
    NSArray *randomSections = KCDRandomSections([KCDAbstractObject class], 5, 0);
    NSMutableArray *sortedSections = [randomSections mutableCopy];
    [sortedSections sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [[obj1 sectionName] localizedCaseInsensitiveCompare:[obj2 sectionName]];
    }];
    [controller sortSectionsWithComparator:^NSComparisonResult(id obj1, id obj2) {
        return [[obj1 sectionName] localizedCaseInsensitiveCompare:[obj2 sectionName]];
    }];
    [controller queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
        [koala.sections enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            XCTAssert([obj isEqual:sortedSections[idx]]);
        }];
    }];
    [controller queueAction:^{
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5 handler:nil];
}

#pragma mark - Objects

#pragma mark Adding Objects

- (void)testAddObjectsToSection;
{
    XCTestExpectation *expectation = [self expectationWithDescription:nil];
    KCDObjectController *controller = [self objectController];
    NSArray *randomSections = KCDRandomSections([KCDAbstractObject class], 5, 0);
    [controller addSections:randomSections animation:0];
    NSArray *randomObjects = KCDRandomObjects([KCDAbstractObject class], randomSections.count);
    [randomSections enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [controller addObjects:@[randomObjects[idx]] toSection:obj animation:0];
        [controller queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
            id<KCDSection> section = koala.sections[idx];
            XCTAssert([section isEqual:obj]);
            XCTAssert([section.objects.lastObject isEqual:randomObjects[idx]]);
        }];
    }];
    [controller queueAction:^{
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5 handler:nil];
}

- (void)testInsertObjectsAtIndexPaths;
{
    XCTestExpectation *expectation = [self expectationWithDescription:nil];
    KCDObjectController *controller = [self objectController];
    NSArray *randomObjects = KCDRandomObjects([KCDAbstractObject class], 5);
    NSArray *randomSections = KCDRandomSections([KCDAbstractObject class], randomObjects.count, 0);
    NSMutableArray *indexPaths = [NSMutableArray new];
    [randomObjects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSIndexPath *aPath = [NSIndexPath indexPathForRow:0 inSection:idx];
        [indexPaths addObject:aPath];
    }];
    [controller insertObjects:randomObjects atIndexPaths:indexPaths animation:0];
    [controller queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
        XCTAssert(koala.sections.count == 0);
    }];
    [controller addSections:randomSections animation:0];
    [controller insertObjects:randomObjects atIndexPaths:indexPaths animation:0];
    [indexPaths enumerateObjectsUsingBlock:^(NSIndexPath *aPath, NSUInteger idx, BOOL *stop) {
        [controller queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
            id<KCDSection> sectionAtIndex = [koala sectionAtIndex:aPath.section];
            XCTAssert(sectionAtIndex);
            id<KCDObject> objectAtIndex = [sectionAtIndex objectAtIndex:0];
            XCTAssert(objectAtIndex);
            XCTAssert(objectAtIndex == randomObjects[idx]);
            id<KCDObject> objectAtPath = [koala objectAtIndexPath:aPath];
            XCTAssert(objectAtPath == randomObjects[idx]);
        }];
    }];
    [controller deleteAllSections:0];
    [controller addSections:randomSections animation:0];
    NSMutableDictionary *objPathMap = [NSMutableDictionary new];
    [randomObjects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if (arc4random() % 2 == 0) {
            objPathMap[[NSIndexPath indexPathForRow:0 inSection:idx]] = obj;
        }
    }];
    [controller insertObjects:objPathMap.allValues atIndexPaths:objPathMap.allKeys animation:0];
    [objPathMap enumerateKeysAndObjectsUsingBlock:^(NSIndexPath<KCDIntrospective>*aPath, id<KCDObject> obj, BOOL *stop) {
        [controller queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
            id<KCDObject>objAtPath = [koala objectAtIndexPath:aPath];
            XCTAssert(objAtPath == obj);
        }];
    }];
    
    // Try incorrect bounds
    
    void (^testMatch)(NSArray *, NSArray *) =
    ^(NSArray *indexPaths, NSArray *objects) {
        for (NSInteger x = 0; x < MIN(indexPaths.count, objects.count); x++)
        {
            NSIndexPath *aPath = indexPaths[x];
            id<KCDObject> anObject = objects[x];
            [controller queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
                id<KCDObject> objectAtPath = [koala objectAtIndexPath:aPath];
                XCTAssertTrue(objectAtPath == anObject, @"%@ != %@", [koala objectAtIndexPath:aPath], anObject);
            }];
        }
    };
    
    NSMutableArray *mismatchObjects = [randomObjects mutableCopy];
    NSMutableArray *mismatchPaths = [indexPaths mutableCopy];
    XCTAssert(mismatchObjects.count == mismatchPaths.count);
    
    // Remove a random path; now there are -1 paths to objects.
    [mismatchPaths removeObjectAtIndex:arc4random() % mismatchPaths.count];
    [controller deleteAllSections:0];
    [controller addSections:randomSections animation:0];
    [controller queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
        XCTAssert(koala.sections.count == randomSections.count);
    }];
    [controller insertObjects:mismatchObjects atIndexPaths:mismatchPaths animation:0];
    
    testMatch(mismatchPaths, mismatchObjects);
    
    // Now bring the objects down to -2 of the paths
    
    mismatchObjects = [mismatchObjects mutableCopy];
    mismatchPaths = [mismatchPaths mutableCopy];
    
    [mismatchObjects removeObjectAtIndex:arc4random() % mismatchObjects.count];
    [mismatchObjects removeObjectAtIndex:arc4random() % mismatchObjects.count];
    [controller deleteAllSections:0];
    [controller addSections:randomSections animation:0];
    [controller insertObjects:mismatchObjects atIndexPaths:mismatchPaths animation:0];

    testMatch(mismatchPaths, mismatchObjects);
    
    [controller queueAction:^{
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5 handler:nil];
}

- (void)testAddObjectsToSectionAtIndex;
{
    XCTestExpectation *expectation = [self expectationWithDescription:nil];
    KCDObjectController *controller = [self objectController];
    NSArray *randomSections = KCDRandomSections([KCDAbstractObject class], 5, 0);
    [controller addSections:randomSections animation:0];
    NSArray *randomObjects = KCDRandomObjects([KCDAbstractObject class], randomSections.count);
    [randomObjects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [controller queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
            id<KCDSection> section = [koala sectionAtIndex:idx];
            XCTAssert(![[section objects] containsObject:obj]);
        }];
        [controller addObjects:@[obj] toSectionAtIndex:idx animation:0];
        if (idx < randomSections.count) {
            [controller queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
                id<KCDSection> section = [koala sectionAtIndex:idx];
                XCTAssert(section);
                XCTAssert(section.objects);
                XCTAssert([[section objects] containsObject:obj]);
                XCTAssert(section.objects.lastObject == obj);
            }];
        }
    }];
    [controller queueAction:^{
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5 handler:nil];
}

#pragma mark Moving Objects

- (void)testMoveObjectsAtIndexPathsToIndexPaths;
{
    // TODO: Add out of bounds move
    XCTestExpectation *expectation = [self expectationWithDescription:nil];
    KCDObjectController *controller = [self objectController];
    NSArray *randomSections = KCDRandomSections([KCDAbstractObject class], 5, 0);
    [controller addSections:randomSections animation:0];
    NSMutableArray *objects = [NSMutableArray new];
    NSMutableArray *paths = [NSMutableArray new];
    [randomSections enumerateObjectsUsingBlock:^(id<KCDSection> aSection, NSUInteger s, BOOL *stop) {
        [aSection.objects enumerateObjectsUsingBlock:^(id obj, NSUInteger r, BOOL *stop) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:r inSection:s];
            [objects addObject:obj];
            [paths addObject:indexPath];
            [controller queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
                XCTAssert([koala objectAtIndexPath:indexPath] == obj);
            }];
        }];
    }];
    NSArray *reversedPaths = [[paths reverseObjectEnumerator] allObjects];
    [controller moveObjectsAtIndexPaths:paths toIndexPaths:reversedPaths];
    [objects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSIndexPath *path = reversedPaths[idx];
        [controller queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
            XCTAssert([koala objectAtIndexPath:path] == obj);
        }];
    }];
    [controller queueAction:^{
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5 handler:nil];
}

- (void)testMoveObjectsToIndexPaths;
{
    XCTestExpectation *expectation = [self expectationWithDescription:nil];
    KCDObjectController *controller = [self objectController];
    NSArray *randomSections = KCDRandomSections([KCDAbstractObject class], 5, 0);
    [controller addSections:randomSections animation:0];
    NSMutableArray *objects = [NSMutableArray new];
    NSMutableArray *paths = [NSMutableArray new];
    [randomSections enumerateObjectsUsingBlock:^(id<KCDSection> aSection, NSUInteger s, BOOL *stop) {
        [aSection.objects enumerateObjectsUsingBlock:^(id obj, NSUInteger r, BOOL *stop) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:r inSection:s];
            [objects addObject:obj];
            [paths addObject:indexPath];
            [controller queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
                XCTAssert([koala objectAtIndexPath:indexPath] == obj);
            }];
        }];
    }];
    NSArray *reversePaths = [[paths reverseObjectEnumerator] allObjects];
    [controller moveObjects:objects toIndexPaths:reversePaths];
    [reversePaths enumerateObjectsUsingBlock:^(NSIndexPath *aPath, NSUInteger idx, BOOL *stop) {
        [controller queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
            XCTAssert([koala objectAtIndexPath:aPath] == objects[idx]);
        }];
    }];
    [controller moveObjects:objects toIndexPaths:paths];
    [paths enumerateObjectsUsingBlock:^(NSIndexPath *aPath, NSUInteger idx, BOOL *stop) {
        [controller queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
            XCTAssert([koala objectAtIndexPath:aPath] == objects[idx]);
        }];
    }];
    [objects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSIndexPath *targetPath = reversePaths[idx];
        [controller moveObject:obj toIndexPath:targetPath];
        [controller queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
            // Paths will be normalized.
            XCTAssert([[[koala sectionAtIndex:targetPath.section] objects] containsObject:obj]);
        }];
    }];
    [controller queueAction:^{
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5 handler:nil];
}

#pragma mark Deleting Objects

- (void)testDeleteObjectsByReference;
{
    XCTestExpectation *expectation = [self expectationWithDescription:nil];
    KCDObjectController *controller = [self objectController];
    NSArray *randomSections = KCDRandomSections([KCDAbstractObject class], 5, 0);
    [controller addSections:randomSections animation:0];
    [controller queueTransaction:^(KCDObjectController *koala) {
        [[randomSections valueForKeyPath:@"objects"]
         enumerateObjectsUsingBlock:^(NSOrderedSet *sectionObjects, NSUInteger s, BOOL *stop) {
            [sectionObjects enumerateObjectsUsingBlock:^(id obj, NSUInteger r, BOOL *stop) {
                __block NSInteger objectCount = 0;
                [controller queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
                    objectCount = [[[koala sectionAtIndex:s] objects] count];
                }];
                [controller deleteObject:obj animation:0];
                [controller queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
                    id<KCDSection> affectedSection = [koala sectionAtIndex:s];
                    XCTAssert(![affectedSection.objects containsObject:obj]);
                    XCTAssert([affectedSection.objects count] == objectCount-1);
                }];
            }];
        }];
        [controller queueAction:^{
            [expectation fulfill];
        }];
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
}

- (void)testDeleteObjectsAtIndexPaths;
{
    XCTestExpectation *expectation = [self expectationWithDescription:nil];
    KCDObjectController *controller = [self objectController];
    NSArray *randomSections = KCDRandomSections([KCDAbstractObject class], 5, 0);
    [controller addSections:randomSections animation:0];

    
    void (^deleteObjects)() = nil;
    __block void (^strongDelete)() __strong = nil;
    deleteObjects = ^{
        [controller queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
            NSArray *allObjects = [koala allObjects];
            NSMutableSet *objectsToDelete = [NSMutableSet new];
            for (NSInteger x = 0; x < arc4random() % allObjects.count+1; x++)
            {
                NSInteger index = (allObjects.count > 5) ? arc4random() % allObjects.count : x;
                id<KCDObject> aRandomObject = [allObjects objectAtIndex:index];
                [objectsToDelete addObject:aRandomObject];
            }
            NSMutableArray *indexPathsToDelete = [NSMutableArray new];
            [objectsToDelete enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
                NSIndexPath *aPath = [koala indexPathForObject:obj];
                [indexPathsToDelete addObject:aPath];
                XCTAssert([koala objectAtIndexPath:aPath] == obj);
            }];
            [koala deleteObjectsAtIndexPaths:indexPathsToDelete animation:0];
            [koala queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
                [objectsToDelete enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
                    XCTAssert(![koala.allObjects containsObject:obj]);
                }];
                if (koala.allObjects.count == 0) {
                    strongDelete = nil;
                    [expectation fulfill];
                }
                else {
                    strongDelete();
                }
            }];
        }];
    };
    
    strongDelete = deleteObjects;
    strongDelete();

    [self waitForExpectationsWithTimeout:30 handler:nil];
}

#pragma mark Sorting Sections

- (void)testSortingSectionsWithComparator;
{
    XCTestExpectation *expectation = [self expectationWithDescription:nil];
    KCDObjectController *controller = [self objectController];
    NSArray *randomSections = KCDRandomSections([KCDAbstractObject class], 5, 0);
    [controller addSections:randomSections animation:0];
    NSComparator comp = ^NSComparisonResult(id<KCDSection> obj1, id<KCDSection> obj2) {
        return [obj1.sectionName localizedCaseInsensitiveCompare:obj2.sectionName];
    };
    NSMutableArray *sortedSections = [randomSections mutableCopy];
    [sortedSections sortUsingComparator:comp];
    [controller sortSectionsWithComparator:comp];
    [controller queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
        [koala.sections enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            XCTAssert([obj isEqual:sortedSections[idx]]);
        }];
    }];
    [controller queueAction:^{
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5 handler:nil];
}

- (void)testSortingSectionWithDescriptors;
{
    XCTestExpectation *expectation = [self expectationWithDescription:nil];
    KCDObjectController *controller = [self objectController];
    NSArray *randomSections = KCDRandomSections([KCDAbstractObject class], 5, 0);
    [controller addSections:randomSections animation:0];
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"sectionName" ascending:YES];
    NSMutableArray *sortedSections = [randomSections mutableCopy];
    [sortedSections sortUsingDescriptors:@[sort]];
    [controller sortSectionsUsingDescriptors:@[sort]];
    [controller queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
        [koala.sections enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            XCTAssert([obj isEqual:sortedSections[idx]]);
        }];
    }];
    [controller queueAction:^{
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5 handler:nil];
}

#pragma mark Filtering Sections

- (void)testFilteringSectionAtIndex;
{
    XCTestExpectation *expectation = [self expectationWithDescription:nil];
    KCDObjectController *controller = [self objectController];
    NSArray *randomSections = KCDRandomSections([KCDAbstractObject class], 5, 0);
    [controller addSections:randomSections animation:0];
    __block NSInteger minLength = NSIntegerMax;
    __block NSInteger maxLength = 0;
    [randomSections enumerateObjectsUsingBlock:^(id<KCDSection>aSection, NSUInteger idx, BOOL *stop) {
        [aSection.objects enumerateObjectsUsingBlock:^(KCDAbstractObject * anObject, NSUInteger idx, BOOL *stop) {
            NSInteger titleLength = anObject.title.length;
            if (titleLength < minLength) {
                minLength = titleLength;
            }
            if (titleLength > maxLength) {
                maxLength = titleLength;
            }
        }];
    }];
    NSInteger difference = arc4random() % (maxLength-minLength);
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(KCDAbstractObject * anObject, NSDictionary *bindings) {
        return (anObject.title.length < minLength+difference);
    }];
    [[randomSections valueForKeyPath:@"objects"] enumerateObjectsUsingBlock:^(NSOrderedSet *sectionObjects, NSUInteger idx, BOOL *stop) {
        NSMutableOrderedSet *filteredObjects = [sectionObjects mutableCopy];
        [filteredObjects filterUsingPredicate:predicate];
        [controller filterSectionAtIndex:idx predicate:predicate animation:0];
        [controller queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
            id<KCDSection> filteredSection = [koala sectionAtIndex:idx];
            [filteredSection.objects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                XCTAssert(obj == filteredObjects[idx]);
            }];
        }];
    }];
    [controller queueAction:^{
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5 handler:nil];
}

- (void)testFilteringAllSections;
{
    XCTestExpectation *expectation = [self expectationWithDescription:nil];
    KCDObjectController *controller = [self objectController];
    NSArray *randomSections = KCDRandomSections([KCDAbstractObject class], 5, 0);
    [controller addSections:randomSections animation:0];
    __block NSInteger minLength = NSIntegerMax;
    __block NSInteger maxLength = 0;
    [randomSections enumerateObjectsUsingBlock:^(id<KCDSection>aSection, NSUInteger idx, BOOL *stop) {
        [aSection.objects enumerateObjectsUsingBlock:^(KCDAbstractObject * anObject, NSUInteger idx, BOOL *stop) {
            NSInteger titleLength = anObject.title.length;
            if (titleLength < minLength) {
                minLength = titleLength;
            }
            if (titleLength > maxLength) {
                maxLength = titleLength;
            }
        }];
    }];
    NSInteger difference = arc4random() % (maxLength-minLength);
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(KCDAbstractObject * anObject, NSDictionary *bindings) {
        return (anObject.title.length < minLength+difference);
    }];
    [controller filterWithPredicate:predicate animation:0];
    [controller queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
        [[randomSections valueForKeyPath:@"objects"] enumerateObjectsUsingBlock:^(NSOrderedSet *sectionObjects, NSUInteger idx, BOOL *stop) {
            NSMutableOrderedSet *filteredObjects = [sectionObjects mutableCopy];
            [filteredObjects filterUsingPredicate:predicate];
            id<KCDSection> filteredSection = [koala sectionAtIndex:idx];
            [filteredSection.objects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                XCTAssert(obj == filteredObjects[idx]);
            }];
        }];
    }];
    [controller queueAction:^{
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5 handler:nil];
}

#pragma mark - Introspection

- (void)testEnumeration;
{
    XCTestExpectation *expectation = [self expectationWithDescription:nil];
    KCDObjectController *controller = [self objectController];
    NSArray *randomSections = KCDRandomSections([KCDAbstractObject class], 10, 0);
    [controller addSections:randomSections animation:0];
    [controller queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
        NSMutableArray *objects = [NSMutableArray new];
        NSMutableArray *paths = [NSMutableArray new];
        [[randomSections valueForKeyPath:@"objects"] enumerateObjectsUsingBlock:^(NSOrderedSet *sectionObjects, NSUInteger s, BOOL *stop) {
            [sectionObjects enumerateObjectsUsingBlock:^(id obj, NSUInteger r, BOOL *stop) {
                [paths addObject:[NSIndexPath indexPathForRow:r inSection:s]];
                [objects addObject:obj];
            }];
        }];
        __block NSInteger index = 0;
        [koala enumerateObjectsUsingBlock:^(id<KCDObject> object, id<KCDSection> section, NSIndexPath*(^indexPath)(), BOOL *stop) {
            id<KCDObject> refObject = objects[index];
            NSIndexPath *refPath = paths[index];
            XCTAssert(object == refObject);
            XCTAssert([indexPath() isEqual:refPath]);
            index++;
        }];
    }];
    [controller queueAction:^{
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5 handler:nil];
}

- (void)testContainsObject;
{
    XCTestExpectation *expectation = [self expectationWithDescription:nil];
    KCDObjectController *controller = [self objectController];
    NSArray *randomSections = KCDRandomSections([KCDAbstractObject class], 100, 0);
    [controller addSections:randomSections animation:0];
    [controller queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
        [self measureBlock:^{
            [[randomSections valueForKeyPath:@"objects"] enumerateObjectsUsingBlock:^(NSOrderedSet *sectionObjects, NSUInteger idx, BOOL *stop) {
                [sectionObjects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    XCTAssert([koala containsObject:obj]);
                }];
            }];
        }];
    }];
    [controller queueAction:^{
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:15 handler:nil];
}

- (void)testSectionForIndex;
{
    XCTestExpectation *expectation = [self expectationWithDescription:nil];
    KCDObjectController *controller = [self objectController];
    NSArray *randomSections = KCDRandomSections([KCDAbstractObject class], 10, 0);
    [controller addSections:randomSections animation:0];
    [controller queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
        [randomSections enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            XCTAssert([obj isEqual:[koala sectionAtIndex:idx]]);
        }];
    }];
    [controller queueAction:^{
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5 handler:nil];
}

- (void)testIndexForSection;
{
    XCTestExpectation *expectation = [self expectationWithDescription:nil];
    KCDObjectController *controller = [self objectController];
    NSArray *randomSections = KCDRandomSections([KCDAbstractObject class], 10, 0);
    [controller addSections:randomSections animation:0];
    [controller queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
        [randomSections enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            XCTAssert(idx == [koala indexForSection:obj]);
        }];
    }];
    [controller queueAction:^{
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5 handler:nil];
}

- (void)testIndexPathsForObjects;
{
    XCTestExpectation *expectation = [self expectationWithDescription:nil];
    KCDObjectController *controller = [self objectController];
    NSArray *randomSections = KCDRandomSections([KCDAbstractObject class], 10, 10); // 10, 10
    [controller addSections:randomSections animation:0];
    [controller queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
        NSMutableArray *objects = [NSMutableArray new];
        NSMutableArray *paths = [NSMutableArray new];
        [[randomSections valueForKeyPath:@"objects"] enumerateObjectsUsingBlock:^(NSOrderedSet *sectionObjects, NSUInteger s, BOOL *stop) {
            [sectionObjects enumerateObjectsUsingBlock:^(id obj, NSUInteger r, BOOL *stop) {
                if (s + r % 2 == 0) {
                    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:r inSection:s];
                    [objects addObject:obj];
                    [paths addObject:indexPath];
                    [koala queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
                        XCTAssert([koala objectAtIndexPath:indexPath] == obj);
                    }];
                }
            }];
        }];
        NSArray *indexPaths = [koala indexPathsForObjects:objects];
        [indexPaths enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSInteger index = [paths indexOfObject:obj];
            id<KCDObject> expectedObject = [objects objectAtIndex:index];
            XCTAssert([koala objectAtIndexPath:obj] == expectedObject);
        }];
    }];
    [controller queueAction:^{
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
}

- (void)testMeasureIndexPathsForObjects;
{
    
    XCTestExpectation *expectation = [self expectationWithDescription:nil];
    NSInteger sectionCount = 100;
    NSInteger objectCount = 100;
    KCDObjectController *controller = [self objectController];
    NSMutableArray *sections = [NSMutableArray new];
    for (NSInteger s = 0; s < sectionCount; s++) {
        NSArray *randomObjects = KCDRandomObjects([KCDAbstractObject class], objectCount);
        id<KCDSection> aSection = [controller newSectionWithName:[@(s) stringValue] objects:[randomObjects subarrayWithRange:NSMakeRange(0, objectCount)]];
        [sections addObject:aSection];
    }
    [controller addSections:sections animation:0];
    [controller queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
        [self measureBlock:^{
            [koala indexPathsForObjects:koala.allObjects];
        }];
    }];
    [controller queueAction:^{
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:120 handler:nil];
}

- (void)testObjectsForIndexPaths;
{
    XCTestExpectation *expectation = [self expectationWithDescription:nil];
    NSInteger sectionCount = 100;
    NSInteger objectCount = 100;
    KCDObjectController *controller = [self objectController];
    NSMutableArray *sections = [NSMutableArray new];
    for (NSInteger s = 0; s < sectionCount; s++) {
        NSArray *randomObjects = KCDRandomObjects([KCDAbstractObject class], objectCount);
        id<KCDSection> aSection = [controller newSectionWithName:[@(s) stringValue] objects:[randomObjects subarrayWithRange:NSMakeRange(0, objectCount)]];
        [sections addObject:aSection];
    }
    [controller addSections:sections animation:0];
    [controller queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
        NSArray *indexPaths = [koala indexPathsForObjects:koala.allObjects];
        __block NSArray *objects = nil;
        [self measureBlock:^{
            objects = [koala objectsForIndexPaths:indexPaths];
        }];
        XCTAssertTrue(objects.count == indexPaths.count,
                      @"%@ objects; %@ index paths",
                      @(objects.count),
                      @(indexPaths.count));
        for (NSInteger x = 0; x < indexPaths.count; x++)
        {
            id<KCDObject> obj = objects[x];
            NSIndexPath *path = indexPaths[x];
            XCTAssert([koala objectAtIndexPath:path] == obj);
        }

    }];
    [controller queueAction:^{
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:120 handler:nil];
}

- (void)testAllObjects;
{
    XCTestExpectation *expectation = [self expectationWithDescription:nil];
    KCDObjectController *controller = [self objectController];
    NSArray *randomSections = KCDRandomSections([KCDAbstractObject class], 100, 100); // 10, 10
    [controller addSections:randomSections animation:0];
    [controller queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
        [self measureBlock:^{
            [koala allObjects];
        }];
    }];
    [controller queueAction:^{
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
}

- (void)testObjectForIndexPaths;
{
    XCTestExpectation *expectation = [self expectationWithDescription:nil];
    KCDObjectController *controller = [self objectController];
    NSArray *randomSections = KCDRandomSections([KCDAbstractObject class], 10, 0);
    [controller addSections:randomSections animation:0];
    [controller queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
        [randomSections enumerateObjectsUsingBlock:^(id<KCDSection> aSection, NSUInteger s, BOOL *stop) {
            [aSection.objects enumerateObjectsUsingBlock:^(id obj, NSUInteger r, BOOL *stop) {
                XCTAssert([koala objectAtIndexPath:[NSIndexPath indexPathForRow:r inSection:s]] == obj);
            }];
        }];
    }];
    [controller queueAction:^{
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5 handler:nil];
}


#pragma mark Factory

- (void)testSectionCreation;
{
    XCTestExpectation *expectation = [self expectationWithDescription:nil];
    KCDObjectController *controller = [self objectController];
    NSArray *randomObjects1 = KCDRandomObjects([KCDAbstractObject class], 0);
    NSArray *randomObjects2 = KCDRandomObjects([KCDAbstractObject class], 0);
    NSArray *randomObjects3 = KCDRandomObjects([KCDAbstractObject class], 0);
    NSArray *randomObjects4 = KCDRandomObjects([KCDAbstractObject class], 0);
    [controller insertSectionWithName:@"Section One" objects:randomObjects1 atIndex:0 animation:0];
    [controller queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
        XCTAssert([[[koala sectionAtIndex:0] sectionName] isEqualToString:@"Section One"]);
        [[[koala sectionAtIndex:0] objects] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            XCTAssert(obj == randomObjects1[idx]);
        }];
    }];
    [controller insertSectionWithName:@"Section Two" objects:randomObjects2 atIndex:0 animation:0];
    [controller queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
        XCTAssert([[[koala sectionAtIndex:0] sectionName] isEqualToString:@"Section Two"]);
        [[[koala sectionAtIndex:0] objects] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            XCTAssert(obj == randomObjects2[idx]);
        }];
    }];
    // Out of bounds insertion
    [controller insertSectionWithName:@"Section Three" objects:randomObjects3 atIndex:99 animation:0];
    [controller queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
        XCTAssert([[[koala sectionAtIndex:2] sectionName] isEqualToString:@"Section Three"]);
        [[[koala sectionAtIndex:2] objects] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            XCTAssert(obj == randomObjects3[idx]);
        }];
    }];
    // Adding section
    [controller addSectionWithName:@"Section Four" objects:randomObjects4 animation:0];
    [controller queueTransaction:^(KCDObjectController<KCDIntrospective>*koala) {
        XCTAssert([[[koala sectionAtIndex:3] sectionName] isEqualToString:@"Section Four"]);
        [[[koala sectionAtIndex:3] objects] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            XCTAssert(obj == randomObjects4[idx]);
        }];
    }];
    [controller queueAction:^{
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5 handler:nil];
}

@end

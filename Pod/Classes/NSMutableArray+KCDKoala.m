//
//  NSMutableArray+KCDUtilities.m
//  KCDKoalaMobile
//
//  Created by Nicholas Zeltzer on 11/10/14.
//  Copyright (c) 2014 LawBox LLC. All rights reserved.
//

#import "NSMutableArray+KCDKoala.h"

@implementation NSMutableArray (KCDKoala)

- (void)KCDMoveObjectAtIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex;
{
    [self KCDMoveObjectsAtIndices:@[@(fromIndex)] toIndices:@[@(toIndex)]];
}

- (void)KCDMoveObjectsAtIndices:(NSArray *)fromIndices toIndices:(NSArray *)toIndices;
{

    NSAssert(fromIndices.count == toIndices.count,
             @"Index set mismatch: %@ from; %@ to",
             @(toIndices.count),
             @(toIndices.count));
    
    NSAssert(fromIndices.count <= self.count, @"Number of indices exceed bounds");
    if (fromIndices.count == toIndices.count && fromIndices.count <= self.count) {
        NSInteger count = fromIndices.count;
        for (NSInteger x = 0; x < count; x++)
        {
            NSInteger fIndex = [fromIndices[x] integerValue];
            NSInteger tIndex = [toIndices[x] integerValue];
            id objectToMove = [self objectAtIndex:fIndex];
            [self removeObjectAtIndex:fIndex];
            [self insertObject:objectToMove atIndex:tIndex];
        }
    }
}

@end

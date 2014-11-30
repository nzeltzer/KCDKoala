//
//  NSMutableArray+KCDUtilities.h
//  KCDKoalaMobile
//
//  Created by Nicholas Zeltzer on 11/10/14.
//  Copyright (c) 2014 LawBox LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableArray (KCDKoala)

- (void)KCDMoveObjectAtIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex;
- (void)KCDMoveObjectsAtIndices:(NSArray *)fromIndices toIndices:(NSArray *)toIndices;

@end

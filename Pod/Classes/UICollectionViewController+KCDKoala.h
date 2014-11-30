//
//  UICollectionViewController+KCDKoala.h
//  KCDKoalaMobile
//
//  Created by Nicholas Zeltzer on 11/11/14.
//  Copyright (c) 2014 LawBox LLC. All rights reserved.
//

@import UIKit;

#import "KCDCollectionViewDataSourceDelegate.h"

@class KCDCollectionViewDataSource;

@interface UICollectionViewController (KCDKoala) <KCDCollectionViewDataSourceDelegate>

@property (readonly) KCDCollectionViewDataSource *KCDDataSource;

- (instancetype)initWithLayout:(UICollectionViewLayout *)layout
                      sections:(NSArray *)KCDSections;

- (instancetype)initWithLayout:(UICollectionViewLayout *)layout
                       objects:(NSArray *)KCDObjects;

@end

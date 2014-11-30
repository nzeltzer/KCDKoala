//
//  UICollectionViewController+KCDKoala.m
//  KCDKoalaMobile
//
//  Created by Nicholas Zeltzer on 11/11/14.
//  Copyright (c) 2014 LawBox LLC. All rights reserved.
//

#import "UICollectionViewController+KCDKoala.h"
#import "UIViewController+KCDKoala.h"
#import "KCDCollectionViewDataSource.h"

@implementation UICollectionViewController (KCDKoala) 

@dynamic KCDDataSource;

- (instancetype)initWithLayout:(UICollectionViewLayout *)layout
                      sections:(NSArray *)KCDSections;
{
    self = [self initWithCollectionViewLayout:layout];
    if (self) {
        KCDCollectionViewDataSource *datasource = [[KCDCollectionViewDataSource alloc]
                                                   initWithDelegate:self
                                                   sections:KCDSections];
        [self setKCDObjectController:datasource];
        [datasource setCollectionView:self.collectionView];
        NSAssert([NSThread isMainThread], @"Attempt to initialize off of main thread");
    }
    return self;
}

- (instancetype)initWithLayout:(UICollectionViewLayout *)layout
                       objects:(NSArray *)KCDObjects;
{
    self = [self initWithCollectionViewLayout:layout];
    if (self) {
        KCDCollectionViewDataSource *dataSource = nil;
        if (KCDObjects.count > 0) {
            id<KCDSection>section = [KCDCollectionViewDataSource sectionWithName:nil objects:KCDObjects];
            dataSource = [[KCDCollectionViewDataSource alloc]
                          initWithDelegate:self
                          sections:@[section]];
        }
        else {
            dataSource = [[KCDCollectionViewDataSource alloc]
                          initWithDelegate:self
                          sections:nil];
        }
        [self setKCDObjectController:dataSource];
        [dataSource setCollectionView:self.collectionView];
        NSAssert([NSThread isMainThread],
                 @"Attempt to initialize off of main thread");
    }
    return self;
}

- (KCDCollectionViewDataSource *)KCDDataSource;
{
    KCDCollectionViewDataSource * controller = nil;
    if (!(controller = (KCDCollectionViewDataSource*)[self KCDObjectController]) ||
        ![controller isKindOfClass:[KCDCollectionViewDataSource class]]) {
        return nil;
    }
    return controller;
}

@end

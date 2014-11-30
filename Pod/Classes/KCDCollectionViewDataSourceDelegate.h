//
//  KCDCollectionViewDataSourceDelegate.h
//  KCDKoala
//
//  Created by Nicholas Zeltzer on 10/30/14.
//  Copyright (c) 2014 LawBox LLC. All rights reserved.
//

@import Foundation;
@import UIKit;

@class KCDObjectController;

#import "KCDScrollViewDataSource.h"
#import "KCDObjectProtocol.h"

@class KCDCollectionViewDataSource;

@protocol KCDCollectionViewDataSourceDelegate <KCDScrollViewDataSourceDelegate>

@optional

/**
 This is a direct pipe to the UICollectionViewDataSource protocol method with the same signature. Unlike most data source protocol methods, this one is not fit for a default implementation.
 */

- (UICollectionReusableView *)koala:(KCDObjectController<KCDIntrospective>*)koala
                     collectionView:(UICollectionView *)collectionView
  viewForSupplementaryElementOfKind:(NSString *)kind
                        atIndexPath:(NSIndexPath *)indexPath;

- (CGSize)koala:(KCDObjectController<KCDIntrospective>*)koala
 collectionView:(UICollectionView *)view
         layout:(UICollectionViewLayout *)layout
    sizeForItem:(id<KCDObject>)cellItem
    atIndexPath:(NSIndexPath *)indexPath;

- (UICollectionViewCell *)koala:(KCDObjectController<KCDIntrospective>*)koala
                 collectionView:(UICollectionView *)collectionView
                    cellForItem:(id<KCDObject>)cellItem
                    atIndexPath:(NSIndexPath *)indexPath;

- (void)koala:(KCDObjectController<KCDIntrospective>*)koala
collectionView:(UICollectionView *)collectionView
didSelectItem:(id<KCDObject>)item
  atIndexPath:(NSIndexPath *)indexPath;

@end
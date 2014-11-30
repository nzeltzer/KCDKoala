//
//  KCDCollectionViewDataSource
//  KCDKoala
//
//  Created by Nicholas Zeltzer on 10/29/14.
//  Copyright (c) 2014 LawBox LLC. All rights reserved.
//

#import "KCDScrollViewDataSource.h"
#import "KCDCollectionViewDataSourceDelegate.h"

/**
 Subclassing Notes.
 Subclasses that implement UICollectionView or UICollectionViewLayout delegate methods should defer to the data source's delegate for method implementations. Please see implementation for examples.
 */


@interface KCDCollectionViewDataSource : KCDScrollViewDataSource <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

#if __IPHONE_OS_VERSION_MIN_REQUIRED > __IPHONE_4_3
@property (nonatomic, readwrite, weak) id <KCDCollectionViewDataSourceDelegate> delegate;
@property (nonatomic, readwrite, weak) UICollectionView *collectionView;
#else
@property (nonatomic, readwrite, assign) id <KCDCollectionViewDataSourceDelegate> delegate;
@property (nonatomic, readwrite, assign) UICollectionView *collectionView;
#endif

@end

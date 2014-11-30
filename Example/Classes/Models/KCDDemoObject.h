//
//  KCDDemoCellObject.h
//  KCDKoalaMobile
//
//  Created by Nicholas Zeltzer on 11/4/14.
//  Copyright (c) 2014 Nicholas Zeltzer
//

@import UIKit;

#import <KCDKoala/KCDKoala.h>

/**
 Cell Identifiers affect registration of UICollectionViewCells. They have no affect in the UITableView context.
 */

UIKIT_EXTERN NSString * const KCDDefaultCellIdentifier;
UIKIT_EXTERN NSString * const KCDCircleCellIdentifier;
UIKIT_EXTERN NSString * const KCDSquareCellIdentifier;

@interface KCDDemoObject : KCDAbstractObject

@property (nonatomic, readonly, copy) NSString *identifier;
@property (nonatomic, readwrite, strong) UIColor *backgroundColor;

@end

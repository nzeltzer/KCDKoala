//
//  KCDKoala.h
//  KCDKoala
//
//  Created by Nicholas Zeltzer on 10/28/14.
//  Copyright (c) 2014 LawBox LLC. All rights reserved.
//

@import Foundation;

// Protocols

#import "KCDObjectProtocol.h"
#import "KCDSectionProtocol.h"
#import "KCDInternalTransactions.h"
#import "KCDViewUpdates.h"

// Base Classes

#import "KCDAbstractObject.h"
#import "KCDSectionContainer.h"
#import "KCDObjectController.h"

// Utilities

#import "KCDRuntime.h"
#import "KCDUtilities.h"

#if TARGET_OS_IPHONE

// Collection Views

#import "KCDCollectionViewDataSource.h"

// Table Views

#import "KCDTableViewDataSource.h"

// Categories

#import "UITableView+KCDKoala.h"
#import "UIViewController+KCDKoala.h"
#import "UITableViewController+KCDKoala.h"
#import "UICollectionViewController+KCDKoala.h"

#endif

//! Project version number for KCDKoala.
FOUNDATION_EXPORT double KCDKoalaVersionNumber;

//! Project version string for KCDKoala.
FOUNDATION_EXPORT const unsigned char KCDKoalaVersionString[];

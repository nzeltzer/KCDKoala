//
//  KCDTableViewDataSource.h
//  KCDKoala
//
//  Created by Nicholas Zeltzer on 10/29/14.
//  Copyright (c) 2014 LawBox LLC. All rights reserved.
//

@import Foundation;
#if TARGET_OS_IPHONE
@import UIKit;
#import "KCDScrollViewDataSource.h"
#import "KCDTableViewDataSourceDelegate.h"

/**
 Subclassing Notes.
 
 Subclasses that implement UITableViewDelegate methods should defer to the data source's delegate for method implementations where available. Please see implementation for examples.
 */

#pragma mark - KCDTableViewDataSource

@interface KCDTableViewDataSource : KCDScrollViewDataSource <UITableViewDataSource, UITableViewDelegate> {
}

/**
 The amount of time to pause between animated transactions. 
 @default: 0.25f
 */

@property (nonatomic, readwrite, assign) NSTimeInterval transactionStaggerDuration;
#if __IPHONE_OS_VERSION_MIN_REQUIRED > __IPHONE_4_3
@property (nonatomic, readwrite, weak) id <KCDTableViewDataSourceDelegate> delegate;
@property (nonatomic, readwrite, weak) UITableView *tableView;
#else
@property (nonatomic, readwrite, assign) id <KCDTableViewDataSourceDelegate> delegate;
@property (nonatomic, readwrite, assign) UITableView *tableView;
#endif

/** 
 If set to YES, the table view section index will be visible and populated using the section header strings. 
 */

@property (nonatomic, readwrite, assign) BOOL enableSectionIndex;

@end

#endif
//
//  UITableView+KCDTableViewDataSource.h
//  KCDKoalaMobile
//
//  Created by Nicholas Zeltzer on 10/31/14.
//  Copyright (c) 2014 LawBox LLC. All rights reserved.
//

@import UIKit;

@class KCDTableViewDataSource;

#pragma mark - UITableView+KCDKoala

@interface UITableView (KCDKoala)

/**
 A convenience accessor on UITableView that will return the table view's KCDCellObjectDataSource instance. If the table view's data source does not inherit from KCDCellObjectDataSource, this method will return nil.
 */

@property (readonly) KCDTableViewDataSource *KCDDataSource;

/**
 Returns the KCDCellObjects that represent the selected table view rows.
 */

- (NSArray*)selectedTableViewObjects;

/**
 Utility function for describing the value of a UITableViewRowAnimation enum value.
 */

NSString * KCDTableViewRowAnimationDescription(UITableViewRowAnimation rowAnimation);

@end

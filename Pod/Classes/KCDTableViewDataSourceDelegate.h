//
//  KCDTableViewDataSourceDelegate.h
//  KCDKoala
//
//  Created by Nicholas Zeltzer on 10/30/14.
//  Copyright (c) 2014 LawBox LLC. All rights reserved.
//

@import Foundation;
@import UIKit;

#import "KCDScrollViewDataSource.h"

@class KCDObjectController;


/**
 The KCDTableViewDataSourceDelegate protocol reimplements UITableViewDataSource methods to provide additional context.
 
 The data source will prefer delegate implementations of the following methods to its internal default implementations; all a delegate needs to do override the data source's implementation is to implement the corresponding method from the protocol.
 */

@protocol KCDTableViewDataSourceDelegate <KCDScrollViewDataSourceDelegate>

@optional

- (BOOL)koala:(KCDObjectController<KCDIntrospective>*)koala
    tableView:(UITableView *)tableView
canMoveObject:(id<KCDObject>)tableViewObject
  atIndexPath:(NSIndexPath *)indexPath;

- (BOOL)koala:(KCDObjectController<KCDIntrospective>*)koala
            tableView:(UITableView *)tableView
    canEditObject:(id<KCDObject>)tableViewObject
      atIndexPath:(NSIndexPath *)indexPath;

- (void)koala:(KCDObjectController<KCDIntrospective>*)koala
    tableView:(UITableView *)tableView
  didSelectObject:(id<KCDObject>)tableViewObject
      atIndexPath:(NSIndexPath*)indexPath;

- (void)koala:(KCDObjectController<KCDIntrospective>*)koala
    tableView:(UITableView *)tableView
didDeselectObject:(id<KCDObject>)tableViewObject
      atIndexPath:(NSIndexPath *)indexPath;

- (CGFloat)koala:(KCDObjectController<KCDIntrospective>*)koala
       tableView:(UITableView *)tableView
 heightForObject:(id<KCDObject>)tableViewObject;

- (void)koala:(KCDObjectController<KCDIntrospective>*)koala
    tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
        forObject:(id<KCDObject>)tableViewObject
      atIndexPath:(NSIndexPath *)indexPath;

- (void)koala:(KCDObjectController<KCDIntrospective>*)koala
    tableView:(UITableView *)tableView accessoryButtonTappedForObject:(id<KCDObject>)tableViewObject withIndexPath:(NSIndexPath *)indexPath;

- (void)koala:(KCDObjectController<KCDIntrospective>*)koala
    tableView:(UITableView *)tableView didDeleteCellForTableViewObject:(id<KCDObject>)tableViewObject;

- (UITableViewCell*)koala:(KCDObjectController<KCDIntrospective>*)koala
                tableView:(UITableView *)tableView
                cellForObject:(id<KCDObject>)tableViewObject
                  atIndexPath:(NSIndexPath*)indexPath;

- (UIView *)koala:(KCDObjectController<KCDIntrospective>*)koala
        tableView:(UITableView *)tableView viewForHeaderInSection:(id<KCDSection>)section;

- (CGFloat)koala:(KCDObjectController<KCDIntrospective>*)koala
       tableView:(UITableView *)tableView heightForHeaderInSection:(id<KCDSection>)section;

- (UIView *)koala:(KCDObjectController<KCDIntrospective>*)koala
        tableView:(UITableView *)tableView viewForFooterInSection:(id<KCDSection>)section;

- (CGFloat)koala:(KCDObjectController<KCDIntrospective>*)koala
       tableView:(UITableView *)tableView heightForFooterInSection:(id<KCDSection>)section;


@end


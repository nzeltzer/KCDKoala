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

@class KCDTableViewDataSource;

/**
 The KCDTableViewDataSourceDelegate protocol reimplements UITableViewDataSource methods to provide additional context.
 
 The data source will prefer delegate implementations of the following methods to its internal default implementations; all a delegate needs to do override the data source's implementation is to implement the corresponding method from the protocol.
 */

@protocol KCDTableViewDataSourceDelegate <KCDScrollViewDataSourceDelegate>

@optional

- (BOOL)koala:(KCDTableViewDataSource<KCDIntrospective>*)koala
    tableView:(UITableView *)tableView
canMoveObject:(id<KCDTableViewObject>)tableViewObject
  atIndexPath:(NSIndexPath *)indexPath;

- (BOOL)koala:(KCDTableViewDataSource<KCDIntrospective>*)koala
            tableView:(UITableView *)tableView
    canEditObject:(id<KCDTableViewObject>)tableViewObject
      atIndexPath:(NSIndexPath *)indexPath;

- (void)koala:(KCDTableViewDataSource<KCDIntrospective>*)koala
    tableView:(UITableView *)tableView
  didSelectObject:(id<KCDTableViewObject>)tableViewObject
      atIndexPath:(NSIndexPath*)indexPath;

- (void)koala:(KCDTableViewDataSource<KCDIntrospective>*)koala
    tableView:(UITableView *)tableView
didDeselectObject:(id<KCDTableViewObject>)tableViewObject
      atIndexPath:(NSIndexPath *)indexPath;

- (CGFloat)koala:(KCDTableViewDataSource<KCDIntrospective>*)koala
       tableView:(UITableView *)tableView
 heightForObject:(id<KCDTableViewObject>)tableViewObject;

- (void)koala:(KCDTableViewDataSource<KCDIntrospective>*)koala
    tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
        forObject:(id<KCDTableViewObject>)tableViewObject
      atIndexPath:(NSIndexPath *)indexPath;

- (void)koala:(KCDTableViewDataSource<KCDIntrospective>*)koala
    tableView:(UITableView *)tableView accessoryButtonTappedForObject:(id<KCDTableViewObject>)tableViewObject withIndexPath:(NSIndexPath *)indexPath;

- (void)koala:(KCDTableViewDataSource<KCDIntrospective>*)koala
    tableView:(UITableView *)tableView didDeleteCellForTableViewObject:(id<KCDTableViewObject>)tableViewObject;

- (UITableViewCell*)koala:(KCDTableViewDataSource<KCDIntrospective>*)koala
                tableView:(UITableView *)tableView
                cellForObject:(id<KCDTableViewObject>)tableViewObject
                  atIndexPath:(NSIndexPath*)indexPath;

- (UIView *)koala:(KCDTableViewDataSource<KCDIntrospective>*)koala
        tableView:(UITableView *)tableView viewForHeaderInSection:(id<KCDSection>)section;

- (CGFloat)koala:(KCDTableViewDataSource<KCDIntrospective>*)koala
       tableView:(UITableView *)tableView heightForHeaderInSection:(id<KCDSection>)section;

- (UIView *)koala:(KCDTableViewDataSource<KCDIntrospective>*)koala
        tableView:(UITableView *)tableView viewForFooterInSection:(id<KCDSection>)section;

- (CGFloat)koala:(KCDTableViewDataSource<KCDIntrospective>*)koala
       tableView:(UITableView *)tableView heightForFooterInSection:(id<KCDSection>)section;


@end


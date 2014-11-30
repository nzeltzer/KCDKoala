//
//  KCDObject.h
//  KCDKoala
//
//  Created by Nicholas Zeltzer on 10/29/14.
//  Copyright (c) 2014 LawBox LLC. All rights reserved.
//

@import Foundation;
#if TARGET_OS_IPHONE
@import UIKit;
#else
@import Cocoa;
@import AppKit;
#endif

@protocol KCDObject <NSObject>

/**
 A string value that can be used for cell registrations.
 @default An NSString representation of the class name.
 */

@property (nonatomic, readonly, copy) NSString *identifier;

@optional

@property (nonatomic, readonly, assign) BOOL canEdit;
@property (nonatomic, readonly, assign) BOOL canMove;

@end

#if TARGET_OS_IPHONE

#pragma mark - iOS Protocol Extensions -

#pragma mark - KCDTableViewObject

@protocol KCDTableViewObject <KCDObject>

- (UITableViewCell *)cellForTableView:(UITableView *)tableView;

- (CGFloat)heightForCellInTableView:(UITableView *)tableView;

@end

#pragma mark - KCDCollectionViewObject

@protocol KCDCollectionViewObject <KCDObject>

- (UICollectionViewCell*)cellForCollectionView:(UICollectionView*)collectionView
                                   atIndexPath:(NSIndexPath*)indexPath;

- (CGSize)sizeForCollectionView:(UICollectionView *)collectionView
                         layout:(UICollectionViewLayout *)collectionViewLayout;

@end

#else

#pragma mark - OS-X Protocol Extensions -

#pragma mark - KCDTableViewObject

@protocol KCDTableViewObject <KCDObject>

- (NSTableCellView *)cellForTableView:(NSTableView *)tableView;

- (CGFloat)heightForCellInTableView:(NSTableView *)tableView;

@end

@protocol KCDCollectionViewObject <KCDObject>

@end

#endif

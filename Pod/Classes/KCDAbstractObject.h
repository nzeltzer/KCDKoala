//
//  KCDAbstractObject
//  Created by Nicholas Zeltzer on 11/2/11.
//
/**
 KCDAbstractObject is an bare-bones implementation of the KCDObject protocol.
 KCDAbstractObject can be subclassed, or used as a container for non-conformant objects.
 Unlike KCDSectionContainer, KCDObjectController and its subclasses do not use KCDAbstractObject internally. 
 */

@import Foundation;

#import "KCDObjectProtocol.h"

#if TARGET_OS_IPHONE
@import UIKit;
#else
@import AppKit;
#endif

@interface KCDAbstractObject : NSObject <KCDCollectionViewObject, KCDTableViewObject>

/**
 The represented object is a free form node for use when the represented object does not conform to the KCDObject.
 */

@property (nonatomic, readwrite, strong) id <NSObject> representedObject;

/**
 The title of this object. 
 */

@property (nonatomic, readwrite, copy) NSString *title;

/**
 The cell identifier for this object.
 @note This identifier should be used for dequeuing reusable views in both UITableView and UICollectionView. The KCDObject subclass is responsible for returning a proper class from collectionViewCellClass: and tableViewCellClass: class methods.
 */

@property (nonatomic, readonly, copy) NSString *identifier;

/**
 Returns a new, empty KCDObject.
 @note The identifier will be a string representation of the KCDObject's class name.
 */

- (instancetype)init NS_DESIGNATED_INITIALIZER;

/**
 Returns a new, empty KCDObject with the provided identifier.
 */

- (instancetype)initWithIdentifier:(NSString *)identifier;

#if TARGET_OS_IPHONE

#pragma mark - KCDTableViewObject

- (UITableViewCell *)cellForTableView:(UITableView *)tableView;

- (CGFloat)heightForCellInTableView:(UITableView *)tableView;

#pragma mark KCDObject

+ (Class)tableViewCellClass:(NSString *)identifier;

- (void)configureTableViewCell:(UITableViewCell *)cell;

#pragma mark - KCDCollectionViewObject

- (UICollectionViewCell*)cellForCollectionView:(UICollectionView*)view
                                   atIndexPath:(NSIndexPath*)indexPath;

- (CGSize)sizeForCollectionView:(UICollectionView *)view
                         layout:(UICollectionViewLayout *)layout;

#pragma mark KCDObject

/**
 KCDAbstractObject classes can provide a dictionary mapping identifier strings to cell class names. This allows you to use the UICollectionView/Controller KCDCellClassRegister category method to register your cell classes in one line.
 @note This is an optional convenience structure.
 */

+ (NSDictionary *)collectionViewCellClassMap;

/**
 Returns the appropriate cell class for the identifier.
 */

+ (Class)collectionViewCellClass:(NSString *)identifier;

- (void)configureCollectionViewCell:(UICollectionViewCell*)cell;

#else

#pragma mark - NSTableView

- (NSTableCellView *)cellViewForTableView:(NSTableView *)tableView;

- (CGFloat)heightForCellViewInTableView:(NSTableView *)tableView;

#pragma mark KCDObject

+ (Class)tableViewCellClass:(NSString *)identifier;

- (void)configureTableCellView:(NSTableCellView *)cellView;

#endif

@end

#if TARGET_OS_IPHONE

#pragma mark - UICollectionView+KCDObject

@interface UICollectionView (KCDObject)

- (void)KCDCellClassRegister:(Class)KCDObjectClass;

@end

@interface UICollectionViewController (KCDObject)

- (void)KCDCellClassRegister:(Class)KCDObjectClass;

@end

#pragma mark - Base Classes

/** 
 iOS Primitive View Classes.
 */

@interface KCDTableViewCell : UITableViewCell

@end

@interface KCDCollectionViewCell : UICollectionViewCell

@end

@interface KCDReusableView : UICollectionReusableView

@end

#endif
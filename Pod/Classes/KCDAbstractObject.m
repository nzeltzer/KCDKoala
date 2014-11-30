//
//  KCDObject.m
//
//  Created by Nicholas Zeltzer on 11/2/11.
//

#import "KCDAbstractObject.h"
#import <objc/runtime.h>

@interface KCDAbstractObject()

@end

@implementation KCDAbstractObject

@synthesize canEdit = _canEdit;
@synthesize canMove = _canMove;

- (instancetype)initWithIdentifier:(NSString *)identifier;
{
    self = [self init];
    if (self) {
        NSAssert(identifier.length > 0,
                 @"Attempt to initialize %@ with nil identifier.",
                 NSStringFromClass([self class]));
        if (identifier.length > 0) {
            _identifier = identifier;
        }
    }
    return self;
}

- (instancetype)init;
{
    self = [super init];
    if (self) {
        // By default, the identifier is the name of the object class.
        _identifier = NSStringFromClass([self class]);
        _canMove = NO;
        _canEdit = NO;
    }
    return self;
}

- (NSString *)description;
{
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@", NSStringFromClass([self class])];
    [description appendFormat:@" (%@)", self.identifier];
    [description appendFormat:@" { title = %@ }", self.title];
    [description appendFormat:@" %p>", self];
    return description;
}

#if TARGET_OS_IPHONE

#pragma mark - KCDTableViewObject Protocol

- (UITableViewCell *)cellForTableView:(UITableView *)tableView;
{
    UITableViewCell *aCell = nil;
    if (!(aCell = [tableView dequeueReusableCellWithIdentifier:self.identifier])) {
        Class cellClass = [[self class] tableViewCellClass:self.identifier];
        aCell = [[cellClass alloc] initWithStyle:UITableViewCellStyleDefault
                                 reuseIdentifier:self.identifier];
    }
    [self configureTableViewCell:aCell];
    return aCell;
}

- (CGFloat)heightForCellInTableView:(UITableView *)tableView;
{
    return 44.0f;
}

- (void)configureTableViewCell:(UITableViewCell *)cell;
{
    cell.textLabel.text = [self title];
}

#pragma mark KCDObject Protocol

+ (Class)tableViewCellClass:(NSString *)identifier;
{
    return [KCDTableViewCell class];
}

#pragma mark - KCDCollectionViewObject Protocol

- (UICollectionViewCell*)cellForCollectionView:(UICollectionView*)view
                                   atIndexPath:(NSIndexPath*)indexPath;
{
    UICollectionViewCell *aCell = nil;
    @try {
        aCell = [view dequeueReusableCellWithReuseIdentifier:self.identifier
                                                forIndexPath:indexPath];
    }
    @catch (NSException *exception) {
        
        NSLog(@"Failed to dequeue cell with reuse identifier %@."
             "Did you forget to register a cell class with the collection view?", self.identifier);
        
        // If this is the NSInternalInconsistencyException for failing to
        // dequeue a view for the identifier, you most likely forgot to
        // register the class with the collection view.
        
        // This isn't Java: don't ship apps that trigger this exception.
        
        Class cellClass = Nil;
        if (!(cellClass = [[self class] collectionViewCellClass:self.identifier])) {
            NSAssert(cellClass, @"Object did not return a cell class for identifier: %@",
                     self.identifier);
            cellClass = [KCDCollectionViewCell class];
        }
        NSLog(@"Caught exception and registered %@ for %@. This is a bug.",
             NSStringFromClass(cellClass), self.identifier);
        [view registerClass:cellClass forCellWithReuseIdentifier:self.identifier];
        
    }
    @finally {
        aCell = [view dequeueReusableCellWithReuseIdentifier:self.identifier
                                                forIndexPath:indexPath];
    }
    NSAssert([aCell isKindOfClass:[[self class] collectionViewCellClass:self.identifier]],
             @"Incorrect cell class (%@) for identifier (%@); should be: %@\n\n%@",
             NSStringFromClass([aCell class]), self.identifier,
             [[self class] collectionViewCellClass:self.identifier],
             [[self class] collectionViewCellClassMap]);
    [self configureCollectionViewCell:aCell];
    return aCell;
}

- (CGSize)sizeForCollectionView:(UICollectionView *)view
                         layout:(UICollectionViewLayout *)layout;
{
    return CGSizeMake(44.0f, 44.0f);
}

#pragma mark KCDObject Protocol

+ (NSDictionary *)collectionViewCellClassMap;
{
    // This method works in combination with the UICollectionView+KCDObject category method
    // 'KCDCellClassRegister'.
    
    static NSDictionary *map = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        map = @{ NSStringFromClass([self class]) : NSStringFromClass([KCDCollectionViewCell class]) };
    });
    return map;
}

+ (Class)collectionViewCellClass:(NSString *)identifier;
{
    return NSClassFromString([[self class] collectionViewCellClassMap][identifier]);
}

- (void)configureCollectionViewCell:(UICollectionViewCell*)cell;
{

}

#else

#pragma mark - NSTableView

- (NSTableCellView *)cellViewForTableView:(NSTableView *)tableView;
{
    NSAssert(NO, @"Unimplemented method");
    return nil;
}

- (CGFloat)heightForCellViewInTableView:(NSTableView *)tableView;
{
    return 44.0f;
}

- (void)configureTableCellView:(NSTableCellView *)cellView;
{

}

#endif

@end

#if TARGET_OS_IPHONE

@implementation UICollectionView (KCDObject)

- (void)KCDCellClassRegister:(Class)KCDObjectClass;
{
    if (class_getClassMethod(KCDObjectClass, @selector(collectionViewCellClassMap))) {
        NSDictionary * map = [(id)KCDObjectClass performSelector:@selector(collectionViewCellClassMap)];
        [map enumerateKeysAndObjectsUsingBlock:^(NSString *identifer, NSString * className, BOOL *stop) {
            Class cellClass = Nil;
            if ((cellClass = NSClassFromString(className))) {
                [self registerClass:cellClass forCellWithReuseIdentifier:identifer];
            }
            else {
                NSLog(@"Could not register cell class %@ for identifier: %@", className, identifer);
            }
        }];
    }
}

@end

#pragma mark - UICollectionViewController+KCDObject

@implementation UICollectionViewController (KCDObject)

- (void)KCDCellClassRegister:(Class)KCDObjectClass;
{
    [self.collectionView KCDCellClassRegister:KCDObjectClass];
}

@end

#pragma mark - KCDTableViewCell

@implementation KCDTableViewCell

@end

#pragma mark - KCDCollectionViewCell

@implementation KCDCollectionViewCell

@end

#pragma makr - KCDReusableView

@implementation KCDReusableView

@end

#endif
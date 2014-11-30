# [![KCDKoala](http://piratepenguin.com/downloads/KCDKoala.jpg?raw=true)](#)

# Important

This documentation is incomplete pending the initial public release of KCDKoala. 

# What is KCDKoala?

KCDKoala is an object controller for iOS view collection classes (UITableView, UICollectionView). It is intended to allow quick instantiation of customizable UITableViewController and UICollectionViewController instances via a common API.

Once instantiated, the contents of a Koala-backed view controller can be manipulated sequentially in a similar manner to traditional Cocoa storage classes (e.g., NSMutableArray). Changes to the object arrangement are automatically reflected in the corresponding UITableView or UICollectionView as animated updates.  

### [![KCDKoala API](http://piratepenguin.com/downloads/koala_api.gif?raw=true)](#)

Internally, all transaction updates are dispatched on paired, private serial queues that provide animated updates to controller content in a serialized, safe manner. 

In order to maximize setup speed, Koala declares a pair of simple MVVM protocols that any class can adopt by category to become a Koala-presentable object. Once an object adopts the appropriate protocol, a fully interactive view controller can be created with a single initialization call. 

Each of these protocols is intentially minimalist:

```
// KCDTableViewObject

- (UITableViewCell *)cellForTableView:(UITableView *)tableView;
- (CGFloat)heightForTableView:(UITableView *)tableView;

// KCDCollectionViewObject

- (UICollectionViewCell *)cellForCollectionView:(UICollectionView *)collectionView;
- (CGSize)sizeForCollectionView:(UICollectionView *)collectionView;

```
## Getting Started

KCDKoala provides implementations of UITableViewDataSource and UICollectionViewDataSource that allow collection presentation of any object class that conform to the relevant KCDObjectProtocol protocol extension. In most circumstances, you do not need to create an instance of these classes directly: they will be created automatically through the appropriate view controller initialization method – _e.g., [[UITableViewController alloc] initWithStyle:UITableViewStylePlain objects:myObjectsArray];_

## A Brief Example

For example, to present a table view of NSString instances, one can simply adopt the KCDTableViewObject protocol via category:

```
@interface NSString (KCDTableViewObject) <KCDTableViewObjectProtocol>
@end

@implementation NSString (KCDTableViewObject)

- (UITableViewCell *)cellForTableView:(UITableView *)tableView;{
      // Dequeue and return a cell;
}

- (CGFloat)heightForCellInTableView:(UITableView *)tableView;{
      // Return a height.
}
  
@end

```

Once the class to be represented has adopted the appropriate protocol, creating the appropriate view controller is simple:

```
UITableViewController *controller = [[UITableViewController alloc] 
                                      initWithStyle:UITableViewStylePlain 
                                      objects:myArrayOfStrings];
```

Once the view controller has been instantiated, you can access the object controller through the KCDDataSource property on UITableViewController.

```
KCDObjectController *koala = [controller KCDDataSource];
```

And you can manipulate the controller’s content just as easily:

```
[koala moveObjectsAtIndexPaths:fromPaths toIndexPaths:toPaths];
[koala insertObjects:moreObjects inSectionAtIndex:0 animation:UITableViewRowAnimationMiddle];
[koala sortSectionAtIndex:0 withComparator:myComparator];
 
id<KCDMutableSectionProtocol> myMutableSection = [koala newSectionWithName:@"Section Two" objects:moreObjects];

// Perform an animated update to the table view contents:
[koala setSections:@[myMutableSection] animation:UITableViewRowAnimationFade completion:nil];
```

###Transaction Queues###

_Pending_

### Tests ###

KCDKoala includes a complete set of unit tests, and a sample application that demonstrates each API call in an application environment. 

//
//  KCDCellObjectDataSource+ShuffleForever.h
//  KCDCellObjectDataSource
//
//  Created by Nicholas Zeltzer on 10/29/14.
//  Copyright (c) 2014 Nicholas Zeltzer
//

#import <KCDKoala/KCDKoala.h>
#import "KCDDemoObject.h"
#import "KCDDemoCollectionViewCell.h"
#import "KCDDemoTableViewCell.h"
#import "KCDDemoReusableView.h"

@interface KCDObjectController (KCDDemoApp)

- (void)KCDDemoShuffleForever;
- (void)KCDDemoAPIForever:(NSString *)identifier;
- (void)KCDDemoDiffForever:(NSString *)identifier;

@end




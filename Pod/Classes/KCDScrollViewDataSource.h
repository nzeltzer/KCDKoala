//
//  KCDScrollViewDataSource.h
//  KCDKoala
//
//  Created by Nicholas Zeltzer on 10/29/14.
//  Copyright (c) 2014 LawBox LLC. All rights reserved.
//

#import "KCDObjectController.h"

/**
 An abstract class for KCDCellObjectDataSources that manage UIScrollView descendents.
 */

/**
 KCDScrollViewDataSourceDelegateFlags are set with the delegate and provide an efficient method of checking delegate conformance that does not incur the burder of respondsToSelector:.
 */

typedef struct {
    BOOL scrollViewDidScroll;
    BOOL scrollViewDidZoom;
    BOOL scrollViewWillBeginDragging;
    BOOL scrollViewWillEndDragging_withVelocity_targetContentOffset;
    BOOL scrollViewDidEndDragging_willDecelerate;
    BOOL scrollViewWillBeginDecelerating;
    BOOL scrollViewDidEndDecelerating;
    BOOL scrollViewDidEndScrollingAnimation;
    BOOL viewForZoomingInScrollView;
    BOOL scrollViewWillBeginZooming_withView;
    BOOL scrollViewDidEndZooming_withView_atScale;
    BOOL scrollViewShouldScrollToTop;
    BOOL scrollViewDidScrollToTop;
} KCDScrollViewDataSourceDelegateFlags;

@protocol KCDScrollViewDataSourceDelegate <KCDObjectControllerDelegate>

@end

@interface KCDScrollViewDataSource : KCDObjectController <UIScrollViewDelegate> {
    @protected
    KCDScrollViewDataSourceDelegateFlags _scrollViewDelegateFlags;
}
#if __IPHONE_OS_VERSION_MIN_REQUIRED > __IPHONE_4_3
@property (nonatomic, readwrite, weak) id <KCDScrollViewDataSourceDelegate> delegate;
#else
@property (nonatomic, readwrite, assign) id <KCDScrollViewDataSourceDelegate> delegate;
#endif

@end

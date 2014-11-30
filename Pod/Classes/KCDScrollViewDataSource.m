//
//  KCDScrollViewDataSource.m
//  KCDKoala
//
//  Created by Nicholas Zeltzer on 10/29/14.
//  Copyright (c) 2014 LawBox LLC. All rights reserved.
//

#import "KCDScrollViewDataSource.h"

@interface KCDScrollViewDataSource() {
    
}

@end

@implementation KCDScrollViewDataSource

@dynamic delegate;

- (instancetype)initWithDelegate:(id<KCDScrollViewDataSourceDelegate>)delegate;
{
    self = [super initWithDelegate:delegate];
    if (self) {
        NSAssert(![self isMemberOfClass:[KCDScrollViewDataSource class]], @"Attempt to initialize abstract class: %@", [self class]);
    }
    return self;
}

- (NSArray *)forwardingProtocols;
{
    return @[@protocol(UIScrollViewDelegate)];
}

- (id<KCDScrollViewDataSourceDelegate, UIScrollViewDelegate>)delegate;
{
    return (id<KCDScrollViewDataSourceDelegate, UIScrollViewDelegate>)[super delegate];
}

- (void)setDelegate:(id<KCDScrollViewDataSourceDelegate, UIScrollViewDelegate>)delegate;
{
    _scrollViewDelegateFlags.scrollViewDidZoom = [delegate respondsToSelector:@selector(scrollViewDidZoom:)];
    _scrollViewDelegateFlags.viewForZoomingInScrollView = [delegate respondsToSelector:@selector(viewForZoomingInScrollView:)];
    _scrollViewDelegateFlags.scrollViewWillBeginZooming_withView = [delegate respondsToSelector:@selector(scrollViewWillBeginZooming:withView:)];
    _scrollViewDelegateFlags.scrollViewDidEndZooming_withView_atScale = [delegate respondsToSelector:@selector(scrollViewDidEndZooming:withView:atScale:)];
    _scrollViewDelegateFlags.scrollViewShouldScrollToTop = [delegate respondsToSelector:@selector(scrollViewShouldScrollToTop:)];
    _scrollViewDelegateFlags.scrollViewDidEndDecelerating = [delegate respondsToSelector:@selector(scrollViewDidEndDecelerating:)];
    _scrollViewDelegateFlags.scrollViewDidEndDragging_willDecelerate = [delegate respondsToSelector:@selector(scrollViewDidEndDragging:willDecelerate:)];
    _scrollViewDelegateFlags.scrollViewDidEndScrollingAnimation = [delegate respondsToSelector:@selector(scrollViewDidEndScrollingAnimation:)];
    _scrollViewDelegateFlags.scrollViewDidScroll = [delegate respondsToSelector:@selector(scrollViewDidScroll:)];
    _scrollViewDelegateFlags.scrollViewDidScrollToTop = [delegate respondsToSelector:@selector(scrollViewDidScrollToTop:)];
    _scrollViewDelegateFlags.scrollViewWillBeginDecelerating = [delegate respondsToSelector:@selector(scrollViewWillBeginDecelerating:)];
    _scrollViewDelegateFlags.scrollViewWillBeginDragging = [delegate respondsToSelector:@selector(scrollViewWillBeginDragging:)];
    _scrollViewDelegateFlags.scrollViewWillEndDragging_withVelocity_targetContentOffset = [delegate respondsToSelector:@selector(scrollViewWillEndDragging:withVelocity:targetContentOffset:)];
    [super setDelegate:delegate];
}

@end

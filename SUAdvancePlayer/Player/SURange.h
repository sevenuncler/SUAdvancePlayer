//
//  SURange.h
//  TBPlayer
//
//  Created by fanghe on 17/9/14.
//  Copyright © 2017年 SF. All rights reserved.
//
#ifndef SURANGE_h
#define SURANGE_h
#import <Foundation/Foundation.h>



struct _SURange{
    unsigned long long      location;
    unsigned long long      length;
    struct _SURange *next;
};
typedef struct _SURange SURange;
typedef struct _SURange *SURangePointer;

NS_INLINE SURange SUMakeRange(NSUInteger loc, NSUInteger len) {
    SURange r;
    r.location = loc;
    r.length   = len;
    r.next     = NULL;
    return r;
}

NS_INLINE NSRange SURange2NSRange(SURange node) {
    NSRange r;
    r.location = node.location;
    r.length   = node.length;
    return r;
}

NS_INLINE BOOL SULocationInRange(NSUInteger loc, SURange range) {
    return (!(loc < range.location) && (loc - range.location) < range.length) ? YES : NO;
}


SURangePointer mergeNode(SURangePointer node1, SURangePointer node2);

SURangePointer  SUInsertNodeIntoRange(SURange  *src, SURange *node1);

void swapSmallLocation2Left(SURangePointer node1, SURangePointer node2);

void SURangePrint(SURange *range);

int isTargetCrossInSrc(SURangePointer src, SURangePointer target);

SURangePointer getGapRanges(SURangePointer links, SURangePointer node);

#endif







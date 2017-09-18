//
//  SURange.h
//  TBPlayer
//
//  Created by fanghe on 17/9/14.
//  Copyright © 2017年 SF. All rights reserved.
//

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

SURange SUMergeNode(SURange range1, SURange range2) {
    SURange src;
    SURange assit;
    if(range1.location <= range2.location) {
        src     = range1;
        assit   = range2;
    }else {
        src     = range2;
        assit   = range1;
    }
    if(assit.location <= (src.length+src.location)) {
        src.length = assit.location + assit.length - src.location;
    }else {
        src.next = &assit;
    }
    return src;
}

NS_INLINE SURange SUMergeRange(SURange range1, SURange range2) {
    SURange src;
    SURange assit;
    if(range1.location <= range2.location) {
        src     = range1;
        assit   = range2;
    }else {
        src     = range2;
        assit   = range1;
    }
    
    for(SURange *node = &src; node; node = node->next) {
        
    }
    
    return src;
}
SURange  SUInsertNodeIntoRangeByReference(SURange  src, SURange node){
    SURange head;
    SURange tail;
    
    //
    for(head = src; head.length != 0; head = *head.next) {
        if(node.location <= (head.location + head.length - 1)) {
            break;
        }
    }
    
    for(tail = head; tail.length != 0; tail = *tail.next) {
        if((node.location + node.length - 1) < head.location) {
            break;
        }
    }
    
    //忽略中间节点，合并head节点和node 节点
    SURange range;
    if((node.location + node.length-1) < head.location) {
        node.next = &head;
        range = head;
        head  = node;
    }else {
        NSUInteger  location = MIN(node.location, head.location);
        NSUInteger  offset   = MAX(node.location + node.length - 1, head.location + head.length - 1);
        range.location = location;
        range.length   = offset - location - 1;
        range.next = NULL;
        head = range;
    }
    
    //忽略中间节点，直接连接尾部节点
    range.next = &tail;
    return head;
}

SURangePointer mergeNode(SURangePointer node1, SURangePointer node2);
SURangePointer  SUInsertNodeIntoRange(SURange  *src, SURange *node){
    struct _SURange * headPre       = NULL;
    struct _SURange * tailPre       = NULL;
    struct _SURange * head          = NULL;
    struct _SURange * tail          = NULL;
    struct _SURange * targetHead    = NULL;
    if(src == NULL || node == NULL || node->length <= 0 || src->length <= 0) {
        return src;
    }
    targetHead = src;
    //
    for(head = src; head; head = head->next) {
        if(node->location <= (head->location + head->length - 1) + 1) {
            break;
        }
        headPre = head;
    }
    
    for(tail = head; tail; tail = tail->next) {
        if(tail->location>0 && (node->location + node->length - 1) < tail->location - 1) {
            break;
        }
        tailPre = tail;
    }
    
    //忽略中间节点，合并head节点和node 节点
    SURangePointer range = NULL;
    if(NULL != head) {
        if(head->location>0 && (node->location + node->length-1) < head->location - 1) {
            node->next = head;
            range = node;
        }else {
            NSUInteger  location = MIN(node->location, head->location);
            NSUInteger  offset   = MAX(node->location + node->length - 1, head->location + head->length - 1);
            range = (SURangePointer)malloc(sizeof(SURange));
            range->location = location;
            range->length   = offset - location + 1;
            range->next = NULL;
            
            //
            range = mergeNode(range, tailPre);
            range->next = tail;
            head = range;
        }
    }else {
        range = node;
    }
    
    //处理尾部节点前一个节点，不能漏掉
    
    if(NULL == headPre) {
        targetHead = range;
    }else {
        headPre->next = range;
    }
    return targetHead;
}

void swapSmallLocation2Left(SURangePointer node1, SURangePointer node2);
//使用此函数的前提是两个节点有重合的部分，否则
SURangePointer mergeNode(SURangePointer node1, SURangePointer node2) {
    SURangePointer range;
    SURangePointer head;
    if(NULL == node2 || NULL == node1) {
        return node1;
    }
    swapSmallLocation2Left(node1, node2);
    
    if(node1->location >0 && (node2->location + node2->length-1) < node1->location - 1) {
        node2->next = node1;
        head = node2;
    }else {
        NSUInteger  location = MIN(node2->location, node1->location);
        NSUInteger  offset   = MAX(node2->location + node2->length - 1, node1->location + node1->length - 1);
        range = (SURangePointer)malloc(sizeof(SURange));
        range->location = location;
        range->length   = offset - location + 1;
        range->next = NULL;
        head = range;
    }
    return head;
}

void swapSmallLocation2Left(SURangePointer node1, SURangePointer node2) {
    SURangePointer tmp;
    if(NULL == node1 || NULL == node2) {
        return;
    }
    if(node1->location > node2->location) {
        tmp     = node1;
        node1   = node2;
        node2   = tmp;
    }
}

void SURangePrint(SURangePointer range) {
    while (range) {
        printf(" (%lld, %lld, length = %lld)", range->location, range->location+range->length-1, range->length);
        range = range->next;
    }
}









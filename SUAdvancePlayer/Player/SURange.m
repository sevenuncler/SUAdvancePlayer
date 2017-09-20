//
//  SURange.c
//  SUAdvancePlayer
//
//  Created by He on 2017/9/20.
//  Copyright © 2017年 Sevenuncle. All rights reserved.
//
#import "SURange.h"

SURangePointer  SUInsertNodeIntoRange(SURange  *src, SURange *node1){
    struct _SURange * headPre       = NULL;
    struct _SURange * tailPre       = NULL;
    struct _SURange * head          = NULL;
    struct _SURange * tail          = NULL;
    struct _SURange * targetHead    = NULL;
    struct _SURange * node          = NULL;
    
    //拷贝
    node = malloc(sizeof(SURange));
    memcpy(node, node1, sizeof(SURange));
    
    if(src == NULL || src->length <= 0) {
        return node;
    }
    if(node == NULL || node->length <= 0 ) {
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
            free(node);
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

SURangePointer getGapRanges(SURangePointer links, SURangePointer node) {
    SURangePointer  head    = NULL;
    SURangePointer  tail    = NULL;
    SURangePointer  preTail = NULL;
    SURangePointer  tmp     = NULL;
    
    unsigned long long nodeStart = node->location;
    unsigned long long nodeEnd   = node->location + node->length - 1;
    
    head = links;
    while(NULL != head) {
        unsigned long long start = head->location;
        unsigned long long end   = head->location + head->length - 1;
        if((start <= nodeStart && end >= nodeStart && end <= nodeEnd)
           || (start >= nodeStart && end <= nodeEnd)
           || (nodeStart <= start && start <= nodeEnd && nodeEnd <= end)) {
            break;
        }
        head = head->next;
    }
    
    if(NULL != head) {
        preTail = head;
        tail    = head->next;
    }else {
        preTail = tail = NULL;
    }
    
    while (NULL != tail) {
        unsigned long long start = tail->location;
        unsigned long long end   = tail->location + head->length - 1;
        if((start <= nodeStart && end >= nodeStart && end <= nodeEnd)
           || (start >= nodeStart && end <= nodeEnd)
           || (nodeStart <= start && start <= nodeEnd && nodeEnd <= end)) {
            
        }else {
            break;
        }
        preTail = tail;
        tail = tail->next;
    }
    tail = preTail;
    
    if(NULL == head) {
        return node;
    }
    SURangePointer resultHead      = NULL;
    SURangePointer currentPointer  = NULL;
    tmp = NULL;
    switch (isTargetCrossInSrc(node, head)) {
        case 1:
            break;
        case 2:
            tmp = (SURangePointer)malloc(sizeof(SURange));
            tmp->location = nodeStart;
            tmp->length   = head->location - nodeStart;
            tmp->next     = NULL;
            resultHead = tmp;
            break;
        case 3:
            tmp = (SURangePointer)malloc(sizeof(SURange));
            tmp->location = nodeStart;
            tmp->length   = head->location - nodeStart;
            tmp->next     = NULL;
            resultHead = tmp;
            break;
        default:
            break;
    }
    
    while (head->next != NULL && head != tail) {
        currentPointer = (SURangePointer)malloc(sizeof(SURange));
        currentPointer->location = head->location + head->length;
        currentPointer->length   = head->next->location - currentPointer->location; //head->next->location - 1 - currentPointer->location + 1
        currentPointer->next     = NULL;
        if(tmp == NULL) {
            tmp = currentPointer;
            resultHead = tmp;
        }else {
            tmp->next = currentPointer;
            tmp = currentPointer;
        }
        head = head->next;
    }
    
    switch (isTargetCrossInSrc(node, tail)) {
        case 1:
        case 2:
            currentPointer = (SURangePointer)malloc(sizeof(SURange));
            currentPointer->location = tail->location + tail->length ;
            currentPointer->length   = nodeEnd - currentPointer->location + 1;
            currentPointer->next     = NULL;
            if(tmp == NULL) {
                tmp = currentPointer;
                resultHead = tmp;
            }else {
                tmp->next = currentPointer;
            }
            break;
        case 3:
            break;
        default:
            break;
    }
    return resultHead;
}


int isTargetCrossInSrc(SURangePointer src, SURangePointer target) {
    if(NULL == src || target == NULL) {
        return 0;
    }
    unsigned long long nodeStart = src->location;
    unsigned long long nodeEnd   = src->location + src->length - 1;
    
    unsigned long long start = target->location;
    unsigned long long end   = target->location + target->length - 1;
    if(start <= nodeStart && end >= nodeStart && end <= nodeEnd) {
        return 1;
    }else if(start > nodeStart && end < nodeEnd) {
        return 2;
    }else if(nodeStart <= start && start <= nodeEnd && nodeEnd <= end) {
        return 3;
    }
    return 0;
}

void SURangePrint(SURange *range) {
    while (range) {
        printf(" (%lld, %lld, length = %lld)", range->location, range->location+range->length-1, range->length);
        range = range->next;
    }
    printf("\n");
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

//使用此函数的前提是两个节点有重合的部分，否则
SURangePointer mergeNode(SURangePointer node1, SURangePointer node) {
    SURangePointer range;
    SURangePointer head;
    SURangePointer node2 = NULL;
    
    //拷贝
    node2 = malloc(sizeof(SURange));
    memcpy(node2, node, sizeof(SURange));
    
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
        free(node2);
    }
    return head;
}

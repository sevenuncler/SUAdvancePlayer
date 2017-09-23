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
//            SURangePointer tmp = malloc(sizeof(SURange));
//            memcpy(tmp, head, sizeof(SURange));
//            tmp->next = NULL;
            node->next = head;
            range = node;
        }else {
            unsigned long long  location = MIN(node->location, head->location);
            unsigned long long  offset   = MAX(node->location + node->length - 1, head->location + head->length - 1);
            range = (SURangePointer)malloc(sizeof(SURange));
            range->location = location;
            range->length   = offset - location + 1;
            range->next = NULL;
            free(node);
            //
            range = mergeNode(range, tailPre);
            range->next = tail;
            
            //释放中间节点
            while (head != NULL && head != tail) {
                node = head;
                free(head);
                head = node->next;
            }
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


SURangePointer SUGetGapRanges(SURangePointer links, SURangePointer node) {
    SURangePointer  head    = NULL;
    SURangePointer  tail    = NULL;
    SURangePointer  preTail = NULL;
    SURangePointer  tmp     = NULL;
    
    unsigned long long nodeStart = node->location;
    unsigned long long nodeEnd   = node->location + node->length - 1;
    
    head = links;
    while(NULL != head) {
        switch (SURangePositionInSource(node, head)) {
            case 5:
                tmp = malloc(sizeof(SURange));
                memcpy(tmp, node, sizeof(SURange));
                tmp->next = NULL;
                return tmp;
            case 4:
                return  NULL;
            case 3:
            case 2:
            case 1:
                break;
            default:
                head = head->next;
                continue;
        }
        break;
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
        tmp = malloc(sizeof(SURange));
        memcpy(tmp, node, sizeof(SURange));
        tmp->next = NULL;
        return tmp;
    }
    SURangePointer resultHead      = NULL;
    SURangePointer currentPointer  = NULL;
    tmp = NULL;
    
    switch (SURangePositionInSource(node, head)) {
        case 1:
            break;
        case 2:
        case 3:
            tmp = (SURangePointer)malloc(sizeof(SURange));
            tmp->location = nodeStart;
            tmp->length   = head->location - nodeStart;
            tmp->next     = NULL;
            resultHead    = tmp;
            break;
        case 4:
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
            tmp         = currentPointer;
            resultHead  = tmp;
        }else {
            tmp->next   = currentPointer;
            tmp         = currentPointer;
        }
        head = head->next;
    }
    
    
    switch (SURangePositionInSource(node, tail)) {
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
    if(start <= nodeStart && nodeStart <= end && end < nodeEnd) {
        return 1;
    }else if(start > nodeStart && end < nodeEnd) {
        return 2;
    }else if(nodeStart < start && start <= nodeEnd && nodeEnd <= end) {
        return 3;
    }else if(start <= nodeStart && end <= nodeEnd) {
        return 4;
    }
    return 0;
}

//判断target是否和src有交叉
int SURangePositionInSource(SURangePointer src, SURangePointer target) {
    if(NULL == src || target == NULL) { //无法判断
        return -2;
    }
    unsigned long long srcS   = src->location;
    unsigned long long srcE   = src->location + src->length - 1;
    
    unsigned long long targetS = target->location;
    unsigned long long targetE   = target->location + target->length - 1;
    
    if(targetE < srcS) { //在左边, 无交集
        return 0;
    }else if(targetS <= srcS && srcS <= targetE && targetE < srcE) { //右边空
        return 1;
    }else if(targetS <= srcS && targetE >= srcE) { //两头包
        return 4;
    }else if(srcS < targetS && targetE < srcE) {//两头空
        return 2;
    }else if(srcS < targetS && targetS <= srcE && srcE <= targetE) {//左边空
        return 3;
    }else if(srcE < targetS) { //在右边，无交集
        return -1;
    }
    return -3;
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
        range = malloc(sizeof(SURange));
        memcpy(range, node1, sizeof(SURange));
        range->next = NULL;
        node2->next = range;
        head = node2;
        free(node1);
    }else {
        unsigned long long  location = MIN(node2->location, node1->location);
        unsigned long long  offset   = MAX(node2->location + node2->length - 1, node1->location + node1->length - 1);
        range = (SURangePointer)malloc(sizeof(SURange));
        range->location = location;
        range->length   = offset - location + 1;
        range->next = NULL;
        head = range;
        free(node2);
        free(node1);
    }
    return head;
}

void SURangeFree(SURangePointer range) {
    while (range) {
        SURangePointer tmp = range;
        range = range->next;
        free(tmp);
        tmp = NULL;
    }
}

SURangePointer SUGetXRanges(SURangePointer src, SURangePointer target) {
    SURangePointer tmp = NULL;
    SURangePointer tmp1 = NULL;
    
    for(tmp = src; tmp; tmp = tmp->next) {
        if(tmp->location <= target->location && (target->location <= tmp->location+tmp->length - 1 )) {
        tmp1 = malloc(sizeof(SURange));
        tmp1->next = NULL;
        tmp1->location = target->location;
            unsigned long long offset = MIN(target->location + target->length - 1, tmp->location+tmp->length - 1 );
        tmp1->length   = offset - tmp1->location + 1;
        return tmp1;
        }
    }
    return NULL;
}

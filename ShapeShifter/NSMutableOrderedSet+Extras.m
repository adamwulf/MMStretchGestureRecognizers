//
//  NSMutableOrderedSet+Extras.m
//  jotuiexample
//
//  Created by Adam Wulf on 6/19/12.
//  Copyright (c) 2014 Milestone Made, LLC. All rights reserved.
//

#import "NSMutableOrderedSet+Extras.h"

@implementation NSMutableSet (Extras)

-(void) addObjectsInSet:(NSSet*)set{
    for(id obj in set){
        [self addObject:obj];
    }
}

-(void) removeObjectsInSet:(NSSet*)set{
    for(id obj in set){
        [self removeObject:obj];
    }
}

-(NSSet*) setByRemovingObject:(id)obj{
    NSMutableSet* ret = [NSMutableSet setWithSet:self];
    [ret removeObject:obj];
    return ret;
}

@end


@implementation NSMutableOrderedSet (Extras)

-(void) addObjectsInOrderedSet:(NSOrderedSet*)set{
    for(id obj in set){
        [self addObject:obj];
    }
}

-(void) addObjectsInSet:(NSSet*)set{
    for(id obj in set){
        [self addObject:obj];
    }
}

-(void) removeObjectsInSet:(NSSet*)set{
    for(id obj in set){
        [self removeObject:obj];
    }
}

-(NSOrderedSet*) setByRemovingObject:(id)obj{
    NSMutableOrderedSet* ret = [NSMutableOrderedSet orderedSetWithOrderedSet:self];
    [ret removeObject:obj];
    return ret;
}

@end

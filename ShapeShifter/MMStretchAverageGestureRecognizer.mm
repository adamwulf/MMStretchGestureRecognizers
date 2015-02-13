//
//  MMStretchGestureRecognizer.m
//  ShapeShifter
//
//  Created by Adam Wulf on 2/21/14.
//  Copyright (c) 2014 Milestone Made, LLC. All rights reserved.
//

#import "MMStretchAverageGestureRecognizer.h"
#import "Constants.h"
#import "NSMutableOrderedSet+Extras.h"
#import "MMVector.h"

// this will stretch and rotate the image
// so that the quad is always a convex quad
// regardless of the fingers' location.
// the image will also rotate as the fingers
// rotate on screen, so that the image seems
// to be held as you'd expect a physical object
// to be held.
@implementation MMStretchAverageGestureRecognizer


-(id) init{
    self = [super init];
    if(self){
        validTouches = [[NSMutableOrderedSet alloc] init];
        possibleTouches = [[NSMutableOrderedSet alloc] init];
        ignoredTouches = [[NSMutableSet alloc] init];
        self.delaysTouchesEnded = NO;
    }
    return self;
}

-(id) initWithTarget:(id)target action:(SEL)action{
    self = [super initWithTarget:target action:action];
    if(self){
        validTouches = [[NSMutableOrderedSet alloc] init];
        possibleTouches = [[NSMutableOrderedSet alloc] init];
        ignoredTouches = [[NSMutableSet alloc] init];
        self.delaysTouchesEnded = NO;
    }
    return self;
}

-(void) cancel{
    if(self.enabled){
        self.enabled = NO;
        self.enabled = YES;
    }
}

-(NSArray*) possibleTouches{
    return [possibleTouches array];
}

-(NSArray*) ignoredTouches{
    NSMutableArray* ret = [NSMutableArray array];
    for(NSObject* obj in ignoredTouches){
        [ret addObject:obj];
    }
    return ret;
}

-(NSArray*)validTouches{
    return [validTouches array];
}


#pragma mark - Quadrilateral

-(Quadrilateral) getQuad{
    return [self generateAverageQuadFor:[self getRawQuad]];
}

// this generates a Quadrilateral struct from the clockwise touch locations.
// note. the touches are only sorted at the beginning of the gesture. so this means
// that the touches are guaranteed form a clockwise quad only at the very beginning of
// the gesture, but the user can spin, flip, and mix their fingers to create self
// intersecting quads.
-(Quadrilateral) getRawQuad{
    __block Quadrilateral output;
    [[self validTouches] enumerateObjectsUsingBlock:^(UITouch* touch, NSUInteger idx, BOOL* stop){
        CGPoint location = [touch locationInView:self.view];
        if(idx == 0){
            output.upperLeft = location;
        }else if(idx == 1){
            output.upperRight = location;
        }else if(idx == 2){
            output.lowerRight = location;
        }else if(idx == 3){
            output.lowerLeft = location;
        }
    }];
    return output;
}

// if we use the getRawQuad only, then the transform we create by skewing that
// raw quad will manipulate dramatically in 3d. This transform ends up to give
// terrible results if the quad is manipulated by the user to be concave.
//
// this methods helps get around these awkward transforms by created an average of the
// user's finger positions instead of exact quad transforms.
//
// 1. find the midpoints along each edge of the quad.
// 2. find the vectors beteween opposite midpoints
// 3. create new quad endpoints using these vectors
// 4. this will create an output parallelogram from the input quad
-(Quadrilateral) generateAverageQuadFor:(Quadrilateral)q{
    Quadrilateral ret;
    
    CGPoint midLeft = CGPointMake((q.upperLeft.x + q.lowerLeft.x)/2, (q.upperLeft.y + q.lowerLeft.y)/2);
    CGPoint midRight = CGPointMake((q.upperRight.x + q.lowerRight.x)/2, (q.upperRight.y + q.lowerRight.y)/2);
    
    MMVector* lengthVector = [MMVector vectorWithPoint:midLeft andPoint:midRight];
    
    CGPoint midTop = CGPointMake((q.upperLeft.x + q.upperRight.x)/2, (q.upperLeft.y + q.upperRight.y)/2);
    CGPoint midLow = CGPointMake((q.lowerLeft.x + q.lowerRight.x)/2, (q.lowerLeft.y + q.lowerRight.y)/2);
    
    
    ret.upperLeft = [lengthVector pointFromPoint:midTop distance:-0.5];
    ret.upperRight = [lengthVector pointFromPoint:midTop distance:0.5];
    ret.lowerRight = [lengthVector pointFromPoint:midLow distance:0.5];
    ret.lowerLeft = [lengthVector pointFromPoint:midLow distance:-0.5];
    
    return ret;
}


// this method looks at our internal state for the gesture, and updates
// the UIGestureRecognizer.state to match
-(void) updateState{
    if([possibleTouches count] == 4){
        [validTouches addObjectsInOrderedSet:possibleTouches];
        [possibleTouches removeAllObjects];
        [self sortValidTouches];
    }else if([validTouches count] < 4){
        if(self.state != UIGestureRecognizerStatePossible){
            self.state = UIGestureRecognizerStateEnded;
        }
    }else{
        if(self.state == UIGestureRecognizerStatePossible){
            self.state = UIGestureRecognizerStateBegan;
        }else{
            self.state = UIGestureRecognizerStateChanged;
        }
    }
}

//
// this method takes all valid touches, and sorts them in the OrderedSet
// so that their touch locations are in clockwise order
-(void) sortValidTouches{
    __block CGPoint center = CGPointZero;
    [validTouches enumerateObjectsUsingBlock:^(UITouch* touch, NSUInteger idx, BOOL *stop){
        CGPoint location = [touch locationInView:self.view];
        center.x += location.x / [validTouches count];
        center.y += location.y / [validTouches count];
    }];
    [validTouches sortUsingComparator:^NSComparisonResult(UITouch* obj1, UITouch* obj2){
        CGPoint a = [obj1 locationInView:self.view];
        CGPoint b = [obj2 locationInView:self.view];
        
        // compute the cross product of vectors (center -> a) x (center -> b)
        int det = (a.x-center.x) * (b.y-center.y) - (b.x - center.x) * (a.y - center.y);
        if (det < 0)
            return NSOrderedAscending;
        if (det > 0)
            return NSOrderedDescending;
        
        // points a and b are on the same line from the center
        // check which point is closer to the center
        int d1 = (a.x-center.x) * (a.x-center.x) + (a.y-center.y) * (a.y-center.y);
        int d2 = (b.x-center.x) * (b.x-center.x) + (b.y-center.y) * (b.y-center.y);
        return d1 > d2 ? NSOrderedAscending : NSOrderedDescending;
    }];
}


#pragma mark - UIGestureRecognizer

- (BOOL)canPreventGestureRecognizer:(UIGestureRecognizer *)preventedGestureRecognizer{
    return NO;
}

- (BOOL)canBePreventedByGestureRecognizer:(UIGestureRecognizer *)preventingGestureRecognizer{
    return NO;
}

- (void)reset{
    [super reset];
    [validTouches removeAllObjects];
    [ignoredTouches removeAllObjects];
    [possibleTouches removeAllObjects];
}

-(void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    [touches enumerateObjectsUsingBlock:^(id touch, BOOL* stop){
        [possibleTouches addObject:touch];
    }];
    [self updateState];
}

-(void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
    [self updateState];
}

-(void) touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event{
    [touches enumerateObjectsUsingBlock:^(id touch, BOOL* stop){
        [possibleTouches removeObject:touch];
        [validTouches removeObject:touch];
        [ignoredTouches removeObject:touch];
    }];
    [self updateState];
}

-(void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    [touches enumerateObjectsUsingBlock:^(id touch, BOOL* stop){
        [possibleTouches removeObject:touch];
        [validTouches removeObject:touch];
        [ignoredTouches removeObject:touch];
    }];
    [self updateState];
}


#pragma mark - OpenCV Transform

// http://stackoverflow.com/questions/9470493/transforming-a-rectangle-image-into-a-quadrilateral-using-a-catransform3d

+ (CATransform3D)transformQuadrilateral:(Quadrilateral)origin toQuadrilateral:(Quadrilateral)destination {
    
    CvPoint2D32f *cvsrc = [self openCVMatrixWithQuadrilateral:origin];
    CvMat *src_mat = cvCreateMat( 4, 2, CV_32FC1 );
    cvSetData(src_mat, cvsrc, sizeof(CvPoint2D32f));
    
    CvPoint2D32f *cvdst = [self openCVMatrixWithQuadrilateral:destination];
    CvMat *dst_mat = cvCreateMat( 4, 2, CV_32FC1 );
    cvSetData(dst_mat, cvdst, sizeof(CvPoint2D32f));
    
    CvMat *H = cvCreateMat(3,3,CV_32FC1);
    cvFindHomography(src_mat, dst_mat, H);
    cvReleaseMat(&src_mat);
    cvReleaseMat(&dst_mat);
    
    CATransform3D transform = [self transform3DWithCMatrix:H->data.fl];
    cvReleaseMat(&H);
    
    return transform;
}

+ (CvPoint2D32f *)openCVMatrixWithQuadrilateral:(Quadrilateral)origin {
    
    CvPoint2D32f *cvsrc = (CvPoint2D32f *)malloc(4*sizeof(CvPoint2D32f));
    cvsrc[0].x = origin.upperLeft.x;
    cvsrc[0].y = origin.upperLeft.y;
    cvsrc[1].x = origin.upperRight.x;
    cvsrc[1].y = origin.upperRight.y;
    cvsrc[2].x = origin.lowerRight.x;
    cvsrc[2].y = origin.lowerRight.y;
    cvsrc[3].x = origin.lowerLeft.x;
    cvsrc[3].y = origin.lowerLeft.y;
    return cvsrc;
}

+ (CATransform3D)transform3DWithCMatrix:(float *)matrix {
    CATransform3D transform = CATransform3DIdentity;
    
    transform.m11 = matrix[0];
    transform.m21 = matrix[1];
    transform.m41 = matrix[2];
    
    transform.m12 = matrix[3];
    transform.m22 = matrix[4];
    transform.m42 = matrix[5];
    
    transform.m14 = matrix[6];
    transform.m24 = matrix[7];
    transform.m44 = matrix[8];
    
    return transform;
}



@end

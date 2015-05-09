//
//  MMShapeViewController.m
//  ShapeShifter
//
//  Created by Adam Wulf on 2/21/14.
//  Copyright (c) 2014 Milestone Made, LLC. All rights reserved.
//

#import "MMShapeViewController.h"
#import "MMDebugQuadrilateralView.h"
#import "MMStretchExactGestureRecognizer.h"
#import "MMStretchAverageGestureRecognizer.h"
#import "MMStretchOrientationGestureRecognizer.h"
#import "UIView+AnchorPoint.h"
#import "Constants.h"

@implementation MMShapeViewController{
    MMDebugQuadrilateralView* debugView;
    UIImageView* draggable;
    MMStretchExactGestureRecognizer* gesture1;
    MMStretchAverageGestureRecognizer* gesture2;
    MMStretchOrientationGestureRecognizer* gesture3;
    
    CGPoint adjust;
    Quadrilateral firstQ;
    CATransform3D startTransform;

    UILabel* convexLabel;
}

const int INDETERMINANT = 0;
const int CONCAVE = -1;
const int CONVEX = 1;
const int COLINEAR = 0;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // control to choose
    // choose the gesture to use
    UISegmentedControl* gestureChooser = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"exact", @"average", @"oriented", nil]];
    [gestureChooser addTarget:self action:@selector(chooseGesture:) forControlEvents:UIControlEventValueChanged];
    gestureChooser.frame = CGRectMake(100, 50, 300, 50);
    gestureChooser.selectedSegmentIndex = 1;
    //
    // this label will tell us if the points we're using to
    // calculate the transform are concave or convex
    convexLabel = [[UILabel alloc] initWithFrame:CGRectMake(110, 105, 120, 30)];
    convexLabel.backgroundColor = [UIColor whiteColor];

    // this view draws the quad we're using for the transform in red,
    // and draws an 'average' quad in green
    debugView = [[MMDebugQuadrilateralView alloc] initWithFrame:self.view.bounds];
    

    draggable = [[UIImageView alloc] initWithFrame:CGRectMake(100, 300, 300, 200)];
    draggable.contentMode = UIViewContentModeScaleAspectFill;
    draggable.image = [UIImage imageNamed:@"space.jpg"];
    // we're going to add a transform to the view that
    // we're stretching, to prove to ourselves that we can
    // play nice with any existing transform on the view
    draggable.transform = CGAffineTransformConcat(CGAffineTransformMakeRotation(M_PI / 4),CGAffineTransformMakeScale(1.2, 1.2));

    gesture1 = [[MMStretchExactGestureRecognizer alloc] initWithTarget:self action:@selector(didStretch:)];
    gesture2 = [[MMStretchAverageGestureRecognizer alloc] initWithTarget:self action:@selector(didStretch:)];
    gesture3 = [[MMStretchOrientationGestureRecognizer alloc] initWithTarget:self action:@selector(didStretch:)];
    [self.view addGestureRecognizer:gesture1];
    [self.view addGestureRecognizer:gesture2];
    [self.view addGestureRecognizer:gesture3];
    self.view.userInteractionEnabled = YES;
    
    [self.view addSubview:draggable];
    
    [self.view addSubview:debugView];
    [self.view addSubview:convexLabel];
    [self.view addSubview:gestureChooser];
    
    [self chooseGesture:gestureChooser];
}

-(void) chooseGesture:(UISegmentedControl*)control{
    if(control.selectedSegmentIndex == 0){
        gesture1.enabled = YES;
        gesture2.enabled = NO;
        gesture3.enabled = NO;
    }else if(control.selectedSegmentIndex == 1){
        gesture1.enabled = NO;
        gesture2.enabled = YES;
        gesture3.enabled = NO;
    }else if(control.selectedSegmentIndex == 2){
        gesture1.enabled = NO;
        gesture2.enabled = NO;
        gesture3.enabled = YES;
    }else if(control.selectedSegmentIndex == 3){
        gesture1.enabled = NO;
        gesture2.enabled = NO;
        gesture3.enabled = NO;
    }
}

-(void) updateLabelFor:(Quadrilateral)q2{
    NSString* text = @"co-linear";
    CGPoint points[4];
    points[0] = q2.upperLeft;
    points[1] = q2.upperRight;
    points[2] = q2.lowerRight;
    points[3] = q2.lowerLeft;
    
    int convexTest = Convex(points);
    if(convexTest == CONVEX){
        text = @"convex";
    }else if(convexTest == CONCAVE){
        text = @"concave";
    }else{
        text = @"co-linear";
    }
    
    convexLabel.text = text;
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



-(void) didStretch:(MMStretchExactGestureRecognizer*)gesture{
    
    // first, set our anchor point to 0,0 if we're
    // beginning the gesture
    if(gesture.state == UIGestureRecognizerStateBegan){
        [UIView setAnchorPoint:CGPointMake(0, 0) forView:draggable];
        adjust =  [draggable convertPoint:draggable.bounds.origin toView:self.view];
    }

    Quadrilateral quadForHandShadows = [gesture getExactQuad];
    
    // calculate the rotation of the gesture.
    // we can use the angle when the gesture ends to
    // set a standard 2d transform if we'd like
    CGFloat angle = [(NSNumber *)[draggable valueForKeyPath:@"layer.transform.rotation.z"] floatValue];
    if(gesture.state == UIGestureRecognizerStateBegan){
        firstQ = [gesture getQuad];
        startTransform = draggable.layer.transform;
        DebugLog(@"begin angle: %f", angle); // 0.020000
    }else if(gesture.state == UIGestureRecognizerStateCancelled){
        draggable.layer.transform = startTransform;
        DebugLog(@"cancelled angle: %f", angle); // 0.020000
    }else if(gesture.state == UIGestureRecognizerStateChanged){
        Quadrilateral secondQ = [gesture getQuad];

        [self updateLabelFor:secondQ];
        [debugView setQuadrilateral:secondQ];

        // we want the transformed quad and our transformed view
        // to each begin at the exact same point.
        Quadrilateral q1 = [self translateQuad:firstQ by:adjust];
        Quadrilateral q2 = [self translateQuad:secondQ by:adjust];
        
        // generate the actual transform between the two quads
        CATransform3D skewTransform = [MMStretchExactGestureRecognizer transformQuadrilateral:q1 toQuadrilateral:q2];
        
        // we can watch these scales to see how different
        // the x vs y scales are. if they are extremely different,
        // then that will look like a very stretched image.
        //
        // it's a stretch if x or y is larger than its value at the
        // beginning. it's a squish if its smaller than it's value.
        //
        // to find the stretch over x and y, we need to undo the rotation
        // of the transform.
        CATransform3D transformForScale = CATransform3DRotate(skewTransform, -angle, 0, 0, 1);
        CGFloat scalex = sqrtf((transformForScale.m11 * transformForScale.m11 ) +
                               (transformForScale.m12 * transformForScale.m12) +
                               (transformForScale.m13 * transformForScale.m13));
        CGFloat scaley = sqrtf((transformForScale.m21 * transformForScale.m21 ) +
                               (transformForScale.m22 * transformForScale.m22) +
                               (transformForScale.m23 * transformForScale.m23));
        DebugLog(@"scales: %f %f and rotation: %f", scalex, scaley, angle);
        
        draggable.layer.transform = CATransform3DConcat(startTransform, skewTransform);
    }else if(gesture.state == UIGestureRecognizerStateEnded){
        draggable.layer.transform = startTransform;
        DebugLog(@"ended angle: %f", angle); // 0.020000
    }else if(gesture.state == UIGestureRecognizerStateFailed){
        draggable.layer.transform = startTransform;
        DebugLog(@"failed angle: %f", angle); // 0.020000
    }else if(gesture.state == UIGestureRecognizerStatePossible){
        draggable.layer.transform = startTransform;
    }
    
    // if we've ended the gesture, then move our
    // anchor back to 0.5,0.5
    if(gesture.state == UIGestureRecognizerStateCancelled ||
       gesture.state == UIGestureRecognizerStateEnded ||
       gesture.state == UIGestureRecognizerStateFailed){
        
        [UIView setAnchorPoint:CGPointMake(.5, .5) forView:draggable];
    }
    
    
    
    NSArray* rightHandTouches = @[[NSValue valueWithCGPoint:quadForHandShadows.lowerLeft],
                                  [NSValue valueWithCGPoint:quadForHandShadows.upperLeft]];
    NSArray* leftHandTouches = @[[NSValue valueWithCGPoint:quadForHandShadows.lowerRight],
                                  [NSValue valueWithCGPoint:quadForHandShadows.upperRight]];
    if(distanceBetweenPoints(quadForHandShadows.lowerLeft, quadForHandShadows.upperLeft) >
       distanceBetweenPoints(quadForHandShadows.lowerLeft, quadForHandShadows.lowerRight)){
        // rotate so that we match fingers to closer touches
        rightHandTouches = @[[NSValue valueWithCGPoint:quadForHandShadows.lowerLeft],
                             [NSValue valueWithCGPoint:quadForHandShadows.lowerRight]];
        leftHandTouches = @[[NSValue valueWithCGPoint:quadForHandShadows.upperLeft],
                            [NSValue valueWithCGPoint:quadForHandShadows.upperRight]];
    }
}

// translate the quad by the input point amount
-(Quadrilateral) translateQuad:(Quadrilateral)a by:(CGPoint)p{
    Quadrilateral output = a;
    output.upperLeft.x -= p.x;
    output.upperLeft.y -= p.y;
    output.upperRight.x -= p.x;
    output.upperRight.y -= p.y;
    output.lowerRight.x -= p.x;
    output.lowerRight.y -= p.y;
    output.lowerLeft.x -= p.x;
    output.lowerLeft.y -= p.y;
    
    return output;
}





/*
 Return whether a polygon in 2D is concave or convex
 return 0 for incomputables eg: colinear points
 CONVEX == 1
 CONCAVE == -1
 It is assumed that the polygon is simple
 (does not intersect itself or have holes)
 
 http://paulbourke.net/geometry/polygonmesh/source2.c
 */
int Convex(CGPoint p[4])
{
    int len = 4;
    int i,j,k;
    int flag = 0;
    double z;
    
    for (i=0;i<len;i++) {
        j = (i + 1) % len;
        k = (i + 2) % len;
        z  = (p[j].x - p[i].x) * (p[k].y - p[j].y);
        z -= (p[j].y - p[i].y) * (p[k].x - p[j].x);
        if (z == 0){
            return(COLINEAR);
        }else if (z < 0){
            flag |= 1;
        }else if (z > 0){
            flag |= 2;
        }
        if (flag == 3){
            return(CONCAVE);
        }
    }
    if (flag != 0)
        return(CONVEX);
    else
        return(0);
}

static CGFloat distanceBetweenPoints(const CGPoint p1, const CGPoint p2) {
    CGFloat dist = sqrt(pow(p2.x - p1.x, 2) + pow(p2.y - p1.y, 2));
    return dist;
}

@end

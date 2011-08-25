//
//  DnDOverlayView.m
//  testDragAndDrop
//
//  Created by Joshua Foster on 8/16/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "DnDOverlayView.h"

#import <QuartzCore/QuartzCore.h>

#import "DnDManager.h"
#import "DnDProtocols.h"

// This class holds the state of an in-progress drag.

@interface DragOperation : NSObject {
    UIView* draggable;                      // Item being dragged
    UIView<DragSource>* dragSource;         // Item from which drag originated
    CGPoint initialPoint;                   // Point of initial touch
    
    UIView<DropTarget>* currentDropTarget;  // Drop target the draggable item is hovering over (if any)
    
    BOOL dropAnimationInProgress;           // Whether a drop (or return to start) animation is in progress
}

@property (nonatomic, readonly) UIView* draggable;
@property (nonatomic, readonly) UIView<DragSource>* dragSource;
@property (nonatomic, readonly) CGPoint initialPoint;
@property (nonatomic, assign) UIView<DropTarget>* currentDropTarget;
@property (nonatomic, assign) BOOL dropAnimationInProgress;

- (id)initWithDraggable:(UIView*)view dragSource:(UIView*)source initialPoint:(CGPoint)point;

@end


@implementation DragOperation

@synthesize draggable, dragSource, initialPoint, currentDropTarget, dropAnimationInProgress;

- (id)initWithDraggable:(UIView*)view dragSource:(UIView*)source initialPoint:(CGPoint)point {
    if(( self = [super init] )) {
        draggable = view;
        dragSource = source;
        initialPoint = point;
    }
    return self;
}

@end

////////////////////////////////////////////////////////////////////////////////////////

@interface DnDOverlayView(Private)

- (void)setHighlight:(BOOL)highlight onDropTarget:(UIView<DropTarget>*)dropTarget;
- (void)notifyDraggableEntered:(UIView<DropTarget>*)target atPoint:(CGPoint)point;
- (void)animateDropOn:(UIView<DropTarget>*)dropTarget atPoint:(CGPoint)point withDuration:(float)duration;
    
@end

@implementation DnDOverlayView

@synthesize dragModeActive;

- (id)initWithCoder:(NSCoder *)aDecoder {
    if(( self = [super initWithCoder:aDecoder] )) {
        self.backgroundColor = [UIColor clearColor];
        dragSources = [[NSMutableArray alloc] init];
        dropTargets = [[NSMutableArray alloc] init];
        dragModeViews = [[NSMutableArray alloc] init];
        
        // Register ourselves with the singleton.
        [[DnDManager instance] registerDnDOverlay:self withId:@"testDND"];
        
        // We don't want to intercept touch events until drag-and-drop mode is enabled.
        self.userInteractionEnabled = NO;
    }
    return self;
}

- (void)dealloc {
    [dragSources release];
    [dropTargets release];
    [dragModeViews release];
    [super dealloc];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/


#pragma mark -

- (void)registerDnDItem:(id)item {
    // Add the item to the approriate arrays based on what protocols it implements.
    if( [item conformsToProtocol:@protocol(DragSource)] ) [dragSources addObject:item];
    if( [item conformsToProtocol:@protocol(DropTarget)] ) [dropTargets addObject:item];
    if( [item conformsToProtocol:@protocol(DragModeView)] ) [dragModeViews addObject:item];
    
    NSLog( @"%d drag sources / %d drop targets registered", [dragSources count], [dropTargets count] );
}

- (void)deregisterDnDItem:(id)item {
    if( [item conformsToProtocol:@protocol(DragSource)] ) [dragSources removeObject:item];
    if( [item conformsToProtocol:@protocol(DropTarget)] ) [dropTargets removeObject:item];
    if( [item conformsToProtocol:@protocol(DragModeView)] ) [dragModeViews removeObject:item];
    
    NSLog( @"%d drag sources / %d drop targets registered", [dragSources count], [dropTargets count] );
}

- (void)setDragModeActive:(BOOL)isActive {
    dragModeActive = isActive;
    self.userInteractionEnabled = isActive;
    if( isActive ) NSLog( @"Drag mode %@ACTIVATED!", isActive ? @"" : @"DE" );
    
    for( id<DragModeView> dragModeView in dragModeViews ) {
        [dragModeView setDragModeActive:isActive];
    }
}

- (void)notifyDraggableEntered:(UIView<DropTarget>*)target atPoint:(CGPoint)point {
    dragOperation.currentDropTarget = target;
    [self setHighlight:YES onDropTarget:target];
    [target draggable:dragOperation.draggable enteredAtPoint:point];
}


#pragma mark - Touch handling

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    NSLog( @"BEGAN" );
    UITouch* touch = [touches anyObject];
    BOOL inDragSource = NO;
    
    // Was the touch over a drag source?
    for( UIView<DragSource>* dragSource in dragSources ) {
        CGPoint point = [touch locationInView:dragSource];
        if( CGRectContainsPoint( dragSource.bounds, point )) {
            NSLog( @"Detected touch inside drag source!!!" );
            inDragSource = YES;

            // Ask the drag source for a draggable
            UIView* draggable = [[dragSource popItemForDragFrom:point] retain];
            if( draggable != nil ) {
                NSLog( @"Start drag on thing: %@", draggable );
                dragOperation = [[DragOperation alloc] initWithDraggable:draggable dragSource:dragSource initialPoint:draggable.center];
                
                // Unattach the draggable from its parent view and attach it to the overlay view, using the touch
                // location as the center point.
                [self addSubview:draggable];
                draggable.center = [self convertPoint:draggable.center fromView:dragSource];
                draggable.layer.masksToBounds = NO;
                draggable.layer.cornerRadius = 8;
                draggable.layer.shadowOffset = CGSizeMake( 7, 7 );
                draggable.layer.shadowRadius = 5;
                draggable.layer.shadowOpacity = 0.5;
                
                [UIView animateWithDuration:0.1f animations:^{
                    draggable.center = [touch locationInView:self];
                    draggable.transform = CGAffineTransformMakeScale( 1.2f, 1.2f );
                }];
                
                // If the drag source is also a drop target, tell it the draggable is hovering over it.
                if( [dragSource conformsToProtocol:@protocol(DropTarget)] ) {
                    [self notifyDraggableEntered:(UIView<DropTarget>*)dragSource atPoint:point];
                }
                
                return;
            }
        }
    }
    
    // The user touched outside of the draggable areas, disable drag mode.
    if( !inDragSource ) self.dragModeActive = NO;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    if( dragOperation == nil ) return;

    UITouch* touch = [touches anyObject];
    dragOperation.draggable.center = [touch locationInView:self];
    
    // If we have a current drop target, see if we're still over it.
    if( dragOperation.currentDropTarget != nil ) {
        CGPoint point = [touch locationInView:dragOperation.currentDropTarget];
        if( CGRectContainsPoint( dragOperation.currentDropTarget.bounds, point )) {
            [dragOperation.currentDropTarget draggable:dragOperation.draggable hoveringAtPoint:point];
            return;
        }
        else {
            // We've moved out of this drop target.
            NSLog( @"... moved OUT of previous drop target" );
            [self setHighlight:NO onDropTarget:dragOperation.currentDropTarget];
            [dragOperation.currentDropTarget draggableExited:dragOperation.draggable];
            dragOperation.currentDropTarget = nil;
        }
    }
    
    // Ok, now see if we're over _another_ drop target
    for( UIView<DropTarget>* dropTarget in dropTargets ) {
        if( ![dropTarget acceptsDraggable:dragOperation.draggable] ) continue;
              
        CGPoint point = [touch locationInView:dropTarget];
        if( CGRectContainsPoint( dropTarget.bounds, point )) {
            NSLog( @"Detected drag into drop target!!!" );
            [self notifyDraggableEntered:dropTarget atPoint:point];
        }
    }
}

// Animate the draggable to its proper dropped location... AFTER the animation is
// complete will we do the actual drop.
- (void)animateDropOn:(UIView<DropTarget>*)dropTarget atPoint:(CGPoint)point withDuration:(float)duration {
    [UIView animateWithDuration:duration
    animations:^(void) {
        dragOperation.dropAnimationInProgress = YES;
        dragOperation.draggable.center = [self convertPoint:point fromView:dropTarget];
        dragOperation.draggable.transform = CGAffineTransformIdentity;
    }
     completion:^(BOOL finished) {
         [dropTarget draggable:dragOperation.draggable droppedAtPoint:point];
         dragOperation.dropAnimationInProgress = NO;
         [dragOperation.draggable removeFromSuperview];
         [dragOperation release];
         dragOperation = 0;
     }];

}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if( dragOperation == nil ) return;
    
    UITouch* touch = [touches anyObject];
    
    [self setHighlight:NO onDropTarget:dragOperation.currentDropTarget];
    
    // If we have a current drop target, drop the draggable there
    if( dragOperation.currentDropTarget != nil ) {
        NSLog( @"Transferring draggable to drop target!" );
        CGPoint point = [touch locationInView:dragOperation.currentDropTarget];
        
        CGPoint adjustedPoint = [dragOperation.currentDropTarget actualDropPointForLocation:point];
        [self animateDropOn:dragOperation.currentDropTarget atPoint:adjustedPoint withDuration:0.1f];
    }
    else {
        // If the original drag source is also a drop target, put the draggable back in its
        // original spot.
        if( [dragOperation.dragSource conformsToProtocol:@protocol(DropTarget)] ) {
            NSLog( @"Transferring draggable back to source" );
            [self animateDropOn:(UIView<DropTarget>*)dragOperation.dragSource atPoint:dragOperation.initialPoint withDuration:0.3f];
        }
        else {
            // Otherwise, just kill it?
            NSLog( @"Killing draggable, nobody wants it :-(" );
            [dragOperation.draggable removeFromSuperview];
            [dragOperation release];
            dragOperation = 0;
        }
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    // Sigh... sometimes, for a really fast touch/release sequence, touchesCancelled is called instead of
    // the usual touchesBegan/touchesEnded. So handle that possibility here.
    if( dragOperation != nil && !dragOperation.dropAnimationInProgress ) {
        [self touchesEnded:touches withEvent:event];
    }

}

#pragma mark - Highlighting

// Highlight a drag target to give the user visual feedback that it is a valid drop location.
- (void)setHighlight:(BOOL)highlight onDropTarget:(UIView<DropTarget>*)dropTarget {
    if( highlight ) {
        dropTarget.layer.cornerRadius = 10;
        dropTarget.layer.borderWidth = 5;
        dropTarget.layer.borderColor = [UIColor yellowColor].CGColor;
    }
    else {
        dropTarget.layer.cornerRadius = 0;
        dropTarget.layer.borderWidth = 0;
    }
}


@end

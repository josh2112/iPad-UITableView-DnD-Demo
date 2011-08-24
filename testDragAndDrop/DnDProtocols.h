//
//  DnDProtocols.h
//  testDragAndDrop
//
//  Created by Joshua Foster on 8/18/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

// Any UIView that wants to be a draggable, or a source of draggable objects, should implement this protocol.

@protocol DragSource <NSObject>

// Tells the DragSource the user is initiating a drag at the given point.  Should return itself or
// another item to be dragged.
- (UIView*)popItemForDragFrom:(CGPoint)point;

@end


// Any UIView that wants to accept dropped items should implement this protocol.

@protocol DropTarget <NSObject>

// Asks the DropTarget if it can accept this draggable.
- (BOOL)acceptsDraggable:(UIView*)draggable;

// Asks the DropTarget to return the location (center point) where this item will
// be placed when dropped.
- (CGPoint)actualDropPointForLocation:(CGPoint)point;

// Notifies the DropTarget that a draggable has entered its bounds.
- (void)draggable:(UIView*)draggable enteredAtPoint:(CGPoint)point;

// Notifies the DropTarget that a draggable has moved within its bounds.
- (void)draggable:(UIView*)draggable hoveringAtPoint:(CGPoint)point;

// Notifies the DropTarget that a draggable has exited its bounds.
- (void)draggableExited:(UIView*)draggable;

// Notifies the DropTarget that a draggable has been dropped.
- (void)draggable:(UIView*)draggable droppedAtPoint:(CGPoint)point;

@end


// This is a protocol for objects that want to be notified when drag-and-drop mode
// is activated or deactivated.

@protocol DragModeView <NSObject>

// Notifies the object that drag mode has been turned on or off
- (void)setDragModeActive:(BOOL)active;

@end
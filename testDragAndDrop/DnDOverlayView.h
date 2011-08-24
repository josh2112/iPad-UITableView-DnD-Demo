//
//  DnDOverlayView.h
//  testDragAndDrop
//
//  Created by Joshua Foster on 8/16/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol DragModeView;
@protocol DragSource, DropTarget;

@class DragOperation;

// This is an invisible UIView that goes over all the drag and drop items.  It handles
// the actual DnD functionality - detecting a touch on a draggable item and detaching it
// from its parent view, moving the draggable item in response to finger movement,
// notifying drop targets when the draggable item is over top of them, and dropping
// the item on a target.

@interface DnDOverlayView : UIView {
    NSMutableArray* dragSources;
    NSMutableArray* dropTargets;
    NSMutableArray* dragModeViews;
    
    DragOperation* dragOperation;
    
    BOOL dragModeActive;
}

@property (nonatomic, assign) BOOL dragModeActive;

// Registers a drag source or drop target.
- (void)registerDnDItem:(id)item;

// Deregisters a drag source or drop target.
- (void)deregisterDnDItem:(id)item;

@end

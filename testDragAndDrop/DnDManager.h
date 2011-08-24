//
//  DnDManager.h
//  testDragAndDrop
//
//  Created by Joshua Foster on 8/18/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DnDOverlayView;

// When draggable items and droppable areas are created, they must register with their
// associated DnDOverlayView.  DragSouces/DropTargets use this Singleton class to do
// that - it finds a matching DnD overlay view by ID and does the registration. If, by
// chance, the DnDOverlayView hasn't been created yet at the time of registration, the
// request is cached and performed when the overlay view does get created.

@interface DnDManager : NSObject {
    NSMutableDictionary* dndOverlaysById;    
    NSMutableDictionary* registrationQueueById;
}

// Gets the Singleton instance of the DnDManager.
+ (DnDManager*)instance;

// Used by a DnDOverlayView to make itself available to draggable and droppable items.
- (void)registerDnDOverlay:(DnDOverlayView*)overlayView withId:(NSString*)overlayId;

// Registers a DragSource/DropTarget to a specific overlay view.
- (void)registerDnDItem:(id)item withOverlayId:(NSString*)overlayId;

// Deregisters a DragSource/DropTarget from a specific overlay view.
- (void)deregisterDnDItem:(id)item fromOverlayId:(NSString*)overlayId;

// Allows an external component (UIButton, etc.) to activate drag mode.
- (void)activateDragModeForOverlayId:(NSString*)overlayId;

@end

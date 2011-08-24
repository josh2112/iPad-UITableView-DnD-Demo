//
//  DragDropDemoTable2.h
//  testDragAndDrop
//
//  Created by Joshua Foster on 8/18/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "DnDProtocols.h"

// Drag-drop demo table 2.  It's both a drag source (allowing cells to be picked up and dragged) and a drop target (allowing
// cells to be dropped).  It has slightly different hover behavior than the other demo table - it resizes itself to accomodate
// the dropped cell.  Additionally, it uses a long-press gesture recognizer to enable drag-and-drop mode.

@interface DragDropDemoTable2 : UITableView <UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate, DragSource, DropTarget> {
    NSMutableArray* items;

    NSIndexPath* hoveringIndexPath;
}

@end

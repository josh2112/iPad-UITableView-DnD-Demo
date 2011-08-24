//
//  DragDropDemoTable1.h
//  testDragAndDrop
//
//  Created by Joshua Foster on 8/18/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "DnDProtocols.h"

// Drag-drop demo table 1.  It's both a drag source (allowing cells to be picked up and dragged) and a drop target (allowing
// cells to be dropped).

@interface DragDropDemoTable1 : UITableView <UITableViewDelegate, UITableViewDataSource, DragSource, DropTarget, DragModeView> {
    NSMutableArray* items;
    
    NSIndexPath* hoveringIndexPath;
}

@end

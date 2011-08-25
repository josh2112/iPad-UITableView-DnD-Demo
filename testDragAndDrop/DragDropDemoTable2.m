//
//  DragDropDemoTable2.m
//  testDragAndDrop
//
//  Created by Joshua Foster on 8/18/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "DragDropDemoTable2.h"

#import "DnDManager.h"


@interface DragDropDemoTable2 (Private)

- (int)rowAtPoint:(CGPoint)point;
- (void)animateHeightChange:(int)newHeight;

@end


@implementation DragDropDemoTable2

- (id)initWithCoder:(NSCoder *)aDecoder {
    if(( self = [super initWithCoder:aDecoder] )) {
        self.delegate = self;
        self.dataSource = self;
        items = [[NSMutableArray alloc] initWithObjects:@"1", @"2", nil];
        
        [self addGestureRecognizer:[[[UILongPressGestureRecognizer alloc] initWithTarget:self
                         action:@selector(longPressDetected:)] autorelease]];
        
        // Register ourselves with the DnD overlay.
        [[DnDManager instance] registerDnDItem:self withOverlayId:@"testDND"];
    }
    return self;
}

- (void)dealloc {
    [[DnDManager instance] deregisterDnDItem:self fromOverlayId:@"testDND"];
    [items release];
    [super dealloc];
}

// Return the row number corresponding to a point in the table's bounds.
// If no row is under the point, return a row number one past the end.
- (int)rowAtPoint:(CGPoint)point {
    NSIndexPath* newIndexPath = [self indexPathForRowAtPoint:point];
    return newIndexPath == nil ? [items count] : newIndexPath.row;
}

#pragma mark - Table delegate methods

- (int)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [items count];
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell* cell = [self dequeueReusableCellWithIdentifier:@"DragDestinationCell"];
    if( cell == nil ) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DragDestinationCell"];
    
    cell.textLabel.text = [items objectAtIndex:indexPath.row];
    cell.textLabel.textColor = [UIColor whiteColor];
    
    return cell;
}

#pragma mark - UIGestureRecognizer methods

- (void)longPressDetected:(id)sender {
    if( ((UIGestureRecognizer*)sender).state == UIGestureRecognizerStateBegan ) {
        // Long press detected, activate drag mode!    
        [[DnDManager instance] activateDragModeForOverlayId:@"testDND"];
    }
}

#pragma mark - DragSource methods

- (UIView*)popItemForDragFrom:(CGPoint)point {
    // Find the cell under the touch point.
    NSIndexPath* indexPath = [self indexPathForRowAtPoint:point];
    UITableViewCell* cell = [self cellForRowAtIndexPath:indexPath];
    if( cell == nil ) return nil;
    
    // Return a copy of the cell, then delete the cell from the table.
    //
    // We can't just return the cell itself, because it'll still be controlled by the table while
    // the delete animation is going on. So we create & return a copy instead.
    
    UITableViewCell* cellCopy = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DragDestinationCell"] autorelease];
    cellCopy.textLabel.text = cell.textLabel.text;
    cellCopy.textLabel.textColor = cell.textLabel.textColor;
    cellCopy.backgroundColor = cell.backgroundColor;
    cellCopy.frame = cell.frame;
    
    [items removeObjectAtIndex:indexPath.row];
    [self deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    
    return cellCopy;
}

#pragma mark - DropTarget methods

// This gives you a chance to filter what type of draggable objects you accept.
- (BOOL)acceptsDraggable:(UIView *)draggable {
    return YES;
}

// Returns the center of the table row where an item hovered at this point would be dropped.
- (CGPoint)actualDropPointForLocation:(CGPoint)point {
    int row = [self rowAtPoint:point];
    // If the point is past the last cell, return the rectangle of the last cell (which
    // will be the placeholder)
    if( row >= [items count] ) row = [items count] -1;
    
    CGRect rowRect = [self rectForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];
    return CGPointMake( CGRectGetMidX( rowRect ), CGRectGetMidY( rowRect ));
}

// Animate a table height change, using the "allow user interaction" option so dragging
// doesn't freeze.
- (void)animateHeightChange:(int)newHeight {
    [UIView animateWithDuration:0.3f delay:0 options:UIViewAnimationOptionAllowUserInteraction
    animations:^(void) {
        CGRect frame = self.frame;
        frame.size.height = newHeight;
        self.frame = frame;
    }
    completion:^(BOOL finished) {}];
}

// Insert a placeholder at the appropriate row to show where the draggable would
// be dropped.
- (void)draggable:(UIView *)draggable enteredAtPoint:(CGPoint)point {
    int row = [self rowAtPoint:point];
    
    NSLog( @"Inserting fake object at row %d", row );
    
    [items insertObject:@"[placeholder]" atIndex:row];
    NSIndexPath* newIndexPath = [NSIndexPath indexPathForRow:row inSection:0];
    [self insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
    
    hoveringIndexPath = [newIndexPath retain];
    
    // Expand the table to fit the new item.
    [self animateHeightChange:[self rectForSection:0].size.height];
}

// Move the placeholder if necessary.
- (void)draggable:(UIView*)draggable hoveringAtPoint:(CGPoint)point {
    int row = [self rowAtPoint:point];
    // If row is past the last cell, use the last cell (because we don't want to add a new cell,
    // just remove the existing placeholder to the end)
    if( row >= [items count] ) row = [items count]-1;
    
    // If the draggable is still over the same row, do nothing.  If it's moved up or down, move the
    // placeholder to the appropriate row.
    if( row != hoveringIndexPath.row ) {
        [items removeObjectAtIndex:hoveringIndexPath.row];
        [self deleteRowsAtIndexPaths:[NSArray arrayWithObject:hoveringIndexPath] withRowAnimation:UITableViewRowAnimationFade];
        
        [items insertObject:@"[placeholder]" atIndex:row];
        NSIndexPath* newIndexPath = [NSIndexPath indexPathForRow:row inSection:0];
        [self insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
        
        [hoveringIndexPath autorelease];
        hoveringIndexPath = [newIndexPath retain];
    }
}

// Get rid of the placeholder and shrink the table to its previous height.
- (void)draggableExited:(UIView*)draggable {
    [items removeObjectAtIndex:hoveringIndexPath.row];
    [self deleteRowsAtIndexPaths:[NSArray arrayWithObject:hoveringIndexPath] withRowAnimation:UITableViewRowAnimationFade];
    [hoveringIndexPath autorelease];
    hoveringIndexPath = nil;
    
    [self animateHeightChange:[self rectForSection:0].size.height];
}

// Remove the placeholder and insert the dragged item.
- (void)draggable:(UIView*)draggable droppedAtPoint:(CGPoint)point {
    if( hoveringIndexPath != nil ) {
        [items removeObjectAtIndex:hoveringIndexPath.row];
        [self deleteRowsAtIndexPaths:[NSArray arrayWithObject:hoveringIndexPath] withRowAnimation:UITableViewRowAnimationFade];
        
        [hoveringIndexPath autorelease];
        hoveringIndexPath = nil;
    }
    
    int row = [self rowAtPoint:point];
    
    NSLog( @"Dropping object at row %d", row );
    
    UITableViewCell* draggedCell = (UITableViewCell*)draggable;
    [items insertObject:draggedCell.textLabel.text atIndex:row];
    
    [self insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:row inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
}


@end

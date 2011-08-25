//
//  DragDropDemoTable1.m
//  testDragAndDrop
//
//  Created by Joshua Foster on 8/18/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "DragDropDemoTable1.h"

#import "DnDManager.h"

@implementation DragDropDemoTable1

- (id)initWithCoder:(NSCoder *)aDecoder {
    if(( self = [super initWithCoder:aDecoder] )) {
        self.delegate = self;
        self.dataSource = self;
        items = [[NSMutableArray alloc] initWithObjects:@"a", @"b", @"c", @"d", @"e", nil];
        
        // Register ourselves with the DnD overlay.
        [[DnDManager instance] registerDnDItem:self withOverlayId:@"testDND"];
        
        self.hidden = YES;
    }
    return self;
}

- (void)dealloc {
    [[DnDManager instance] deregisterDnDItem:self fromOverlayId:@"testDND"];
    [items release];
    [super dealloc];
}

#pragma mark - Table delegate methods

- (int)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [items count];
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell* cell = [self dequeueReusableCellWithIdentifier:@"DragSourceTableCell"];
    if( cell == nil ) cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DragSourceTableCell"] autorelease];
    
    cell.textLabel.textColor = [UIColor whiteColor];
    cell.textLabel.text = [items objectAtIndex:indexPath.row];
    
    return cell;
}

#pragma mark - DragModeView methods

- (void)setDragModeActive:(BOOL)active {
    if( active ) {
        // Fade into view
        
        self.hidden = NO;
        self.alpha = 0.0f;
        
        [UIView animateWithDuration:0.3f animations:^{
            self.alpha = 1.0f;
        }];
    }
    else {
        // Fade out of view
        
        [UIView animateWithDuration:0.3f animations:^{
            self.alpha = 0.0f;
        }
        completion:^( BOOL finished ) {
            self.hidden = YES;
        }];
        
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
    
    UITableViewCell* cellCopy = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DragSourceTableCell"] autorelease];
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
    NSIndexPath* newIndexPath = [self indexPathForRowAtPoint:point];
    // If the point is past the last cell, return the rectangle of the last cell (which
    // will be the placeholder)
    if( newIndexPath == nil ) newIndexPath = [NSIndexPath indexPathForRow:[items count]-1 inSection:0];
    
    CGRect rowRect = [self rectForRowAtIndexPath:newIndexPath];
    return CGPointMake( CGRectGetMidX( rowRect ), CGRectGetMidY( rowRect ));
}

// Insert a placeholder at the appropriate row to show where the draggable would
// be dropped.
- (void)draggable:(UIView *)draggable enteredAtPoint:(CGPoint)point {
    NSIndexPath* newIndexPath = [self indexPathForRowAtPoint:point];
    if( newIndexPath == nil ) newIndexPath = [NSIndexPath indexPathForRow:[items count] inSection:0];
    
    NSLog( @"Inserting fake object at row %d", newIndexPath.row );
    
    [items insertObject:@"[placeholder]" atIndex:newIndexPath.row];
    [self insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
    
    hoveringIndexPath = [newIndexPath retain];
}

// Move the placeholder if necessary.
- (void)draggable:(UIView*)draggable hoveringAtPoint:(CGPoint)point {
    NSIndexPath* newIndexPath = [self indexPathForRowAtPoint:point];
    // If row is past the last cell, use the last cell (because we don't want to add a new cell,
    // just remove the existing placeholder to the end)
    if( newIndexPath == nil ) newIndexPath = [NSIndexPath indexPathForRow:[items count]-1 inSection:0];
    
    // If the draggable is still over the same row, do nothing.  If it's moved up or down, move the
    // placeholder to the appropriate row.
    if( newIndexPath.row != hoveringIndexPath.row ) {
        [items removeObjectAtIndex:hoveringIndexPath.row];
        [self deleteRowsAtIndexPaths:[NSArray arrayWithObject:hoveringIndexPath] withRowAnimation:UITableViewRowAnimationFade];
        
        [items insertObject:@"[placeholder]" atIndex:newIndexPath.row];
        [self insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
        
        [hoveringIndexPath autorelease];
        hoveringIndexPath = [newIndexPath retain];
    }
}

// Get rid of the placeholder.
- (void)draggableExited:(UIView*)draggable {
    [items removeObjectAtIndex:hoveringIndexPath.row];
    [self deleteRowsAtIndexPaths:[NSArray arrayWithObject:hoveringIndexPath] withRowAnimation:UITableViewRowAnimationFade];
    [hoveringIndexPath autorelease];
    hoveringIndexPath = nil;
}

// Remove the placeholder and insert the dragged item.
- (void)draggable:(UIView*)draggable droppedAtPoint:(CGPoint)point {
    if( hoveringIndexPath != nil ) {
        [items removeObjectAtIndex:hoveringIndexPath.row];
        [self deleteRowsAtIndexPaths:[NSArray arrayWithObject:hoveringIndexPath] withRowAnimation:UITableViewRowAnimationFade];
        
        [hoveringIndexPath autorelease];
        hoveringIndexPath = nil;
    }
    
    NSIndexPath* newIndexPath = [self indexPathForRowAtPoint:point];
    if( newIndexPath == nil ) newIndexPath = [NSIndexPath indexPathForRow:[items count] inSection:0];
    [[newIndexPath retain] autorelease];
    
    NSLog( @"Dropping object at row %d", newIndexPath.row );
    
    UITableViewCell* draggedCell = (UITableViewCell*)draggable;
    [items insertObject:draggedCell.textLabel.text atIndex:newIndexPath.row];
    
    [self insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
}

@end

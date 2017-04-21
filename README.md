iPad Drag-and-Drop Demo
August 2011
Joshua Foster
josh2112@gmail.com


Demonstration of my drag-and-drop system for iPad. The system consists of two protocols, an invisible UIView, and a singleton.

The protocols DragSource and DropTarget can be inherited by any UIView to define itself as a draggable item and/or drop location. The invisible UIView is an overlay that manages the dragging of the item once initiated, and the singleton component just assists in registering draggable/droppable items with the overlay.

When a DragSource item is pressed, the overlay queries it for an UIView item to drag from the touched location. The UiView is removed from the DragSource and reattached to the overlay so the user can move it outside the table. As the item is dragged around, DropTargets are notified when the item enters, hovers over, or exits their boundaries. This allows them to modify themselves to show what they would look like if the item were dropped there (in this case I just insert a 'placeholder' table cell).

If the item is dropped on a valid DropTarget, the overlay sends the item to the target. Else, if the location of the original drag is also a drop target, the item is sent back to its original location. If the original drag source won't accept the item, it is just released (this could be used to delete cells, just pull them out of the table and let go).

Dragged items are slightly enlarged and have a drop shadow applied to simulate being raised off the page. Drop targets are highlighted to inform the user that the item can be dropped there. Drop actions are animated (the item animates to its final position while shrinking back to normal size).

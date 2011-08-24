//
//  testDragAndDropAppDelegate.h
//  testDragAndDrop
//
//  Created by Joshua Foster on 8/16/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class testDragAndDropViewController;

@interface testDragAndDropAppDelegate : NSObject <UIApplicationDelegate> {

}

@property (nonatomic, retain) IBOutlet UIWindow *window;

@property (nonatomic, retain) IBOutlet testDragAndDropViewController *viewController;

@end

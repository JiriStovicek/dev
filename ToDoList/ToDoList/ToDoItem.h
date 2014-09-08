//
//  ToDoItem.h
//  ToDoList
//
//  Created by Jiri Stovicek on 08/09/14.
//
//

#import <Foundation/Foundation.h>

@interface ToDoItem : NSObject

@property NSString *itemName;
@property BOOL completed;
@property (readonly) NSDate *creationDate;

@end

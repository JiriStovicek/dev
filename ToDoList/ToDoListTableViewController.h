//
//  ToDoListTableViewController.h
//  ToDoList
//
//  Created by Jiri Stovicek on 08/09/14.
//
//

#import <UIKit/UIKit.h>

@interface ToDoListTableViewController : UITableViewController

@property NSMutableArray *toDoItems;

- (IBAction)unwindToList:(UIStoryboardSegue *)segue;

@end

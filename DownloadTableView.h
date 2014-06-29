//
//  DownloadTableView.h
//  iOnionBrowser
//
//  Created by Nick Ivey on 6/24/14.
//
//

#import <UIKit/UIKit.h>

@interface DownloadTableView : UIViewController
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelButton;

@property (strong, nonatomic) IBOutlet UITableView *tableView;
- (void)queueAndStartDownloads:(NSURL *)url;
@property (strong, nonatomic) IBOutlet UILabel *text;
+(id)sharedManager;
- (IBAction)tappedCancelButton:(id)sender;

@end

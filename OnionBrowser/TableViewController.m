//
//  TableViewController.m
//  iOnionBrowser
//
//  Created by Nick Ivey on 6/23/14.
//
//

#import "TableViewController.h"
#import "AppDelegate.h"
#import "DirectoryWatcher.h"

@interface TableViewController () <QLPreviewControllerDataSource,
QLPreviewControllerDelegate, UIDocumentInteractionControllerDelegate, DirectoryWatcherDelegate>
@property (nonatomic, strong) UIDocumentInteractionController *docInteractionController;
@property (nonatomic, strong) NSMutableArray *documentURLs;
@property (nonatomic, strong) DirectoryWatcher *docWatcher;
@end


@implementation TableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.docWatcher = [DirectoryWatcher watchFolderWithPath:[self applicationDocumentsDirectory] delegate:self];
    
    self.documentURLs = [NSMutableArray array];
    
    // scan for existing documents
    [self directoryDidChange:self.docWatcher];
    

}
- (NSString *)applicationDocumentsDirectory
{
    NSString *documentsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *downloadFolder = [documentsPath stringByAppendingPathComponent:@"downloads"];

	return downloadFolder;
}

- (void)setupDocumentControllerWithURL:(NSURL *)url
{
    //checks if docInteractionController has been initialized with the URL
    if (self.docInteractionController == nil)
    {
        self.docInteractionController = [UIDocumentInteractionController interactionControllerWithURL:url];
        self.docInteractionController.delegate = self;
    }
    else
    {
        self.docInteractionController.URL = url;
    }
}

-(void)viewDidAppear:(BOOL)animated {
    [self.tableView reloadData];
    
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return _documentURLs.count;
}
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {


        NSFileManager *fileMangr = [NSFileManager defaultManager];
      //  [fileMangr removeItemAtPath:[self.documentURLs objectAtIndex:indexPath.row]] error:Nil];
        [fileMangr removeItemAtPath:[self.documentURLs objectAtIndex:indexPath.row] error:nil];
        NSLog(@"Deleted file %@", [self.documentURLs objectAtIndex:indexPath.row] );
        [self.tableView reloadData];
    }
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
  //  NSLog(@"FRJFGJFGJFGJGF");
    static NSString *cellIdentifier = @"cellID";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    NSURL *fileURL;
   
        // second section is the contents of the Documents folder
		fileURL = [self.documentURLs objectAtIndex:indexPath.row];
     	[self setupDocumentControllerWithURL:fileURL];
	
    // layout the cell
   cell.textLabel.text = [[fileURL path] lastPathComponent];
   // NSLog(@"%@", fileURL);
    
    NSInteger iconCount = [self.docInteractionController.icons count];
    if (iconCount > 0)
    {
        cell.imageView.image = [self.docInteractionController.icons objectAtIndex:iconCount - 1];
    }
    
    NSString *fileURLString = [self.docInteractionController.URL path];
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:fileURLString error:nil];
    NSInteger fileSize = [[fileAttributes objectForKey:NSFileSize] intValue];
    NSString *fileSizeStr = [NSByteCountFormatter stringFromByteCount:fileSize
                                                           countStyle:NSByteCountFormatterCountStyleFile];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ - %@", fileSizeStr, self.docInteractionController.UTI];
    
    // attach to our view any gesture recognizers that the UIDocumentInteractionController provides
    //cell.imageView.userInteractionEnabled = YES;
    //cell.contentView.gestureRecognizers = self.docInteractionController.gestureRecognizers;
    //
    // or
    // add a custom gesture recognizer in lieu of using the canned ones
    //
  //  UILongPressGestureRecognizer *longPressGesture =
   // [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
  //  [cell.imageView addGestureRecognizer:longPressGesture];
    cell.imageView.userInteractionEnabled = YES;    // this is by default NO, so we need to turn it on
    
    return cell;
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
     [tableView deselectRowAtIndexPath:indexPath animated:YES];
       NSLog(@"%ld", (long)indexPath.row);
  //  AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
  //  NSURL* fileURL = [self.documentURLs objectAtIndex:indexPath.row];
//    [self setupDocumentControllerWithURL:fileURL];
//    [self.docInteractionController presentPreviewAnimated:YES];
//    [self.view.window.rootViewController presentViewController:self.docInteractionController animated:YES completion:nil];
    
    // for case 3 we use the QuickLook APIs directly to preview the document -
   QLPreviewController *previewController = [[QLPreviewController alloc] init];
   previewController.dataSource = self;
   previewController.delegate = self;

   previewController.currentPreviewItemIndex = indexPath.row;
   [self presentViewController:previewController animated:YES completion:nil];


}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
// Returns the number of items that the preview controller should preview
- (NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)previewController
{
    NSInteger numToPreview = 0;
    numToPreview = self.documentURLs.count;
    
    return numToPreview;
}


- (void)previewControllerDidDismiss:(QLPreviewController *)controller
{
    // if the preview dismissed (done button touched), use this method to post-process previews
}
- (UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)interactionController
{
    NSLog(@"privew item ");
    return self;
}
// returns the item that the preview controller should preview
- (id)previewController:(QLPreviewController *)previewController previewItemAtIndex:(NSInteger)idx
{
    NSURL *fileURL = nil;
    
    fileURL = [self.documentURLs objectAtIndex:idx];
    return fileURL;
}
- (void)directoryDidChange:(DirectoryWatcher *)folderWatcher
{
	[self.documentURLs removeAllObjects];    // clear out the old docs and start over
	
	NSString *documentsDirectoryPath = [self applicationDocumentsDirectory];
	
	NSArray *documentsDirectoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDirectoryPath
                                                                                              error:NULL];
    
	for (NSString* curFileName in [documentsDirectoryContents objectEnumerator])
	{
		NSString *filePath = [documentsDirectoryPath stringByAppendingPathComponent:curFileName];
		NSURL *fileURL = [NSURL fileURLWithPath:filePath];
		
		BOOL isDirectory;
        [[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDirectory];
		
        // proceed to add the document URL to our list (ignore the "Inbox" folder)
        if (!(isDirectory && [curFileName isEqualToString:@"Inbox"]))
        {
            [self.documentURLs addObject:fileURL];
        }
	}
	
	[self.tableView reloadData];
   // NSLog(@"%@", self.documentURLs);
}




@end

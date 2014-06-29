//
//  DownloadTableView.m
//  iOnionBrowser
//
//  Created by Nick Ivey on 6/24/14.
//
//

#import "DownloadTableView.h"
#import "DownloadManager.h"
#import "DownloadCell.h"

@interface DownloadTableView () <DownloadManagerDelegate>

@property (strong, nonatomic) DownloadManager *downloadManager;
@property (strong, nonatomic) NSDate *startDate;
@property (nonatomic) NSInteger downloadErrorCount;
@property (nonatomic) NSInteger downloadSuccessCount;

@end

@implementation DownloadTableView

+(id)sharedManager {
    static DownloadTableView *downloadMan = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        downloadMan = [[self alloc] init];
    });
    return downloadMan;
}
- (id)init {
    if (self = [super init]) {
       // someProperty = [[NSString alloc] initWithString:@"Default Property Value"];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    
  // [self queueAndStartDownloads:[NSURL URLWithString:@"http://nickivey.me/wp-content/uploads/2014/02/wackafriendicon-noPreset-300x300.jpg"]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(void)viewDidAppear:(BOOL)animated {
    [self.tableView reloadData];
}
- (void)queueAndStartDownloads:(NSURL *)url
{


    NSString *documentsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *downloadFolder = [documentsPath stringByAppendingPathComponent:@"downloads"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:downloadFolder])		//Does file exist?
	{
		if (![[NSFileManager defaultManager] createDirectoryAtPath:downloadFolder
									   withIntermediateDirectories:NO
														attributes:nil
															 error:nil]) {
       
        }
	}
    
    self.downloadManager = [[DownloadManager alloc] initWithDelegate:self];
    self.downloadManager.maxConcurrentDownloads = 4;
    

        NSString *downloadFilename = [downloadFolder stringByAppendingPathComponent:[url lastPathComponent]];
        [self.downloadManager addDownloadWithFilename:downloadFilename URL:url];

    
    self.cancelButton.enabled = YES;
    self.startDate = [NSDate date];
    NSLog(@"DOwnling %@", url);
    [self.downloadManager start];
    
 }

#pragma mark - DownloadManager Delegate Methods

// optional method to indicate completion of all downloads
//
// In this view controller, display message

- (void)didFinishLoadingAllForManager:(DownloadManager *)downloadManager
{
    NSString *message;
    
    NSTimeInterval elapsed = [[NSDate date] timeIntervalSinceDate:self.startDate];
    
    self.cancelButton.enabled = NO;
    
    if (self.downloadErrorCount == 0)
        message = [NSString stringWithFormat:@"%ld file(s) downloaded successfully. The files are located in the app's Documents folder on your device/simulator. (%.1f seconds)", (long)self.downloadSuccessCount, elapsed];
    else
        message = [NSString stringWithFormat:@"%ld file(s) downloaded successfully. %ld file(s) were not downloaded successfully. The files are located in the app's Documents folder on your device/simulator. (%.1f seconds)", (long)self.downloadSuccessCount, (long)self.downloadErrorCount, elapsed];
    
    [[[UIAlertView alloc] initWithTitle:nil
                                message:message
                               delegate:nil
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil] show];
}

// optional method to indicate that individual download completed successfully
//
// In this view controller, I'll keep track of a counter for entertainment purposes and update
// tableview that's showing a list of the current downloads.

- (void)downloadManager:(DownloadManager *)downloadManager downloadDidFinishLoading:(Download *)download;
{
    //NSLog(@"QQQQQQQQQQQQQQQQQQQQQQ");
    self.downloadSuccessCount++;
    
    [self.tableView reloadData];
}

// optional method to indicate that individual download failed
//
// In this view controller, I'll keep track of a counter for entertainment purposes and update
// tableview that's showing a list of the current downloads.

- (void)downloadManager:(DownloadManager *)downloadManager downloadDidFail:(Download *)download;
{
    NSLog(@"%s %@ error=%@", __FUNCTION__, download.filename, download.error);
    
    self.downloadErrorCount++;
    
    [self.tableView reloadData];
}

// optional method to indicate progress of individual download
//
// In this view controller, I'll update progress indicator for the download.

- (void)downloadManager:(DownloadManager *)downloadManager downloadDidReceiveData:(Download *)download;
{
       //NSLog(@"QQQQQQQQQQQQQQQQQQQQQQ");
    for (NSInteger row = 0; row < [downloadManager.downloads count]; row++)
    {
        if (download == downloadManager.downloads[row])
        {
            [self updateProgressViewForIndexPath:[NSIndexPath indexPathForRow:row inSection:0] download:download];
            break;
        }
    }
}

#pragma mark - Table View delegate and data source methods

// our table view will simply display a list of files being downloaded

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
      //  NSLog(@"SET UP TABLE");
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
       NSLog(@"Number of rows");
    return [self.downloadManager.downloads count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"SET UP TABLE");
    static NSString *CellIdentifier = @"DownloadCell";
    DownloadCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    Download *download = self.downloadManager.downloads[indexPath.row];
    
    // the name of the file
    
    cell.filenameLabel.text = [download.filename lastPathComponent];
    
    if (download.isDownloading)
    {
        // if we're downloading a file turn on the activity indicator
        
        if (!cell.activityIndicator.isAnimating)
            [cell.activityIndicator startAnimating];
        
        cell.activityIndicator.hidden = NO;
        cell.progressView.hidden = NO;
        
        [self updateProgressViewForIndexPath:indexPath download:download];
    }
    else
    {
        // if not actively downloading, no spinning activity indicator view nor file download progress view is needed
        
        [cell.activityIndicator stopAnimating];
        cell.activityIndicator.hidden = YES;
        cell.progressView.hidden = YES;
    }
    
    return cell;
}

#pragma mark - Table view utility methods

- (void)updateProgressViewForIndexPath:(NSIndexPath *)indexPath download:(Download *)download
{
    DownloadCell *cell = (DownloadCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    NSLog(@"UPdating low");
    // if the cell is not visible, we can return
    
    if (!cell)
        return;
    
    if (download.expectedContentLength >= 0)
    {
        // if the server was able to tell us the length of the file, then update progress view appropriately
        // to reflect what % of the file has been downloaded
        
        cell.progressView.progress = (double) download.progressContentLength / (double) download.expectedContentLength;
           }
    else
    {
        // if the server was unable to tell us the length of the file, we'll change the progress view, but
        // it will just spin around and around, not really telling us the progress of the complete download,
        // but at least we get some progress update as bytes are downloaded.
        //
        // This progress view will just be what % of the current megabyte has been downloaded
        
        cell.progressView.progress = (double) (download.progressContentLength % 1000000L) / 1000000.0;
      
    }
}

#pragma mark - IBAction methods

- (IBAction)tappedCancelButton:(id)sender
{
    [self.downloadManager cancelAll];
}

@end

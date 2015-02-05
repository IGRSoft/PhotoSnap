//
//  ViewController.m
//  Example
//
//  Created by Vitalii Parovishnyk on 2/5/15.
//
//

#import "ViewController.h"
#import "ImageSnap.h"

@interface ViewController ()

@property (weak) IBOutlet NSComboBox *imageType;
- (IBAction)takePhoto:(id)sender;

@end

@implementation ViewController

- (void)viewDidLoad
{
	[super viewDidLoad];

	// Do any additional setup after loading the view.
}

- (void)setRepresentedObject:(id)representedObject
{
	[super setRepresentedObject:representedObject];

	// Update the view, if already loaded.
}

- (IBAction)takePhoto:(id)sender
{
	NSDateFormatter *formatter;
	NSString        *dateString = @"snapshot_";
	
	formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:@"dd-MM-yyyy_HH-mm"];
	
	dateString = [dateString stringByAppendingString:[formatter stringFromDate:[NSDate date]]];
	dateString = [dateString stringByAppendingPathExtension:self.imageType.stringValue];
	
	NSString *picturePath = [NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES) firstObject];
	
	picturePath = [picturePath stringByAppendingPathComponent:dateString];
	
	[ImageSnap saveSnapshotFrom:[ImageSnap defaultVideoDevice] toFile:picturePath];
}

@end

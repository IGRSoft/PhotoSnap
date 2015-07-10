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

@property (nonatomic, assign) NSNumber *warmupValue;
@property (nonatomic, assign) NSNumber *timelapseValue;

- (IBAction)takePhoto:(id)sender;

@end

@implementation ViewController

- (void)viewDidLoad
{
	[super viewDidLoad];

    self.warmupValue = 0;
    self.timelapseValue = 0;
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
	[formatter setDateFormat:@"dd-MM-yyyy_HH-mm-ss"];
	
	dateString = [dateString stringByAppendingString:[formatter stringFromDate:[NSDate date]]];
	dateString = [dateString stringByAppendingPathExtension:self.imageType.stringValue];
	
	NSString *picturePath = [NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES) firstObject];
	
	picturePath = [picturePath stringByAppendingPathComponent:dateString];
	
    AVCaptureDevice *defaultVideoDevice = [ImageSnap defaultVideoDevice];
	[ImageSnap saveSnapshotFrom:defaultVideoDevice
                         toFile:picturePath
                     withWarmup:self.warmupValue
                  withTimelapse:self.timelapseValue];
}

- (void)setWarmupValue:(NSNumber *)warmupValue
{
    _warmupValue = @(warmupValue.integerValue);
}

- (void)setTimelapseValue:(NSNumber *)timelapseValue
{
    _timelapseValue = @(timelapseValue.integerValue);
}

@end

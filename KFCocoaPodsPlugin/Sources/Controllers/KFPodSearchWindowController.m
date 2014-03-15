//
//  KFPodSearchWindowController.m
//  KFCocoaPodsPlugin
//
//  Created by rick on 17/11/13.
//  Copyright (c) 2013 KF Interactive. All rights reserved.
//

#import "KFPodSearchWindowController.h"
#import "KFRepoModel.h"
#import "KFReplController.h"
#import "KFCocoaPodsPlugin.h"

@interface KFPodSearchWindowController ()


@property (nonatomic, strong, readwrite) NSMutableArray *repoData;

@property (strong) IBOutlet NSArrayController *repoArrayController;
@property (strong) IBOutlet NSButton *tryButton;
@property (strong) IBOutlet NSProgressIndicator *progressIndicator;

@end



@implementation KFPodSearchWindowController


- (id)initWithRepoData:(NSArray *)repoData
{
    self = [super initWithWindowNibName:@"KFPodSearchWindow"];
    if(self)
    {
        [self performSelectorInBackground:@selector(parseRepoData:) withObject:repoData];
        _repoSortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"pod" ascending:YES selector:@selector(caseInsensitiveCompare:)]];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(replParseCountDidChange:) name:KFReplControllerParsingCountDidChange object:nil];
    }
    return self;
}


- (void)parseRepoData:(NSArray *)repoData
{
    self.repoData = [NSMutableArray new];
    for (NSArray *podspec in repoData)
    {
        if (podspec.firstObject)
        {
            KFRepoModel *repoModel = podspec.firstObject;
            [self.repoData addObject:repoModel];
        }
    }
    [self.repoData sortUsingDescriptors:self.repoSortDescriptors];
    [self.repoData makeObjectsPerformSelector:@selector(parsePodspec)];
    
    self.searchEnabled = NO;
}


- (void)replParseCountDidChange:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    NSNumber *countObj = userInfo[KFReplParseCount];
    NSUInteger count = [countObj unsignedIntegerValue];
    
    BOOL changeEnabledNewValue = count == 0;
    
    if (changeEnabledNewValue != self.searchEnabled)
    {
        self.searchEnabled = changeEnabledNewValue;
    }
}


- (void)windowDidLoad
{
    [super windowDidLoad];
}


- (IBAction)confirmAction:(id)sender
{
    [NSApp endSheet:self.window];
    [self.window orderOut:self];
}

- (IBAction)tryPod:(id)sender
{
    [self.tryButton setEnabled:NO];
    [self.progressIndicator startAnimation:self];
    
    // try the pod.
    KFRepoModel *repoModel = [[self.repoArrayController selectedObjects] firstObject];
    
    [[[KFCocoaPodsPlugin sharedPlugin] taskController] runPodCommand:@[@"try", repoModel.pod] directory:nil outputHandler:^(DSUnixTask *taskLauncher, NSString *newOutput) {
    } terminationHandler:^(DSUnixTask *taskLauncher) {
        [self.progressIndicator stopAnimation:self];
        [self.tryButton setEnabled:YES];
    } failureHandler:^(DSUnixTask *taskLauncher) {
        [self.progressIndicator stopAnimation:self];
        [self.tryButton setEnabled:YES];
    }];
}

- (IBAction)copyPodnameAction:(id)sender
{
    KFRepoModel *repoModel = [[self.repoArrayController selectedObjects] firstObject];
    NSPasteboard *pasteBoard = [NSPasteboard generalPasteboard];
    [pasteBoard declareTypes:@[NSStringPboardType] owner:nil];
    [pasteBoard setString:repoModel.pod forType:NSStringPboardType];
}


@end

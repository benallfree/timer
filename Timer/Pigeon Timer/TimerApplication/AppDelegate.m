//
//  AppDelegate.m
//  Timer
//
//  Created by jenkins on 6/20/14.
//  Copyright (c) 2014 GreatBasinGroup. All rights reserved.
//

#import "AppDelegate.h"
#import "MemoWindow.h"
#import "TimerDatabase.h"
#import "CHCSVParser.h"
#import "Utilities.h"
#import "PreferenceWindow.h"
#import "BreakEnded.h"
#import "BreakStarted.h"
#import "NSBundle+LoginItem.h"
#import "NSString+SpaceAttributes.h"

@implementation AppDelegate


/**
 *  startup launch timer routine.
 *
 *  @param sender <#sender description#>
 */
-(void) launchAlertMemoOnStartup:(id)sender;
{
    ;// [self alertMemoBox];
}

/**
 *  application did finish notification
 *
 *  @param aNotification notification object
 */
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    //setup status item
    [self setupStatusItem];
    [[NSUserDefaults standardUserDefaults]  addObserver:self
                                             forKeyPath: @"load_onStart"
                                                options:NSKeyValueObservingOptionNew
                                                context:nil];
    
    self.totalPomodoro = 1;
    [[NSUserDefaults standardUserDefaults]  addObserver:self
                                             forKeyPath: @"dont_ask"
                                                options:NSKeyValueObservingOptionNew
                                                context:nil];
    
    [[NSUserDefaults standardUserDefaults]  addObserver:self
                                             forKeyPath: @"show_timer"
                                                options:NSKeyValueObservingOptionNew
                                                context:nil];
    
    NSNumber *dont_check = [[NSUserDefaults standardUserDefaults] objectForKey:@"dont_ask"];
    if (![[NSBundle mainBundle] isLoginItem])
    {
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:NO] forKey:@"load_onStart"];
        if (!dont_check || ![dont_check boolValue])
        {
            NSWindowController * controller = [[NSWindowController alloc] initWithWindowNibName:@"StartupCheck" ];
            self.check_loginItem = (NSWindow *)controller.window;
            [self.check_loginItem center];
            [self.check_loginItem makeKeyAndOrderFront:self];
            [self.check_loginItem setLevel:NSFloatingWindowLevel];
            return;
        }
    }
    else
    {
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:@"load_onStart"];
    }
    
    [self setupApp];
    
    
}

/**
 *  starts the timer to relaunch memo box
 */
- (void) startTimer
{
    /*  if ([self.active state] == NSOffState)
     {
     
     
     //otherewise activate the memo box
     [self.active setState:NSOnState];
     [self startNextPomo:NO];
     }//Allocates and loads the images into the application which will be used for our NSStatusItem
     */
    if (self.currentStatus == kPomoInProgress)
    {
        self.timerStatusImage = [NSImage imageNamed:@"pomo"];
        self.timerStatusHighlightImage =  self.timerStatusImage;
        [self.timerStatusItem setImage:self.timerStatusImage];
        [self.timerStatusItem setAlternateImage:self.timerStatusHighlightImage];
    }
    
    NSLog(@"Next memo pop after %d minutes", [[[NSUserDefaults standardUserDefaults] objectForKey:@"log_interval"] intValue]);
    self.timer = [NSTimer scheduledTimerWithTimeInterval:[[[NSUserDefaults standardUserDefaults] objectForKey:@"log_interval"] intValue] * 60 target:self selector:@selector(alertMemoBox) userInfo:nil repeats:NO];
}

/**
 *  inactivate the memo box for popping up next time.
 */
- (void) uncheckActive
{
    
    [self.timer invalidate];
    self.timer = nil;
    [self.active setTitle:@"Start" ];
    
    //Allocates and loads the images into the application which will be used for our NSStatusItem
    
    self.currentStatus = kDoingNothing;
    
    //Sets the images in our NSStatusItem
    
    self.timerStatusImage = [NSImage imageNamed:@"stop"];
    self.timerStatusHighlightImage =  self.timerStatusImage;
    [self.timerStatusItem setImage:self.timerStatusImage];
    [self.timerStatusItem setAlternateImage:self.timerStatusHighlightImage];
    if (self.break_started)
        [self.break_started close];
    
}

/**
 *  execute the mute menu item
 */
-(void) handleMuteMenuItem
{
    //if it was checked, then uncheck and invalidate the timer
    if (self.mute.state == NSOnState)
    {
        [self.mute setState:NSOffState];
    }
    else
    {
        [Utilities stopSound];
        [self.mute setState:NSOnState];
        
    }
}


/**
 *  execute the active menu item
 */
-(void) handleActiveMenuItem
{
    //if it was checked, then uncheck and invalidate the timer
    if ([self.active.title isEqualToString:@"Stop"])
    {
        NSLog(@"User set off Activity");
        [self.enterLog setEnabled:NO];
        [self.enterLog setAction:nil];
        [Utilities stopSound];
        [self uncheckActive];
        [self resetPomoTimer];
        
    }
    else
    {
        NSLog(@"User set Activity On");
        [self.enterLog setEnabled:YES];
        [self.enterLog setAction:@selector(menuClicked:)];
        //otherewise activate the memo box
        [self.active setTitle:@"Stop" ];
        //Allocates and loads the images into the application which will be used for our NSStatusItem
        self.timerStatusImage = [NSImage imageNamed:@"pomo"];
        
        [self.timerStatusImage setSize:NSMakeSize(16, 16)];
        self.timerStatusHighlightImage =  self.timerStatusImage;
        
        //Sets the images in our NSStatusItem
        [self.timerStatusItem setImage:self.timerStatusImage];
        [self.timerStatusItem setAlternateImage:self.timerStatusHighlightImage];
        
        
        
        [self resetPomoTimer];
        
    }
}

/**
 *  executes the report menu item
 */
-(void) handleReportMenuItem
{
    NSArray *toplevel;
    
    if (self.reportWindow) return;
    [[NSBundle mainBundle] loadNibNamed:@"ClientSelectDialog" owner:self topLevelObjects:&toplevel];
    [self willChangeValueForKey:@"clientFromDB"];
    NSMutableArray *clients = (NSMutableArray *)[[TimerDatabase sharedInstance] getClients];
    
    self.clientFromDB = [[NSMutableArray alloc] init];
    
    for (NSString *client in clients)
    {
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        [dict setObject:client forKey:@"title"];
        [dict setObject:@NO forKey:@"selected"];
        [self.clientFromDB addObject:dict];
        
    }
    [self didChangeValueForKey:@"clientFromDB"];
    [self.reportWindow makeKeyAndOrderFront:nil];
    [self.reportWindow center];
    [self.reportWindow setLevel:NSStatusWindowLevel];
    [NSApp activateIgnoringOtherApps:YES];
    
}

/**
 *  handles menu item click for Enter Logs
 */
-(void) handleEnterLogs
{
    NSLog(@"user clicked on Open.");
    
    if (self.currentStatus == kLongBreak || self.currentStatus == kShortBreak)
    {
        if (self.break_started)
        {
            [self.break_started center];
            [self.break_started setLevel:NSFloatingWindowLevel];
            [self.break_started makeKeyAndOrderFront:self];
        }
        return;
    }
    
    if ([self.window isVisible])
    {
        [self.window makeKeyAndOrderFront:self];
        return;
    }
    
    [self.timer invalidate];
    self.timer = nil;
    
    if (!self.window)
    {
        self.windowctrl =  [MemoWindow loadMemoWindow];
        
        self.window = self.windowctrl.window;
    }
    ((MemoWindow *)self.window).clients = (NSMutableArray *) [[TimerDatabase sharedInstance] getClients];
    if (((MemoWindow *)self.window).selectedClient &&
        [((MemoWindow *)self.window).selectedClient length] > 0)
    {
        long long ID = [[TimerDatabase sharedInstance] getClientID:((MemoWindow *)self.window).selectedClient];
        NSMutableArray *arr = (NSMutableArray *) [[TimerDatabase sharedInstance] getLogsForClient:ID];
        NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:@"- Today", @"logs", nil];
        [arr insertObject:dict atIndex:0];
        NSMutableArray *tempArray =   (NSMutableArray *)[[TimerDatabase sharedInstance] getRecentLogsForClient:ID];
        dict = [NSDictionary dictionaryWithObjectsAndKeys:@"- Recent", @"logs", nil];
        ((MemoWindow *)self.window).recentRowIndex = [arr count];
        [arr addObject:dict];
        [arr addObjectsFromArray:tempArray];
        arr = [Utilities unique:arr withIndex:(int)((MemoWindow *)self.window).recentRowIndex ];
        ((MemoWindow *)self.window).values = arr;
        if ( ((MemoWindow *)self.window).recentRowIndex > 1)
            [ ((MemoWindow *)self.window).Tablecontroller selectRowIndexes:[NSIndexSet indexSetWithIndex:1] byExtendingSelection:NO];
        else if ([ ((MemoWindow *)self.window).values count] > 2)
            [ ((MemoWindow *)self.window).Tablecontroller selectRowIndexes:[NSIndexSet indexSetWithIndex:2] byExtendingSelection:NO];
        else
            [ ((MemoWindow *)self.window).Tablecontroller deselectAll:self];
    }
    
    
    [self.window center];
    [self.window makeKeyAndOrderFront:self];
    [self.window setLevel:NSFloatingWindowLevel];
    
    if ([self.mute state] == NSOffState && self.playpopupSound)
    {
        
        [Utilities playSound:@"popup_sound_path" volumeKey:@"popup_vol" default:@"memo"];
    }
}



- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualTo:@"show_timer"] )
    {
        if (self.currentStatus != kPomoPaused)
            self.pomodoroTimerStr = [NSString stringWithFormat:@"%02ld:%02ld", (long)self.minutes, (long)self.seconds];
        else
            self.pomodoroTimerStr = [NSString stringWithFormat:@"Paused"];
        
        if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"show_timer" ] boolValue])
            [self.timerStatusItem setAttributedTitle:[self.pomodoroTimerStr stringByAddingSpaceAttributes:2.f]];
        else
            [self.timerStatusItem setTitle:@""];
        
        
    }
    else if ([keyPath isEqualTo:@"load_onStart"] )
    {
        NSNumber *check_laucnItem = [[NSUserDefaults standardUserDefaults] objectForKey:@"load_onStart"];
        if ([check_laucnItem boolValue])
        {
            if (![[NSBundle mainBundle] isLoginItem])
            {
                [[NSBundle mainBundle] addToLoginItems];
            }
        }
        else
        {
            [[NSBundle mainBundle] removeFromLoginItems];
        }
    }
}
/**
 *  execute preference menu item.
 */
-(void) handlePreferenceMenuItem
{
    NSLog(@"Handle Pereferences Launch");
    if (!self.pref_window)
    {
        NSWindowController * controller = [[NSWindowController alloc] initWithWindowNibName:@"Preferences" ];
        self.pref_window = (NSWindow *)controller.window;
    }
    if (![[NSBundle mainBundle] isLoginItem])
    {
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:NO] forKey:@"load_onStart"];
    }
    [self.pref_window center];
    [(PreferenceWindow *)self.pref_window makeCopyOfCurrent];
    //self.pref_window.value = [[NSUserDefaults standardUserDefaults] objectForKey:@"timeInterval"];
    [self.pref_window makeKeyAndOrderFront:self];
    [self.pref_window setLevel:NSFloatingWindowLevel];
    [NSApp activateIgnoringOtherApps:YES];
    self.preferencesWindowClosed = NO;
    
}
/**
 *  handles break
 */

-(void) handleBreak
{
    NSLog(@"User stopped activity and started break from menu.");
    
    [self pomoFinished];
    self.pomodoroTimerStr = @"00:00";
    
}
/**
 *  handle pause menu item click
 *
 *  @param
 */
-(void) handlePause
{
    NSLog(@"Activity Paused");
    [Utilities stopSound];
    
    if (self.currentStatus != kPomoPaused)
    {
        self.oldStatus = self.currentStatus;
        self.currentStatus = kPomoPaused;
        self.timerStatusImage = [NSImage imageNamed:@"break"];
        self.timerStatusHighlightImage =  self.timerStatusImage;
        [self.timerStatusItem setImage:self.timerStatusImage];
        [self.pause setTitle:@"Resume..."];
        [self.timerStatusItem setAlternateImage:self.timerStatusHighlightImage];
        [self.breakNow setAction:nil];
        [self.active setAction:nil];
        [self.breakNow setTarget:nil];
        [self.active setTarget:nil];
        
    }
    else
    {
        self.currentStatus = self.oldStatus;
        if (self.currentStatus == kPomoInProgress)
        {
            self.timerStatusImage = [NSImage imageNamed:@"pomo"];
            self.timerStatusHighlightImage =  self.timerStatusImage;
            [self.timerStatusItem setImage:self.timerStatusImage];
            [self.pause setTitle:@"Pause..."];
        }
        [self.active setAction:@selector(menuClicked:)];
        [self.breakNow setAction:@selector(menuClicked:)];
        [self.timerStatusItem setAlternateImage:self.timerStatusHighlightImage];
    }
}
/**
 *  action listener for menu items
 *
 *  @param sender Object that trigger this function
 */
-(void) menuClicked:(id)sender
{
    if (sender == self.mute)
    {
        [self handleMuteMenuItem];
    }
    //when clicked on active menu item
    else if (sender == self.active)
    {
        [self handleActiveMenuItem];
    }
    //user clicked on report menu item.
    else if (sender == self.report)
    {
        [self handleReportMenuItem];
    }
    //if user hit enter log
    else if (sender == self.enterLog)
    {
        [self handleEnterLogs];
    }
    //handle preference
    else if (sender == self.Preferences)
    {
        [self handlePreferenceMenuItem];
    }
    else if (sender == self.breakNow)
    {
        [self handleBreak];
    }
    else if (sender == self.pause)
    {
        [self handlePause];
    }
    //quit
    else
    {
        [[NSApplication sharedApplication] terminate:self];
    }
}

/**
 *  when a window is closed.
 *
 *  @param sender <#sender description#>
 */

-(void) windowClosed:(id)sender
{
    if (sender == self.window)
    {
        self.window = nil;
    }
}


/**
 *  function to popup memo box.
 */
- (void) alertMemoBox
{
    NSLog(@"Launching Memo Box");
    if (( [self.active.title isEqualToString:@"Stop"]) && (self.currentStatus != kPomoInProgress))
    {
        [self startTimer];
        return;
    }
    if ([self.active.title isEqualToString:@"Start"])
        return;
    
    if ([self.window isVisible])
    {
        [self.window makeKeyAndOrderFront:self];
        return;
    }
    
    [self.timer invalidate];
    self.timer = nil;
    
    if (!self.window)
    {
        self.windowctrl =  [MemoWindow loadMemoWindow];
        
        self.window = self.windowctrl.window;
    }
    ((MemoWindow *)self.window).clients = (NSMutableArray *) [[TimerDatabase sharedInstance] getClients];
    if (((MemoWindow *)self.window).selectedClient &&
        [((MemoWindow *)self.window).selectedClient length] > 0)
    {
        long long ID = [[TimerDatabase sharedInstance] getClientID:((MemoWindow *)self.window).selectedClient];
        NSMutableArray *arr = (NSMutableArray *) [[TimerDatabase sharedInstance] getLogsForClient:ID];
        NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:@"- Today", @"logs", nil];
        [arr insertObject:dict atIndex:0];
        NSMutableArray *tempArray =   (NSMutableArray *)[[TimerDatabase sharedInstance] getRecentLogsForClient:ID];
        dict = [NSDictionary dictionaryWithObjectsAndKeys:@"- Recent", @"logs", nil];
        ((MemoWindow *)self.window).recentRowIndex = [arr count];
        [arr addObject:dict];
        [arr addObjectsFromArray:tempArray];
        
        arr = [Utilities unique:arr withIndex:(int)((MemoWindow *)self.window).recentRowIndex];
        
        ((MemoWindow *)self.window).values = arr;
        
        if ( ((MemoWindow *)self.window).recentRowIndex > 1)
            [ ((MemoWindow *)self.window).Tablecontroller selectRowIndexes:[NSIndexSet indexSetWithIndex:1] byExtendingSelection:NO];
        else if ([ ((MemoWindow *)self.window).values count] > 2)
            [ ((MemoWindow *)self.window).Tablecontroller selectRowIndexes:[NSIndexSet indexSetWithIndex:2] byExtendingSelection:NO];
        else
            [ ((MemoWindow *)self.window).Tablecontroller deselectAll:self];
    }
    
    
    [self.window center];
    [self.window makeKeyAndOrderFront:self];
    [self.window setLevel:NSFloatingWindowLevel];
    if ([self.mute state] == NSOffState && self.playpopupSound)
    {
        
        [Utilities playSound:@"popup_sound_path" volumeKey:@"popup_vol" default:@"memo"];
    }
    
    
}

-(void) playTick
{
    //wait for start mp3 to play
    //sleep(6);
    
    //dispatch_async(<#dispatch_queue_t queue#>, <#^(void)block#>)
    while (1)
    {
        
        
        if ([self.mute state] == NSOffState)
        {
            if (self.currentStatus == kPomoInProgress && !self.countdown_music)
            {
                [Utilities playSoundStripped:@"tick_sound_path" volumeKey:@"tick_vol" default:@"tick"];
            }
            else
            {
                if (self.countdown_music && [self.active.title isEqualToString:@"Stop"])
                {
                    BOOL playOnce = [[[NSUserDefaults standardUserDefaults] objectForKey:@"count_down_playOnce"] boolValue];
                    if (!(playOnce && self.countdown_playcount >= 1))
                        [Utilities playSound:@"countdown_music_sound_path" volumeKey:@"countdown_music_vol" default:@"countdown"];
                    else  if ([self.mute state] == NSOffState && self.currentStatus == kPomoInProgress )
                        [Utilities playSoundStripped:@"tick_sound_path" volumeKey:@"tick_vol" default:@"tick"];
                    
                    self.countdown_playcount++;
                }
            }
            usleep(980000);
            
        }
        else
            usleep(500000);
    }
}

-(void) backgroundThread
{
    NSNumber *showTitle = nil;
    
   
        @autoreleasepool {
            showTitle = [[NSUserDefaults standardUserDefaults] objectForKey:@"show_timer"];
            
            if (self.currentStatus != kPomoPaused)
            {
                if (self.seconds == 0)
                {
                    if (self.minutes >0)
                        self.minutes--;
                    self.seconds = 59;
                }
                else
                    self.seconds--;
                
                self.totalSecondsToStay--;
            }
            
            
            if (self.totalSecondsToStay <= self.countdown_minutes*60)
            {
                self.countdown_music = YES;
            }
            
            
            if (self.currentStatus == kPomoPaused)
            {
                self.pomodoroTimerStr = [NSString stringWithFormat:@"%02ld:%02ld", (long)self.minutes, (long)self.seconds];
                
                if ([showTitle boolValue])
                    [self.timerStatusItem setTitle:@"Paused"] ;//]self.pomodoroTimerStr];
                else
                    [self.timerStatusItem setTitle:@""];
                
                
            }
            
            
            else if (self.currentStatus == kPomoInProgress)
            {
                self.pomodoroTimerStr = [NSString stringWithFormat:@"%02ld:%02ld", (long)self.minutes, (long)self.seconds];
                
                if ([showTitle boolValue])
                    [self.timerStatusItem setAttributedTitle:[self.pomodoroTimerStr stringByAddingSpaceAttributes:2.f]];
                else
                    [self.timerStatusItem setTitle:@""];
                
                
                if (self.totalSecondsToStay == 0)
                {
                    [self pomoFinished];
                }
            }
            else if (self.currentStatus == kLongBreak || self.currentStatus == kShortBreak)
            {
                self.breakTimerStr = [NSString stringWithFormat:@"%02ld:%02ld", (long)self.minutes, (long)self.seconds];
                if ([showTitle boolValue])
                    [self.timerStatusItem setAttributedTitle:[self.breakTimerStr stringByAddingSpaceAttributes:2.f]];
                else
                    [self.timerStatusItem setTitle:@""];
                
                if (self.totalSecondsToStay == 0)
                {
                    [self BreakEnded];
                }
                
            }
        }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self backgroundThread];
    });
}

/**
 *  updates timer strings
 *
 *  @param sender
 */
-(void) updatePomoTimer:(id)sender
{
    
    if ([self.active.title isEqualToString:@"Start"] || self.currentStatus == kDoingNothing)
    {
        if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"show_timer" ] boolValue])
            [self.timerStatusItem setTitle:@""];
        else
            [self.timerStatusItem setTitle:@""];
        
        [[self.timerStatusItem view] setNeedsDisplay:YES];
        return;
        
    }
    
    
    /*  if (self.seconds == 0)
     {
     if (self.minutes >0)
     self.minutes--;
     self.seconds = 59;
     }
     else
     self.seconds--;*/
    
    
    if (self.currentStatus == kPomoInProgress)
    {
        //  self.pomodoroTimerStr = [NSString stringWithFormat:@"%02ld:%02ld", (long)self.minutes, (long)self.seconds];
        [self.timerStatusItem setAttributedTitle:[self.pomodoroTimerStr stringByAddingSpaceAttributes:2.f]];
    }
    else
    {
        //  self.breakTimerStr = [NSString stringWithFormat:@"%02ld:%02ld", (long)self.minutes, (long)self.seconds];
        [self.timerStatusItem setAttributedTitle:[self.breakTimerStr stringByAddingSpaceAttributes:2.f]];
        
    }
    [[self.timerStatusItem view] setNeedsDisplay:YES];
}
/**
 *  function to handle click on status icon
 *
 *  @param sender
 */
-(void) popup:(id)sender
{
    //  self.window = nil;
    if (self.currentStatus == kShortBreak || self.currentStatus == kLongBreak || self.currentStatus == kPomoPaused)
    {
        [self.breakNow setAction:nil];
    }
    else
    {
        [self.breakNow setTarget:self];
        [self.breakNow setAction:@selector(menuClicked:)];
    }
    if (![[TimerDatabase sharedInstance] LogsAvailableToReport])
    {
        [self.report setAction:nil];
    }
    else
    {
        [self.report setAction:@selector(menuClicked:)];
        
    }
    [self.timerStatusItem popUpStatusItemMenu:self.timerStatusMenu];
    
}
//setsup status item related stuff.
- (void) setupStatusItem
{
    
    //Create the NSStatusBar and set its length
    self.timerStatusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:80.f];
 
    
    //Allocates and loads the images into the application which will be used for our NSStatusItem
    self.timerStatusImage = [NSImage imageNamed:@"pomo"];
    
    //  [self.timerStatusImage setSize:NSMakeSize(16, 16)];
    self.timerStatusHighlightImage =  self.timerStatusImage;
    
    //Sets the images in our NSStatusItem
    [self.timerStatusItem setImage:self.timerStatusImage];
    [self.timerStatusItem setAlternateImage:self.timerStatusHighlightImage];
    
    
    //Tells the NSStatusItem what menu to load
    //[self.timerStatusItem setMenu:self.timerStatusMenu];
    [self.timerStatusItem setTarget:self];
    [self.timerStatusItem setAction:@selector(popup:)];
    //Sets the tooptip for our item
    NSDictionary* infoDict = [[NSBundle mainBundle] infoDictionary];
    NSString* version = [infoDict objectForKey:@"CFBundleVersion"];
    [self.timerStatusItem setToolTip:[NSString stringWithFormat:@"Timer v.%@", version]];
    //Enables highlighting
    [self.timerStatusItem setHighlightMode:YES];
    
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"show_timer" ] boolValue])
        [self.timerStatusItem setTitle:@"Starting..."];
    [self.active setTitle:@"Stop"];
    
    
}



/**
 *  remove status bar and other deallocation.
 *
 *  @param sender sender
 *
 *  @return status either to terminate or delay the termination.
 */

- (NSApplicationTerminateReply) applicationShouldTerminate:(id)sender
{
    
    NSLog(@"Terminating App.");
    [[NSStatusBar systemStatusBar] removeStatusItem:self.timerStatusItem];
    
    return NSTerminateNow;
    
}


- (void) setupPopupSound
{
    
    NSUserDefaults *dict = [NSUserDefaults standardUserDefaults];
    
    if (![dict objectForKey:@"popup_sound_path"])
    {
        [dict setObject:[NSString stringWithFormat:@"default"] forKey:@"popup_sound_path"];
    }
    if (![dict objectForKey:@"popup_sound"])
    {
        [dict setObject:[NSString stringWithFormat:@"default"] forKey:@"popup_sound"];
    }
    if (![dict objectForKey:@"popup_vol"])
    {
        [dict setObject:[NSNumber numberWithInteger:20] forKey:@"popup_vol"];
    }
}

- (void) setupBreakEndSound
{
    
    NSUserDefaults *dict = [NSUserDefaults standardUserDefaults];
    
    if (![dict objectForKey:@"break_end_sound_path"])
    {
        [dict setObject:[NSString stringWithFormat:@"default"] forKey:@"break_end_sound_path"];
    }
    if (![dict objectForKey:@"break_end_sound"])
    {
        [dict setObject:[NSString stringWithFormat:@"default"] forKey:@"break_end_sound"];
    }
    if (![dict objectForKey:@"break_end_vol"])
    {
        [dict setObject:[NSNumber numberWithInteger:20] forKey:@"break_end_vol"];
    }
}
- (void) setup_countdown_sound
{
    NSUserDefaults *dict = [NSUserDefaults standardUserDefaults];
    
    if (![dict objectForKey:@"countdown_music_sound_path"])
    {
        [dict setObject:[NSString stringWithFormat:@"default"] forKey:@"countdown_music_sound_path"];
    }
    if (![dict objectForKey:@"countdown_music_sound"])
    {
        [dict setObject:[NSString stringWithFormat:@"default"] forKey:@"countdown_music_sound"];
    }
    if (![dict objectForKey:@"countdown_music_vol"])
    {
        [dict setObject:[NSNumber numberWithInteger:20] forKey:@"countdown_music_vol"];
    }
    
    
    if (![dict objectForKey:@"count_down_minutes"])
    {
        [dict setObject:[NSNumber numberWithInt:1] forKey:@"count_down_minutes"];
    }
    
    if (![dict objectForKey:@"count_down_playOnce"])
    {
        [dict setObject:[NSNumber numberWithBool:YES] forKey:@"count_down_playOnce"];
    }
    
}
/**
 *  load preferences from disk
 */
- (void) loadPreferences
{
    NSLog(@"Loading Preferences");
    if  (![[NSUserDefaults standardUserDefaults] objectForKey:@"tick_vol"])
    {
        NSUserDefaults *dict = [NSUserDefaults standardUserDefaults];
        [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"25"] forKey:@"pomodor_interval"];
        [dict setObject:[NSString stringWithFormat:@"10"] forKey:@"log_interval"];
        [dict setObject:[NSString stringWithFormat:@"5"] forKey:@"short_break"];
        [dict setObject:[NSString stringWithFormat:@"20"] forKey:@"long_break"];
        [dict setObject:[NSString stringWithFormat:@"3"] forKey:@"long_break_after"];
        
        [dict setObject:[NSString stringWithFormat:@"default"] forKey:@"start_promo_sound"];
        [dict setObject:[NSString stringWithFormat:@"default"] forKey:@"short_break_sound"];
        [dict setObject:[NSString stringWithFormat:@"default"] forKey:@"long_break_sound"];
        [dict setObject:[NSString stringWithFormat:@"default"] forKey:@"tick_sound"];
        
        [dict setObject:[NSString stringWithFormat:@"default"] forKey:@"start_promo_sound_path"];
        [dict setObject:[NSString stringWithFormat:@"default"] forKey:@"short_break_sound_path"];
        [dict setObject:[NSString stringWithFormat:@"default"] forKey:@"long_break_sound_path"];
        [dict setObject:[NSString stringWithFormat:@"default"] forKey:@"tick_sound_path"];
        
        [dict setObject:[NSNumber numberWithInteger:20] forKey:@"start_promo_vol"];
        [dict setObject:[NSNumber numberWithInteger:20] forKey:@"short_break_vol"];
        [dict setObject:[NSNumber numberWithInteger:20] forKey:@"long_break_vol"];
        [dict setObject:[NSNumber numberWithInteger:20] forKey:@"tick_vol"];
        
        [dict setObject:[NSNumber numberWithBool:NO] forKey:@"show_timer"];
        
        [dict setObject:[NSNumber numberWithBool:NO] forKey:@"start_auto"];
        
        
    }
    else
    {
        NSUserDefaults *dict = [NSUserDefaults standardUserDefaults];
        
        self.countdown_minutes = [[dict objectForKey:@"count_down_minutes"] intValue];
        self.minutes =  [[[NSUserDefaults standardUserDefaults] objectForKey:@"pomodor_interval"] integerValue];
        self.totalSecondsToStay = self.minutes * 60;
        self.seconds = 0;
    }
}

- (void) update
{
    self.countdown_minutes = [[[NSUserDefaults standardUserDefaults] objectForKey:@"count_down_minutes"] intValue];
    
}
/**
 *  resets Pomo Timer
 */
- (void) resetPomoTimer
{
    
    [self.timer_updater invalidate];
    [self.long_timer invalidate];
    [self.short_timer  invalidate];
    [self.timer_updater invalidate];
    [self.pomo_timer invalidate];
    self.pomo_timer = nil;
    self.timer_updater = nil;
    self.long_timer = nil;
    self.short_timer = nil;
    self.timer_updater = nil;
    
    self.timer_updater = nil;
    self.totalPomodoro = 1;
    self.currentStatus = kDoingNothing;
    if ([self.active.title isEqualToString:@"Stop"])
        [self startNextPomo:YES];
    else
    {
        self.pomodoroTimerStr = @"00:00";
        if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"show_timer" ] boolValue])
            [self.timerStatusItem setTitle:@""];
        else
            [self.timerStatusItem setTitle:@""];
        
    }
}


/**
 *  when a pomo finishes
 */
- (void) pomoFinished
{
    dispatch_async(dispatch_get_main_queue(), ^{

    NSLog(@"Current Pomo Finished");
    NSInteger pomo_before_long_Break = [[[NSUserDefaults standardUserDefaults] objectForKey:@"long_break_after"] integerValue];
    if (self.totalPomodoro >= pomo_before_long_Break)
    {
        self.totalPomodoro = 1;
        [self longBreakStarted];
    }
    else
    {
        self.totalPomodoro++;
        [self shortBreakStarted];
    }
    });
}
/**
 *  starts a new pomo session
 */
- (void) startNextPomo:(BOOL)startMemo
{
    NSLog(@"Next Pomo Started");
    
    if ([self.mute state] == NSOffState)
    {
        [Utilities playSound:@"start_promo_sound" volumeKey:@"start_promo_vol" default:@"start"];
    }
    
    self.minutes = [[[NSUserDefaults standardUserDefaults] objectForKey:@"pomodor_interval"] integerValue];
    self.totalSecondsToStay = self.minutes * 60;
    self.countdown_music = NO;
    self.countdown_playcount = 0;
    self.seconds = 0;
    //if (!self.timer_updater)
    // self.timer_updater = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updatePomoTimer:) userInfo:nil repeats:YES];
    //  NSInteger interval = [[[NSUserDefaults standardUserDefaults] objectForKey:@"pomodor_interval"] intValue] * 60;
    // self.pomo_timer =  [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(pomoFinished) userInfo:nil repeats:NO];
    
    self.pomodoroTimerStr = [NSString stringWithFormat:@"%02ld:%02ld", (long)self.minutes, (long)self.seconds];
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"show_timer" ] boolValue])
        [self.timerStatusItem setAttributedTitle:[self.pomodoroTimerStr stringByAddingSpaceAttributes:2.f]];
    else
        [self.timerStatusItem setTitle:@""];
    
    self.currentStatus = kPomoInProgress;
    self.timerStatusImage = [NSImage imageNamed:@"pomo"];
    self.timerStatusHighlightImage =  self.timerStatusImage;
    [self.timerStatusItem setImage:self.timerStatusImage];
    
    if (startMemo)
    {
        self.playpopupSound = NO;
        [self alertMemoBox];
        self.playpopupSound = YES;
    }
}

/**
 *  when short break starts
 */
- (void) shortBreakStarted
{
    NSLog(@"Short Break Started.");
    
    self.currentStatus = kShortBreak;
    self.timerStatusImage = [NSImage imageNamed:@"break"];
    self.timerStatusHighlightImage =  self.timerStatusImage;
    [self.timerStatusItem setImage:self.timerStatusImage];
    
    [self.timerStatusItem setAlternateImage:self.timerStatusHighlightImage];
    if ([self.mute state] == NSOffState)
    {
        // sleep(2);
        [Utilities playSound:@"short_break_sound_path" volumeKey:@"short_break_vol" default:@"short"];
    }
    
    self.break_started = [BreakStarted getWindow];
    [self.break_started center];
    [self.break_started setLevel:NSFloatingWindowLevel];
    [self.break_started makeKeyAndOrderFront:self];
    
    [self.timer_updater invalidate];
    self.minutes = [[[NSUserDefaults standardUserDefaults] objectForKey:@"short_break"] integerValue];
    self.seconds = 0;
    self.totalSecondsToStay = self.minutes * 60;
    self.countdown_music = NO;
    self.countdown_playcount = 0;
    
    self.breakTimerStr = [NSString stringWithFormat:@"%02ld:%02ld", (long)self.minutes, (long)self.seconds];
    
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"show_timer" ] boolValue])
        [self.timerStatusItem setAttributedTitle:[self.breakTimerStr stringByAddingSpaceAttributes:2.f]];
    else
        [self.timerStatusItem setTitle:@""];
    
    // self.timer_updater = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updatePomoTimer:) userInfo:nil repeats:YES];
    
    // self.long_timer = [NSTimer scheduledTimerWithTimeInterval:[[[NSUserDefaults standardUserDefaults] objectForKey:@"short_break"] intValue] * 60 target:self selector:@selector(BreakEnded) userInfo:nil repeats:NO];
}

/**
 *  when long break starts
 */
- (void) longBreakStarted
{
    NSLog(@"Long Break Started");
    self.currentStatus = kLongBreak;
    self.timerStatusImage = [NSImage imageNamed:@"break"];
    self.timerStatusHighlightImage =  self.timerStatusImage;
    [self.timerStatusItem setImage:self.timerStatusImage];
    
    if ([self.mute state] == NSOffState)
    {
        [Utilities playSound:@"long_break_sound_path" volumeKey:@"long_break_vol" default:@"long"];
    }
    //pop up break ended.
    self.break_started = [BreakStarted getWindow];
    [self.break_started center];
    [self.break_started setLevel:NSFloatingWindowLevel];
    [self.break_started makeKeyAndOrderFront:self];
    
    
    [self.timer_updater invalidate];
    self.minutes = [[[NSUserDefaults standardUserDefaults] objectForKey:@"long_break"] integerValue];
    self.seconds = 0;
    self.totalSecondsToStay = self.minutes * 60;
    self.countdown_music = NO;
    self.countdown_playcount = 0;
    
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"show_timer" ] boolValue])
        [self.timerStatusItem setAttributedTitle:[self.breakTimerStr stringByAddingSpaceAttributes:2.f]];
    else
        [self.timerStatusItem setTitle:@""];
    
    
    // self.timer_updater = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updatePomoTimer:) userInfo:nil repeats:YES];
    
    
    // self.short_timer = [NSTimer scheduledTimerWithTimeInterval:[[[NSUserDefaults standardUserDefaults] objectForKey:@"long_break"] intValue] * 60 target:self selector:@selector(BreakEnded) userInfo:nil repeats:NO];
}

-(void) playBreakEndSound
{
    if ([self.mute state] == NSOffState)
    {
        
        [Utilities playSound:@"break_end_sound_path" volumeKey:@"break_end_vol" default:@"break_end"];
    }
}

//when long break ends.
- (void) BreakEnded
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSLog(@"Break Ended.");
        self.currentStatus = kDoingNothing;
        
        if (([[[NSUserDefaults standardUserDefaults] objectForKey:@"start_auto"] boolValue]))
        {
            [self.break_started close];
            [NSApp hide:self];
            [self startNextPomo:YES];
        }
        else
        {
            
            [self.break_started close];
            //pop up break ended.
            [self performSelectorOnMainThread:@selector(playBreakEndSound) withObject:nil waitUntilDone:YES];
            self.break_ended = [BreakEnded getWindow];
            [self.break_ended center];
            [self.break_ended setLevel:NSFloatingWindowLevel];
            [self.break_ended makeKeyAndOrderFront:self];
        }
    });
}

-(void) windowWillClose:(NSNotification *)notification
{
    if (notification.object == self.reportWindow)
        self.reportWindow = nil;
}

/**
 *  checks if egnyte Drive was added login items
 *
 *  @return YES if added otherwise false
 */
-(BOOL) itemExistsinLoginList
{
    
    BOOL exists = NO;
    NSString * appPath = [[NSBundle mainBundle] bundlePath];
    // This will retrieve the path for the application
    // For example, /Applications/test.app
    CFURLRef url = (__bridge CFURLRef)([NSURL fileURLWithPath:appPath]);
    // Create a reference to the shared file list.
    LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    if (loginItems) {
        UInt32 seedValue;
        //Retrieve the list of Login Items and cast them to
        // a NSArray so that it will be easier to iterate.
        NSArray *loginItemsArray = CFBridgingRelease(LSSharedFileListCopySnapshot(loginItems, &seedValue));
        for(int i = 0; i< [loginItemsArray count]; i++){
            LSSharedFileListItemRef currentItemRef = (LSSharedFileListItemRef)CFBridgingRetain([loginItemsArray objectAtIndex:i]);
            //Resolve the item with URL
            if (LSSharedFileListItemResolve(currentItemRef, 0, (CFURLRef*) &url, NULL) == noErr) {
                NSString * urlPath = [((NSURL *)CFBridgingRelease(url)) path];
                if ([urlPath compare:appPath] == NSOrderedSame){
                    exists = YES;
                }
            }
        }
    }
    CFRelease(loginItems);
    return exists;
    
}


/**
 *  adds Egnyte drive to startup lit
 */
-(void) addToLoginItem
{
    
    if ( [self itemExistsinLoginList] ) return;
    //    kLSSharedFileListSessionLoginItems
    NSString *strUserPath = [[NSBundle mainBundle] bundlePath];
    CFURLRef url = (CFURLRef)CFBridgingRetain([NSURL fileURLWithPath:strUserPath]);
    
    // Create a reference to the shared file list.
    LSSharedFileListRef favoriteItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    
    if (favoriteItems) {
        //Insert an item to the list.
        LSSharedFileListItemRef item = LSSharedFileListInsertItemURL(favoriteItems,                                                                     kLSSharedFileListItemLast, NULL, NULL,                                                                     url, NULL, NULL);
        if (item){
            CFRelease(item);
        }
    }
    
    CFRelease(favoriteItems);
}

//sets up rest of the app things
- (void) setupApp
{
    self.currentStatus = kDoingNothing;
    
    [self performSelectorInBackground:@selector(playTick) withObject:nil];
    [self performSelectorInBackground:@selector(backgroundThread) withObject:nil];
    //setup default time interval for poping up memo window, if not set by user in preferences window.
    NSNumber *number = [[NSUserDefaults standardUserDefaults] objectForKey:@"timeInterval"];
    if (!number)
    {
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:10] forKey:@"timeInterval"];
    }
    
    //added esc key controller
    NSEvent* (^handler)(NSEvent*) = ^(NSEvent *theEvent) {
        NSWindow *targetWindow = theEvent.window;
        if (theEvent.keyCode == 53) {
            if (targetWindow == self.window) {
                [self.window orderOut:self];
                [NSApp hide:self];
                return theEvent;
            }
            else if (targetWindow == self.pref_window)
            {
                [self.pref_window orderOut:self];
                [NSApp hide:self];
            }
            else if (targetWindow == self.moreClient)
            {
                [self.moreClient close];
                [NSApp hide:self];
                self.moreClient = nil;
            }
            else if (targetWindow == self.break_ended)
            {
                [(BreakEnded *)self.break_ended stop:self];
                [NSApp hide:self];
            }
            else
            {
                if (![targetWindow isKindOfClass:[NSSavePanel class] ])
                    [targetWindow close];
            }
        }
        
        
        NSEvent *result = theEvent;
        return result;
    };
    [self setupPopupSound];
    [self setup_countdown_sound];
    [self setupBreakEndSound];
    NSDictionary *recent_Values = [[NSUserDefaults standardUserDefaults] persistentDomainForName:[[NSBundle mainBundle] bundleIdentifier ]];
    
    for (id key in recent_Values)
    {
        NSLog(@"%@ = %@", key, [recent_Values objectForKey:key]);
    }
    
    
    self.preferencesWindowClosed = YES;
    self.countdown_music = NO;
    self.eventMonitor = [NSEvent addLocalMonitorForEventsMatchingMask:NSKeyDownMask handler:handler];
    [self.mute setState:NSOffState];
    [self loadPreferences];
    //popup the memo box.
    
    
    // [NSTimer scheduledTimerWithTimeInterval:1.1 target:self selector:@selector(launchAlertMemoOnStartup:) userInfo:nil repeats:NO];
    
    [self startNextPomo:YES];
    
}

-(void) saveReportForClients:(NSString *)clientName
{
    //popup save panel.
    NSSavePanel *save = [NSSavePanel savePanel];
    NSString *lastPath = [[NSUserDefaults standardUserDefaults] objectForKey:@"directory_selected"];
    if (lastPath)
    {
        [save setDirectoryURL:[NSURL fileURLWithPath:lastPath]];
    }
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"YYYY-MM-dd hhmma"];
    
    //Optionally for time zone converstions
    [formatter setTimeZone:[NSTimeZone timeZoneWithName:@"..."]];
    
    NSString *stringFromDate = [formatter stringFromDate:[NSDate date]];
    
    [save setNameFieldStringValue:[NSString stringWithFormat:@"%@ Activity Report %@", clientName, stringFromDate]];
    long result = [save runModal];
    
    //user made a selection
    if (result == NSOKButton){
        NSError *err;
        NSString *selectedFile = [[[save URL] path] stringByAppendingPathExtension:@"csv"];
        
        [[NSUserDefaults standardUserDefaults] setObject:[selectedFile stringByDeletingLastPathComponent] forKey:@"directory_selected"];
        //get the CSV string from database
        NSArray *logs = [[TimerDatabase sharedInstance] getLogsAsCSV:@[clientName]];
        
        NSLog(@"Saving report to file %@", selectedFile);
        //write to the file.
        NSOutputStream *output = [NSOutputStream outputStreamToFileAtPath:selectedFile append:NO];
        
        CHCSVWriter *writer = [[CHCSVWriter alloc] initWithOutputStream:output encoding:NSUTF8StringEncoding delimiter:','];
        for (NSArray *line in logs) {
            [writer writeLineOfFields:line];
        }
        [writer closeStream];
        
        //error?
        if (err)
        {
            NSAlert *alert = [[NSAlert alloc] init];
            [alert setMessageText:[NSString stringWithFormat:@"Logs couldn't be saved. %@", [err description]]];
            [alert runModal];
            return;
        }
        
        //success? clear database
        [[TimerDatabase sharedInstance] removeLogsForclients:@[clientName]];
        
    }
}

-(IBAction) ReportOK:(id)sender
{
    //prepare a report
    
    //nothing is selected.
    if (self.reportTable.selectedRow < 0) {
        return;
    }
    
    [self.reportWindow setLevel:NSNormalWindowLevel];
    NSDictionary *dict = self.clientFromDB[self.reportTable.selectedRow];
    
    NSString *selectedClient = [dict objectForKey:@"title"];
    [self saveReportForClients:selectedClient];
    
    
    [self.reportWindow close];
}
-(IBAction) ReportCancel:(id)sender
{
    //cancel
    [self.reportWindow close];
    
}

@end

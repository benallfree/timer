//
//  TimerDatabase.h
//  Timer
//
//  Created by jenkins on 6/20/14.
//  Copyright (c) 2014 GreatBasinGroup. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Cocoa/Cocoa.h>

#include "sqlite3.h"




@interface TimerDatabase : NSObject {
    
	sqlite3 *m_dbHandle;
	
}

+(TimerDatabase *) sharedInstance;
-(BOOL) openTimerDatabase:(NSString *)path;
-(BOOL) createTimerDB:(NSString *)path;
- (NSString *) TimerDbVersion;
- (BOOL) insertTimerDBVersion;
-(BOOL) insertClient:(NSString *)Client;
-(BOOL) insertLog:(NSString *)logs forClient:(long long)client;
-(long long) getClientID:(NSString *)clientname;
-(NSArray *) getClients;

-(NSArray *) getLogsForClient:(long long)client;
-(NSArray *) getRecentLogsForClient:(long long)client;
-(NSArray *) getLogsAsCSV:(NSArray *)clients;
-(int) bindVariable:(int)index textValue:(NSString *)text int64Value:(long long)intValue context: (sqlite3_stmt *)statement useText:(BOOL)flag useFSR:(BOOL)fsFlag;
-(void) removeLogs;
-(BOOL) LogsAvailableToReport;
-(void) removeLogsForclients:(NSArray *)clients;
@end

//
//  CTCallCenter.h
//  CoreTelephony
//
//  Created by H. Nikolaus Schaller on 04.07.11.
//  Copyright 2011 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CTCall;

// extension

@protocol CTCallCenterDelegate
- (BOOL) handleCallEvent:(CTCall *) call;
@end

@interface CTCallCenter : NSObject
{
	NSMutableSet *currentCalls;
	id <CTCallCenterDelegate> delegate;
}

// @property (nonatomic, copy) void (^callEventHandler)(CTCall *)

- (NSSet *) currentCalls;
   
@end

@interface CTCallCenter (Extensions)

- (id <CTCallCenterDelegate>) delegate;
- (void) setDelegate:(id <CTCallCenterDelegate>) d;

- (CTCall *) dial:(NSString *) number;
- (BOOL) sendSMS:(NSString *) number message:(NSString *) message;

@end

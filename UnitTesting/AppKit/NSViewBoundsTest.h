//
//  NSViewBoundsTest.h
//  UnitTests
//
//  Created by H. Nikolaus Schaller on 27.12.12.
//  Copyright 2012 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import <Cocoa/Cocoa.h>


@interface NSViewBoundsTest : SenTestCase {
	NSView *view;
	NSRect has, want;
}

@end
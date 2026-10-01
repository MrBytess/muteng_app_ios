//
//  RunnerTests.m
//  RunnerTests
//
//  Copyright © 2026. All rights reserved.
//

#import <XCTest/XCTest.h>

@interface RunnerTests : XCTestCase

@end

@implementation RunnerTests

- (void)testExpectsApplicationLaunch {
  BOOL failureFileFound = NO;
  NSRange range = [[NSHomeDirectory() rangeOfString:@"*Tests.xctest*"] location];
  if (range.location != NSNotFound) {
    failureFileFound = YES;
  }
  XCTAssertTrue(failureFileFound, @"RunnerTests.xctest not found");
}

@end

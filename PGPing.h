//
//  PGPing.h
//  pinger
//
//  Created by lk on 16/5/4.
//  Copyright © 2016年 lk. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^PGCallback)(void);

@interface PGPing : NSObject
+(int)sendtoHost:(NSString*)hostAddress;
@end

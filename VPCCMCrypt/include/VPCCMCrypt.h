//
//  VPCCMCrypt.h
//  VPCCMCrypt
//
//  Created by Bill Panagiotopoulos on 3/23/14.
//  Copyright (c) 2014. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VPCCM.h"

@interface VPCCMCrypt : NSObject {
    NSInteger _tagLength, _bufferSize, _blockSize;
    
    long long _bytesLeft;
    NSData *_key, *_iv, *_adata;
}

- (instancetype)initWithKey:(NSData *)key
                         iv:(NSData *)iv
                      adata:(NSData *)adata
                  tagLength:(NSInteger)tagLength;

- (NSData*)encryptDataWithData:(NSData *)data;

- (NSData*)decryptDataWithData:(NSData *)data;

@end

 //
//  VPCCMCrypt.m
//  VPCCMCrypt
//
//  Created by Bill Panagiotopoulos on 3/23/14.
//  Copyright (c) 2014. All rights reserved.
//

#import "VPCCMCrypt.h"
#import "VPCCM.h"
#import <CommonCrypto/CommonCryptor.h>

#define _blocksCount 1024

NSString *const VPCCMCryptErrorDomain  = @"com.vpccmcrypt.CryptError";

@implementation VPCCMCrypt

- (instancetype)initWithKey:(NSData *)key
                         iv:(NSData *)iv
                      adata:(NSData *)adata
                  tagLength:(NSInteger)tagLength {

    if (self = [super init]) {
        _key = key;
        _iv = iv;
        _adata = adata;
        _tagLength = tagLength;
        _blockSize = kCCBlockSizeAES128;
        _bufferSize = _blocksCount * _blockSize;

    }
    
    return self;
    
}

- (NSData*)encryptDataWithData:(NSData *)data {
    NSInteger loopCount = ceil(data.length/(float)_bufferSize);
    
    VPCCM *ccmIstance = [[VPCCM alloc] initWithKey:_key
                                                iv:_iv
                                             adata:_adata
                                         tagLength:_tagLength
                                          fileSize:data.length];
    
    NSMutableData *cipher = [[NSMutableData alloc] init];
    
    unsigned char *bytes = (unsigned char *)[data bytes];
    
    for (NSInteger i = 0; i < loopCount; i++) {
        NSData *encrypted = nil;
        if (i != loopCount - 1) {
            encrypted = [[NSData alloc] initWithBytes:[ccmIstance encryptBlock:bytes + i*_bufferSize
                                                                        length:_bufferSize]
                                                                        length:_bufferSize];
        } else {
            NSInteger len = data.length%_bufferSize;
            encrypted = [[NSData alloc] initWithBytes:[ccmIstance encryptBlock:bytes + i*_bufferSize
                                                                        length:len]
                                                                        length:len];
        }
        
        if (ccmIstance.errorMessage != nil) {
            return nil;
        }
        
        [cipher appendData:encrypted];
    }
    
    NSData *tag = [ccmIstance getTag];
    
    [cipher appendData:tag];

    return cipher;
}

- (NSData*)decryptDataWithData:(NSData *)data {
    if (data.length <= _tagLength) {
        NSLog(@"Cipher text is too short");
        return nil;
    }
    
    NSData *dataPart = [data subdataWithRange:NSMakeRange(0, data.length-_tagLength)];
    
    _bytesLeft = dataPart.length;
    
    VPCCM *ccmIstance = [[VPCCM alloc] initWithKey:_key
                                                iv:_iv
                                             adata:_adata
                                         tagLength:_tagLength
                                          fileSize:data.length];
    
    if ([ccmIstance verifyTagWithData:data]) {
        [ccmIstance initialize];
        
        NSInteger loopCount = ceil(dataPart.length/(float)_bufferSize);
        
        NSMutableData *plain = [[NSMutableData alloc] init];
        
        unsigned char *bytes = (unsigned char *)[data bytes];
        
        for (NSInteger i = 0; i < loopCount; i++) {
            NSData *decrypted = nil;
            
            if (i != loopCount-1) {
                
                decrypted = [[NSData alloc] initWithBytes:[ccmIstance decryptBlock:bytes + i*_bufferSize
                                                                            length:_bufferSize
                                                                          exitNext:NULL]
                                                                            length:_bufferSize];
                
            } else {
                NSInteger len = dataPart.length%_bufferSize;
                
                decrypted = [[NSData alloc] initWithBytes:[ccmIstance decryptBlock:bytes + i*   _bufferSize
                                                                            length:len
                                                                          exitNext:NULL]
                                                                            length:len];
            }
            
            if (ccmIstance.errorMessage != nil) {
                [ccmIstance freemem];
                return nil;
            }
            
            [plain appendData:decrypted];
        }
        
        [ccmIstance freemem];
        return plain;
    } else {
        [ccmIstance freemem];
        return nil;
    }
}

@end

#import "FQAESUitil.h"
#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonDigest.h>

@implementation FQAESUitil

+ (NSData *) AESEncryptWithKey:(NSString *)key withData:(NSData *) data{
    char keyPtr[kCCKeySizeAES128+1]; // room for terminator (unused)
    bzero(keyPtr, sizeof(keyPtr)); // fill with zeroes (for padding)
    
    // fetch key data
    [key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    
    NSUInteger dataLength = [data length];
    
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);
    
    size_t numBytesEncrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding,
                                          keyPtr, kCCKeySizeAES128,
                                          NULL /* initialization vector (optional) */,
                                          [data bytes], dataLength, /* input */
                                          buffer, bufferSize, /* output */
                                          &numBytesEncrypted);
    if (cryptStatus == kCCSuccess) {
        //the returned NSData takes ownership of the buffer and will free it on deallocation
        NSData * returnValue = [NSData dataWithBytesNoCopy:buffer length:numBytesEncrypted];
        return returnValue;
    } else {
    }
    free(buffer); //free the buffer;
    return nil;
}

+ (NSData *) calculateHash:(NSData *) data withCryptKey:(NSString*) cryptKey {
    NSMutableData* doubleData = [NSMutableData dataWithCapacity:16];
    [doubleData appendBytes:[data bytes] length:8];
    [doubleData appendBytes:[data bytes] length:8];

    NSData* aesBytes = [self AESEncryptWithKey:cryptKey withData:doubleData];
    
    NSMutableData* returnValue =[NSMutableData dataWithCapacity:8];
    [returnValue appendBytes:[aesBytes bytes] length:8];
    return returnValue;
}

@end

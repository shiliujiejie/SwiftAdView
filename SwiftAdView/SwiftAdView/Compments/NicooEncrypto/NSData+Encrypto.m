

#import "NSData+Encrypto.h"
#import <CommonCrypto/CommonCrypto.h>

@implementation NSData (Encrypto)

- (NSData *)AES128EncryptWithKey:(NSString *)key {
    char keyPtr[kCCKeySizeAES128 + 1];
    bzero(keyPtr, sizeof(keyPtr));
    [key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    
    NSInteger dataLength = [self length];
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);
    size_t numBytesEncrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt,
                                          kCCAlgorithmAES128,
                                          kCCOptionPKCS7Padding | kCCOptionECBMode,/*这里就是刚才说到的PKCS7Padding填充了*/
                                          keyPtr,
                                          kCCKeySizeAES128,
                                          NULL, /*初始化向量在ecb模式下为空*/
                                          [self bytes], dataLength, /*输入*/
                                          buffer, bufferSize, /*输出*/
                                          &numBytesEncrypted);
    if (cryptStatus == kCCSuccess) {
        return [NSData dataWithBytesNoCopy:buffer length:numBytesEncrypted freeWhenDone:true];
    }
    free(buffer);
    return nil;
}

- (NSData *)AES128DecryptWidthKey:(NSString *)key {
    char keyPtr[kCCKeySizeAES128 + 1];
    bzero(keyPtr, sizeof(keyPtr));
    [key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    
    NSInteger dataLength = [self length];
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);
    size_t numBytesEncrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt,
                                          kCCAlgorithmAES128,
                                          kCCOptionPKCS7Padding | kCCOptionECBMode,/*这里就是刚才说到的PKCS7Padding填充了*/
                                          keyPtr,
                                          kCCKeySizeAES128,
                                          NULL, /*初始化向量在ecb模式下为空*/
                                          [self bytes], dataLength, /*输入*/
                                          buffer, bufferSize, /*输出*/
                                          &numBytesEncrypted);
    if (cryptStatus == kCCSuccess) {
        return [NSData dataWithBytesNoCopy:buffer length:numBytesEncrypted freeWhenDone:true];
    }
    free(buffer);
    return nil;
}

@end

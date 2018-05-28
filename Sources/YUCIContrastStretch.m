//
//  YUCIContrastStretch.m
//  Pods
//
//  Created by YuAo on 2/15/16.
//
//

#import "YUCIContrastStretch.h"
#import "YUCIFilterConstructor.h"
#import <Accelerate/Accelerate.h>

@interface YUCIContrastStretch ()

@property (nonatomic, strong) CIContext *context;

@end

@implementation YUCIContrastStretch

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        @autoreleasepool {
            if ([CIFilter respondsToSelector:@selector(registerFilterName:constructor:classAttributes:)]) {
                [CIFilter registerFilterName:NSStringFromClass([YUCIContrastStretch class])
                                 constructor:[YUCIFilterConstructor constructor]
                             classAttributes:@{kCIAttributeFilterCategories: @[kCICategoryStillImage,kCICategoryVideo,kCICategoryColorAdjustment],
                                               kCIAttributeFilterDisplayName: @"Contrast Stretch"}];
            }
        }
    });
}

- (CIContext *)context {
    if (!_context) {
        _context = [CIContext contextWithOptions:@{kCIContextWorkingColorSpace: CFBridgingRelease(CGColorSpaceCreateWithName(kCGColorSpaceSRGB))}];
    }
    return _context;
}

- (NSNumber *)inputPercentLow {
    if (!_inputPercentLow) {
        _inputPercentLow = @(0.0);
    }
    return _inputPercentLow;
}

- (NSNumber *)inputPercentHigh {
    if (!_inputPercentHigh) {
        _inputPercentHigh = @(0.0);
    }
    return _inputPercentHigh;
}

- (CIImage *)outputImage {
    if (!self.inputImage) {
        return nil;
    }
    
    ptrdiff_t rowBytes = self.inputImage.extent.size.width * 4; // ARGB has 4 components
    uint8_t *byteBuffer = calloc(rowBytes * self.inputImage.extent.size.height, sizeof(uint8_t)); // Buffer to render into
    [self.context render:self.inputImage
                toBitmap:byteBuffer
                rowBytes:rowBytes
                  bounds:self.inputImage.extent
                  format:kCIFormatARGB8
              colorSpace:self.context.workingColorSpace];
    
    vImage_Buffer vImageBuffer;
    vImageBuffer.data = byteBuffer;
    vImageBuffer.width = self.inputImage.extent.size.width;
    vImageBuffer.height = self.inputImage.extent.size.height;
    vImageBuffer.rowBytes = rowBytes;
    
    unsigned percentLowValue = (unsigned)(_inputPercentLow.doubleValue * 100 + 0.5);
    unsigned percentLow[] = { percentLowValue, percentLowValue, percentLowValue, percentLowValue };
    unsigned percentHighValue = (unsigned)(_inputPercentHigh.doubleValue * 100 + 0.5);
    unsigned percentHigh[] = { percentHighValue, percentHighValue, percentHighValue, percentHighValue };
    vImageEndsInContrastStretch_ARGB8888(&vImageBuffer, &vImageBuffer, percentLow, percentHigh, kvImageNoFlags);
    
    NSData *bitmapData = [NSData dataWithBytesNoCopy:vImageBuffer.data length:vImageBuffer.rowBytes * vImageBuffer.height freeWhenDone:YES];
    CIImage *result = [[CIImage alloc] initWithBitmapData:bitmapData bytesPerRow:vImageBuffer.rowBytes size:CGSizeMake(vImageBuffer.width, vImageBuffer.height) format:kCIFormatARGB8 colorSpace:self.context.workingColorSpace];
    return result;
}

@end

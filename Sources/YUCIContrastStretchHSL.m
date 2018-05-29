//
//  YUCIContrastStretchHSL.m
//  Pods
//
//  Created by YuAo on 2/15/16.
//
//

#import "YUCIContrastStretchHSL.h"
#import "YUCIFilterConstructor.h"
#import <Accelerate/Accelerate.h>

@interface YUCIContrastStretchHSL ()

@property (nonatomic, strong) CIContext *context;

@end

@implementation YUCIContrastStretchHSL

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        @autoreleasepool {
            if ([CIFilter respondsToSelector:@selector(registerFilterName:constructor:classAttributes:)]) {
                [CIFilter registerFilterName:NSStringFromClass([YUCIContrastStretchHSL class])
                                 constructor:[YUCIFilterConstructor constructor]
                             classAttributes:@{kCIAttributeFilterCategories: @[kCICategoryStillImage,kCICategoryVideo,kCICategoryColorAdjustment],
                                               kCIAttributeFilterDisplayName: @"Contrast Stretch (HSL)"}];
            }
        }
    });
}

+ (CIColorKernel *)RGBToHSLKernel {
    static CIColorKernel *kernel;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *kernelString = [[NSString alloc] initWithContentsOfURL:[[NSBundle bundleForClass:self] URLForResource:@"YUCIRGBToHSL" withExtension:@"cikernel"] encoding:NSUTF8StringEncoding error:nil];
        kernel = [CIColorKernel kernelWithString:kernelString];
    });
    return kernel;
}

+ (CIColorKernel *)HSLToRGBKernel {
    static CIColorKernel *kernel;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *kernelString = [[NSString alloc] initWithContentsOfURL:[[NSBundle bundleForClass:self] URLForResource:@"YUCIHSLToRGB" withExtension:@"cikernel"] encoding:NSUTF8StringEncoding error:nil];
        kernel = [CIColorKernel kernelWithString:kernelString];
    });
    return kernel;
}

- (CIContext *)context {
    if (!_context) {
        _context = [CIContext contextWithOptions:@{kCIContextWorkingColorSpace: CFBridgingRelease(CGColorSpaceCreateWithName(kCGColorSpaceLinearSRGB))}];
    }
    return _context;
}

- (NSNumber *)inputSaturationEnabled {
    if (!_inputSaturationEnabled) {
        _inputSaturationEnabled = @(YES);
    }
    return _inputSaturationEnabled;
}

- (NSNumber *)inputSaturationPercentLow {
    if (!_inputSaturationPercentLow) {
        _inputSaturationPercentLow = @(0.0);
    }
    return _inputSaturationPercentLow;
}

- (NSNumber *)inputSaturationPercentHigh {
    if (!_inputSaturationPercentHigh) {
        _inputSaturationPercentHigh = @(0.0);
    }
    return _inputSaturationPercentHigh;
}

- (NSNumber *)inputLightnessEnabled {
    if (!_inputLightnessEnabled) {
        _inputLightnessEnabled = @(YES);
    }
    return _inputLightnessEnabled;
}

- (NSNumber *)inputLightnessPercentLow {
    if (!_inputLightnessPercentLow) {
        _inputLightnessPercentLow = @(0.0);
    }
    return _inputLightnessPercentLow;
}

- (NSNumber *)inputLightnessPercentHigh {
    if (!_inputLightnessPercentHigh) {
        _inputLightnessPercentHigh = @(0.0);
    }
    return _inputLightnessPercentHigh;
}

- (CIImage *)outputImage {
    if (!self.inputImage) {
        return nil;
    }
    
    CIImage *inputImage = [[[self class] RGBToHSLKernel] applyWithExtent:self.inputImage.extent arguments:@[self.inputImage]];
    
    ptrdiff_t rowBytes = inputImage.extent.size.width * 4; // ARGB has 4 components
    uint8_t *byteBuffer = calloc(rowBytes * inputImage.extent.size.height, sizeof(uint8_t)); // Buffer to render into

    [self.context render:inputImage
                toBitmap:byteBuffer
                rowBytes:rowBytes
                  bounds:inputImage.extent
                  format:kCIFormatARGB8
              colorSpace:self.context.workingColorSpace];
    
    ptrdiff_t planarRowBytes = inputImage.extent.size.width;
    uint8_t *planarBuffer = calloc(planarRowBytes * inputImage.extent.size.height, sizeof(uint8_t));

    vImage_Buffer vImageBuffer;
    vImageBuffer.data = planarBuffer;
    vImageBuffer.width = inputImage.extent.size.width;
    vImageBuffer.height = inputImage.extent.size.height;
    vImageBuffer.rowBytes = planarRowBytes;
    
    if (self.inputSaturationEnabled.boolValue) {
        [self getPlane:&vImageBuffer channel:2 bitmap:byteBuffer stride:rowBytes];
        vImageEndsInContrastStretch_Planar8(&vImageBuffer, &vImageBuffer, [self percents:self.inputSaturationPercentLow], [self percents:self.inputSaturationPercentHigh], kvImageNoFlags);
        [self setPlane:&vImageBuffer channel:2 bitmap:byteBuffer stride:rowBytes];
    }
    
    if (self.inputLightnessEnabled.boolValue) {
        [self getPlane:&vImageBuffer channel:3 bitmap:byteBuffer stride:rowBytes];
        vImageEndsInContrastStretch_Planar8(&vImageBuffer, &vImageBuffer, [self percents:self.inputLightnessPercentLow], [self percents:self.inputLightnessPercentHigh], kvImageNoFlags);
        [self setPlane:&vImageBuffer channel:3 bitmap:byteBuffer stride:rowBytes];
    }

    free(planarBuffer);
    
    NSData *bitmapData = [NSData dataWithBytesNoCopy:byteBuffer length:rowBytes * inputImage.extent.size.height freeWhenDone:YES];
    CIImage *result = [[CIImage alloc] initWithBitmapData:bitmapData bytesPerRow:rowBytes size:inputImage.extent.size format:kCIFormatARGB8 colorSpace:self.context.workingColorSpace];
    
    return [[[self class] HSLToRGBKernel] applyWithExtent:result.extent arguments:@[result]];
}

- (unsigned int)percents:(NSNumber *)number {
    return (unsigned int)(number.floatValue * 100);
}

- (void)getPlane:(vImage_Buffer *)vImageBuffer channel:(int)channel bitmap:(uint8_t *)byteBuffer stride:(ptrdiff_t)rowBytes {
    for (long y = (long)vImageBuffer->height; y-- > 0; ) {
        for (long x = (long)vImageBuffer->width; x-- > 0; ) {
            ((uint8_t *)vImageBuffer->data)[vImageBuffer->rowBytes * y + x] = byteBuffer[rowBytes * y + x * 4 + channel];
        }
    }
}

- (void)setPlane:(vImage_Buffer *)vImageBuffer channel:(int)channel bitmap:(uint8_t *)byteBuffer stride:(ptrdiff_t)rowBytes {
    for (long y = (long)vImageBuffer->height; y-- > 0; ) {
        for (long x = (long)vImageBuffer->width; x-- > 0; ) {
            byteBuffer[rowBytes * y + x * 4 + channel] = ((uint8_t *)vImageBuffer->data)[vImageBuffer->rowBytes * y + x];
        }
    }
}

@end

//
//  YUCIContrastStretch.h
//  Pods
//
//  Created by YuAo on 2/15/16.
//
//

#import <CoreImage/CoreImage.h>

@interface YUCIContrastStretch : CIFilter

@property (nonatomic, strong, nullable) CIImage *inputImage;

@property (nonatomic, copy, null_resettable) NSNumber *inputPercentLow; //default 0.0;

@property (nonatomic, copy, null_resettable) NSNumber *inputPercentHigh; //default 0.0;

@end

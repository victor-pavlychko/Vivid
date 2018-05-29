//
//  YUCIContrastStretchHSL.h
//  Pods
//
//  Created by YuAo on 2/15/16.
//
//

#import <CoreImage/CoreImage.h>

@interface YUCIContrastStretchHSL : CIFilter

@property (nonatomic, strong, nullable) CIImage *inputImage;

@property (nonatomic, copy, null_resettable) NSNumber *inputSaturationEnabled; //default YES;

@property (nonatomic, copy, null_resettable) NSNumber *inputSaturationPercentLow; //default 0.0;

@property (nonatomic, copy, null_resettable) NSNumber *inputSaturationPercentHigh; //default 0.0;

@property (nonatomic, copy, null_resettable) NSNumber *inputLightnessEnabled; //default YES;

@property (nonatomic, copy, null_resettable) NSNumber *inputLightnessPercentLow; //default 0.0;

@property (nonatomic, copy, null_resettable) NSNumber *inputLightnessPercentHigh; //default 0.0;

@end

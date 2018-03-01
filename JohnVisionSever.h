//
//  JohnVisionSever.h
//  ArcFace
//
//  Created by holdtime on 2018/3/1.
//  Copyright © 2018年 ArcSoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@interface JohnVisionSever : NSObject

/**
  用于图像人脸比对

 @param regist 输入基本图像
 @param compare 输入比对图像
 @param complete 输出比对结果
 分别对应 错误类型
 error_regist  基本
 error_compare 比对
 error_reslut 结果
 compareReslut- 输出结果
 其中 1000 1000 1000 - 将输出比对结果 其他结果为0
 */
+ (void)doRecognitionWithRegistImage:(UIImage *)regist
                             compare:(UIImage *)compare
                              result:(void(^)(int error_regist,int error_compare,int error_reslut, float compareReslut))complete;


@end

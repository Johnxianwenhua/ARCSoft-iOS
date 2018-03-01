//
//  JohnVisionSever.m
//  ArcFace
//
//  Created by holdtime on 2018/3/1.
//  Copyright © 2018年 ArcSoft. All rights reserved.
//

#import "JohnVisionSever.h"
#import <arcsoft_fsdk_face_detection/arcsoft_fsdk_face_detection.h>
#import <arcsoft_fsdk_face_recognition/arcsoft_fsdk_face_recognition.h>
#import <string.h>
#import "Utility.h"
#import "asvloffscreen.h"
#import "ammem.h"
#import "merror.h"

#define AFR_DEMO_APP_ID         ""

#define AFR_DEMO_SDK_FD_KEY     ""
#define AFR_DEMO_SDK_FR_KEY     ""

#define AFR_DEMO_SDK_FT_KEY     ""
#define AFR_DEMO_SDK_AGE_KEY    ""
#define AFR_DEMO_SDK_GENDER_KEY ""

#define AFR_FD_MEM_SIZE         1024*1024*50
#define AFR_FR_MEM_SIZE         1024*1024*40
#define AFR_FD_MAX_FACE_NUM     4

#define JOHNVISIONERROR_NULL    {0}

#define JOHNVISIONERROR_00    1000

#define JOHNVISIONERROR_01    1001  //初始化人脸检测引擎失败
#define JOHNVISIONERROR_02    1002  //初始化人脸识别引擎失败

#define JOHNVISIONERROR_03    2001  //图片人脸检测失败
#define JOHNVISIONERROR_04    2002  //图片 没有人脸
#define JOHNVISIONERROR_05    2003  //图片 人脸多

#define JOHNVISIONERROR_06    3001  //图片人脸特征提取失败

#define JOHNVISIONERROR_07    4001  //释放人脸检测引擎失败
#define JOHNVISIONERROR_08    4002  //释放人脸识别引擎失败

#define JOHNVISIONERROR_09    5001  //人脸比对失败


typedef struct
{
    MInt32 lFeatureSize; MByte *pbFeature;
}AFR_FSDK_FACEDATA, *LPAFR_FSDK_FACEDATA;

typedef struct
{
    MLong lPersonID;
    MChar szPersonName[128];
    AFR_FSDK_FACEDATA* pFaceFeatureArray;
    MInt32 nFeatureCount;
}AFR_FSDK_PERSON, *LPAFR_FSDK_PERSON;


@implementation JohnVisionSever

+ (void)doRegister:(UIImage *)image reslut:(void(^)(int error,AFR_FSDK_PERSON person))complete {
    
    MHandle handle_FD;
    MVoid* memBuffer_FD = MMemAlloc(MNull, AFR_FD_MEM_SIZE);
    MMemSet(memBuffer_FD, 0, AFR_FD_MEM_SIZE);
    MRESULT result_FD = AFD_FSDK_InitialFaceEngine((MPChar)AFR_DEMO_APP_ID,
                                                   (MPChar)AFR_DEMO_SDK_FD_KEY,
                                                   (MByte*)memBuffer_FD,
                                                   AFR_FD_MEM_SIZE, &handle_FD, AFD_FSDK_OPF_0_HIGHER_EXT, 16, AFR_FD_MAX_FACE_NUM);
    NSAssert(result_FD == MOK, @"error -- 00001");
    
    if( result_FD != MOK ){complete(JOHNVISIONERROR_01,JOHNVISIONERROR_NULL); return;}
    
    //    初始化人脸识别
    MHandle handle_FR;
    MVoid* memBuffer_FR = MMemAlloc(MNull,AFR_FR_MEM_SIZE);
    MMemSet(memBuffer_FR, 0, AFR_FR_MEM_SIZE);
    MRESULT result_FR = AFR_FSDK_InitialEngine((MPChar)AFR_DEMO_APP_ID,
                                               (MPChar)AFR_DEMO_SDK_FR_KEY,
                                               (MByte*)memBuffer_FR, AFR_FR_MEM_SIZE, &handle_FR);
    
    if( result_FR != MOK ){complete(JOHNVISIONERROR_02,JOHNVISIONERROR_NULL);return;}
    
    LPASVLOFFSCREEN pOffscreen = [Utility createOffscreenwithUImage:image];
    
    LPAFD_FSDK_FACERES pFaceResFD = MNull;
    
    MRESULT result_FD_FACE = AFD_FSDK_StillImageFaceDetection(handle_FD, pOffscreen, &pFaceResFD);
    
    if( result_FD_FACE != MOK ){complete(JOHNVISIONERROR_03,JOHNVISIONERROR_NULL);return;}
    
    if( pFaceResFD->nFace == 0 ){complete(JOHNVISIONERROR_04,JOHNVISIONERROR_NULL);return;}
    if( pFaceResFD->nFace  > 1 ){complete(JOHNVISIONERROR_05,JOHNVISIONERROR_NULL);return;}
    
    AFR_FSDK_FACEINPUT faceInput = {0};
    
    faceInput.rcFace = pFaceResFD->rcFace[0];
    faceInput.lOrient = pFaceResFD->lfaceOrient[0];
    
    AFR_FSDK_FACEMODEL faceModel = {0};
    //提取人脸特性信息
    MRESULT result_FD_Feature = AFR_FSDK_ExtractFRFeature(handle_FR, pOffscreen, &faceInput, &faceModel);
    if( result_FD_Feature != MOK ){complete(JOHNVISIONERROR_06,JOHNVISIONERROR_NULL);return;}

    AFR_FSDK_FACEDATA featureData = {0};
    featureData.lFeatureSize = faceModel.lFeatureSize;
    featureData.pbFeature = (MByte*)MMemAlloc(MNull, featureData.lFeatureSize);
    MMemCpy(featureData.pbFeature, faceModel.pbFeature, featureData.lFeatureSize);
    
    AFR_FSDK_PERSON person = {0};
    person.nFeatureCount = pFaceResFD->nFace;
    person.pFaceFeatureArray = (AFR_FSDK_FACEDATA*)MMemAlloc(MNull,sizeof(AFR_FSDK_FACEDATA) * person.nFeatureCount);
    person.pFaceFeatureArray[0] = featureData;
    
    MRESULT mr_Uninit_FD = AFD_FSDK_UninitialFaceEngine(handle_FD);
    handle_FD = MNull;
    if(memBuffer_FD != MNull)
    {
        MMemFree(MNull,memBuffer_FD);
        memBuffer_FD = MNull;
    }
    if( mr_Uninit_FD != MOK ){complete(JOHNVISIONERROR_07,JOHNVISIONERROR_NULL);return;}
    
    MRESULT mr_Uninit_FR = AFR_FSDK_UninitialEngine(handle_FR);
    handle_FR = MNull;
    if(memBuffer_FR != MNull)
    {
        MMemFree(MNull,memBuffer_FR);
        memBuffer_FR = MNull;
    }
    
    if( mr_Uninit_FR != MOK ){complete(JOHNVISIONERROR_08,JOHNVISIONERROR_NULL);return;}
    
    complete(JOHNVISIONERROR_00,person);
}

+ (void)doRecognitionWithRegistImage:(UIImage *)regist compare:(UIImage *)compare result:(void(^)(int error_regist,int error_compare,int error_reslut,float compareReslut))complete {

    __block UIImage *image1 = regist;
    __block UIImage *image2 = compare;
    
    __block AFR_FSDK_PERSON person1;
    __block AFR_FSDK_PERSON person2;
    
    __block int error1;
    __block int error2;
    
    dispatch_group_t group = dispatch_group_create();
    
    dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [JohnVisionSever doRegister:image1 reslut:^(int error, AFR_FSDK_PERSON person) {
            error1 = error;
            person1 = person;
        }];
    });
    
    dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [JohnVisionSever doRegister:image2 reslut:^(int error, AFR_FSDK_PERSON person) {
            error2 = error;
            person2 = person;
        }];
    });
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        
        if(error1 == JOHNVISIONERROR_00 && error2 == JOHNVISIONERROR_00){
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                //比较
                AFR_FSDK_FACEMODEL probeFaceModel = {0};
                AFR_FSDK_FACEMODEL currentFaceModel = {0};
                
                probeFaceModel.pbFeature = person1.pFaceFeatureArray[0].pbFeature;
                probeFaceModel.lFeatureSize = person1.pFaceFeatureArray[0].lFeatureSize;
                
                currentFaceModel.pbFeature = person2.pFaceFeatureArray[0].pbFeature;
                currentFaceModel.lFeatureSize = person2.pFaceFeatureArray[0].lFeatureSize;
                
                [JohnVisionSever compare:probeFaceModel other:currentFaceModel reslut:^(int error, MFloat result) {
                
                    dispatch_async(dispatch_get_main_queue(), ^{
                        complete(error1,error2,error,result);
                    });
                }];
                
            });
        }else{
            complete(error1,error2,JOHNVISIONERROR_00,0);
        }
    });
    
}

+ (void)compare:(AFR_FSDK_FACEMODEL) aModel other:(AFR_FSDK_FACEMODEL)bModel reslut:(void(^)(int error,MFloat result))complete{
    
    MHandle handle ;
    MVoid* memBuffer = MMemAlloc(MNull,AFR_FR_MEM_SIZE);
    MMemSet(memBuffer, 0, AFR_FR_MEM_SIZE);
    MRESULT result_FR = AFR_FSDK_InitialEngine((MPChar)AFR_DEMO_APP_ID, (MPChar)AFR_DEMO_SDK_FR_KEY, (MByte*)memBuffer, AFR_FR_MEM_SIZE, &handle);

    if( result_FR != MOK ){complete(JOHNVISIONERROR_02,0);return;}

    MFloat fMimilScore =  0.0;
    MRESULT mr = AFR_FSDK_FacePairMatching(handle, &aModel, &bModel, &fMimilScore);
        
    if( mr != MOK ){complete(JOHNVISIONERROR_09,0);return;}
    
    MRESULT mr_Uninit_FR = AFR_FSDK_UninitialEngine(handle);
    handle = MNull;
    if(memBuffer != MNull)
    {
        MMemFree(MNull,memBuffer);
        memBuffer = MNull;
    }
    
    if( mr_Uninit_FR != MOK ){complete(JOHNVISIONERROR_08,0);return;}

    complete(JOHNVISIONERROR_00,fMimilScore);
}

@end

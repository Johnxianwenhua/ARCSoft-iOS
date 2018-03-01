# ARCSoft-iOS

现在把我的想法描述一下。

图片比对-SDK方法会调用人脸识别中的 - AFR_FSDK_FacePairMatching，关键-方法需要传入两个特征参数。

图片特征提取-SDK取图片中人脸调用人脸识别中的-AFR_FSDK_ExtractFRFeature，关键-方法需要传入两个人脸信息。

图片人脸信息-SDK取图片中人脸信息调用人脸检测中的-AFD_FSDK_StillImageFaceDetection，关键-LPASVLOFFSCREEN。

最初的开发会遇到图片转LPASVLOFFSCREEN的问题，虹软最新的Demo已经给出解决的方法，拷过来直接用就行了。

构建
开两个任务取两张图片的特征，处理特征信息，得出结果。

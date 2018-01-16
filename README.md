## cocos-project.json配置说明

android_cfg.studio_proj_path是Android Studio项目的路径，默认为proj.android-studio，如果有多个Studio项目，则每次编译的时候只能在这个字段配置目标路径了。android_cfg.project_path为Eclipse项目的路径，如果配置了android_cfg字段，则它也是必须的，否则编译会出错。

## Android.mk

添加`LOCAL_ARM_MODE := arm`是为了解决编译时的一个错误：relocation overflow in R_ARM_THM_CALL。
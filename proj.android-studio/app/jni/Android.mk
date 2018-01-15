LOCAL_PATH := $(call my-dir)

# --- libBugly.so ---
include $(CLEAR_VARS)
LOCAL_MODULE := bugly_native_prebuilt
# 可在Application.mk添加APP_ABI := armeabi armeabi-v7a 指定集成对应架构的.so文件
LOCAL_SRC_FILES := prebuilt/$(TARGET_ARCH_ABI)/libBugly.so
include $(PREBUILT_SHARED_LIBRARY)
# --- end ---

# --- fmod ---
include $(CLEAR_VARS)
LOCAL_MODULE := fmod
LOCAL_SRC_FILES := prebuilt/$(TARGET_ARCH_ABI)/libfmod.so
include $(PREBUILT_SHARED_LIBRARY)

include $(CLEAR_VARS)
LOCAL_MODULE := fmodstudio
LOCAL_SRC_FILES := prebuilt/$(TARGET_ARCH_ABI)/libfmodstudio.so
include $(PREBUILT_SHARED_LIBRARY)

#include $(CLEAR_VARS)
#LOCAL_MODULE := fmodL
#LOCAL_SRC_FILES := prebuilt/$(TARGET_ARCH_ABI)/libfmodL.so
#include $(PREBUILT_SHARED_LIBRARY)
#
#include $(CLEAR_VARS)
#LOCAL_MODULE := fmodstudioL
#LOCAL_SRC_FILES := prebuilt/$(TARGET_ARCH_ABI)/libfmodstudioL.so
#include $(PREBUILT_SHARED_LIBRARY)
# --- end ---

include $(CLEAR_VARS)

$(call import-add-path,$(LOCAL_PATH)/../../../cocos2d)
$(call import-add-path,$(LOCAL_PATH)/../../../cocos2d/external)
$(call import-add-path,$(LOCAL_PATH)/../../../cocos2d/cocos)
#$(call import-add-path,$(LOCAL_PATH)/../../../cocos2d/cocos/audio/include)
$(call import-add-path,$(LOCAL_PATH)/../../../cocos2d/extensions)

# for AnySDK
$(call import-add-path,$(LOCAL_PATH)/../)

LOCAL_STATIC_LIBRARIES := cocos2d_lua_static
LOCAL_STATIC_LIBRARIES += cocos2dx_static

LOCAL_MODULE := summoner_shared
LOCAL_ARM_MODE := arm
LOCAL_MODULE_FILENAME := libsummoner

FILE_LIST := hellocpp/main.cpp 
FILE_LIST += $(wildcard $(LOCAL_PATH)/../../../Classes/commonFrame/*.cpp) 
FILE_LIST += $(wildcard $(LOCAL_PATH)/../../../Classes/commonFrame/mixedCode/*.cpp) 
FILE_LIST += $(wildcard $(LOCAL_PATH)/../../../Classes/commonFrame/resManager/*.cpp) 
FILE_LIST += $(wildcard $(LOCAL_PATH)/../../../Classes/commonFrame/fmodAudioEngine/*.cpp) 
FILE_LIST += $(wildcard $(LOCAL_PATH)/../../../Classes/gameBattle/*.cpp) 
FILE_LIST += $(wildcard $(LOCAL_PATH)/../../../Classes/gameBattle/common/*.cpp) 
FILE_LIST += $(wildcard $(LOCAL_PATH)/../../../Classes/gameBattle/display/*.cpp) 
FILE_LIST += $(wildcard $(LOCAL_PATH)/../../../Classes/gameBattle/display/effect/*.cpp) 
FILE_LIST += $(wildcard $(LOCAL_PATH)/../../../Classes/gameBattle/display/object/*.cpp) 
FILE_LIST += $(wildcard $(LOCAL_PATH)/../../../Classes/gameBattle/display/ui/*.cpp) 
FILE_LIST += $(wildcard $(LOCAL_PATH)/../../../Classes/gameBattle/logic/*.cpp) 
FILE_LIST += $(wildcard $(LOCAL_PATH)/../../../Classes/gameConfig/*.cpp) 
FILE_LIST += $(wildcard $(LOCAL_PATH)/../../../Classes/gameFrame/*.cpp) 
FILE_LIST += $(wildcard $(LOCAL_PATH)/../../../Classes/gameMain/*.cpp) 
FILE_LIST += $(wildcard $(LOCAL_PATH)/../../../Classes/gameToLua/*.cpp) 
FILE_LIST += $(wildcard $(LOCAL_PATH)/../../../Classes/gameToLua/model/*.cpp) 
FILE_LIST += $(wildcard $(LOCAL_PATH)/../../../Classes/kxdebuger/*.cpp) 
FILE_LIST += $(wildcard $(LOCAL_PATH)/../../../Classes/kxdebuger/*.cc) 
FILE_LIST += $(wildcard $(LOCAL_PATH)/../../../Classes/networkNode/*.cpp)
FILE_LIST += $(wildcard $(LOCAL_PATH)/../../../Classes/protocol/*.cpp)

FILE_LIST += $(wildcard $(LOCAL_PATH)/../../../extern/kxServer/*.cpp) 
FILE_LIST += $(wildcard $(LOCAL_PATH)/../../../extern/kxServer/core/*.cpp) 
FILE_LIST += $(wildcard $(LOCAL_PATH)/../../../extern/kxServer/helper/*.cpp) 
FILE_LIST += $(wildcard $(LOCAL_PATH)/../../../extern/kxServer/pulgins/*.cpp) 
FILE_LIST += $(wildcard $(LOCAL_PATH)/../../../extern/kxServer/commnication/*.cpp) 
FILE_LIST += $(wildcard $(LOCAL_PATH)/../../../extern/protobuf-lite/google/protobuf/*.cc)
FILE_LIST += $(wildcard $(LOCAL_PATH)/../../../extern/protobuf-lite/google/protobuf/io/*.cc)
FILE_LIST += $(wildcard $(LOCAL_PATH)/../../../extern/protobuf-lite/google/protobuf/stubs/*.cc)
FILE_LIST += $(wildcard $(LOCAL_PATH)/../../../extern/quicklib/quick/*.cpp)
FILE_LIST += $(wildcard $(LOCAL_PATH)/../../../extern/md5/*.cpp)
FILE_LIST += $(wildcard $(LOCAL_PATH)/../../../extern/qqHall/*.cpp)
# for AnySDK
FILE_LIST += $(wildcard $(LOCAL_PATH)/../../../extern/anysdk/*.cpp)

LOCAL_SRC_FILES := $(FILE_LIST:$(LOCAL_PATH)/%=%)

LOCAL_C_INCLUDES := $(LOCAL_PATH)/../../../Classes/commonFrame \
					$(LOCAL_PATH)/../../../Classes/commonFrame/mixedCode \
					$(LOCAL_PATH)/../../../Classes/commonFrame/resManager \
					$(LOCAL_PATH)/../../../Classes/commonFrame/fmodAudioEngine \
					$(LOCAL_PATH)/../../../Classes/gameBattle \
					$(LOCAL_PATH)/../../../Classes/gameBattle/common \
					$(LOCAL_PATH)/../../../Classes/gameBattle/display \
					$(LOCAL_PATH)/../../../Classes/gameBattle/display/effect \
					$(LOCAL_PATH)/../../../Classes/gameBattle/display/object \
					$(LOCAL_PATH)/../../../Classes/gameBattle/display/ui \
					$(LOCAL_PATH)/../../../Classes/gameBattle/logic \
					$(LOCAL_PATH)/../../../Classes/gameConfig \
					$(LOCAL_PATH)/../../../Classes/gameFrame \
					$(LOCAL_PATH)/../../../Classes/gameMain \
					$(LOCAL_PATH)/../../../Classes/gameToLua \
					$(LOCAL_PATH)/../../../Classes/gameToLua/model \
					$(LOCAL_PATH)/../../../Classes/kxdebuger \
					$(LOCAL_PATH)/../../../Classes/networkNode \
					$(LOCAL_PATH)/../../../Classes/protocol \
					$(LOCAL_PATH)/../../../extern/kxServer \
					$(LOCAL_PATH)/../../../extern/kxServer/core \
					$(LOCAL_PATH)/../../../extern/kxServer/helper \
					$(LOCAL_PATH)/../../../extern/kxServer/pulgins \
					$(LOCAL_PATH)/../../../extern/kxServer/commnication \
					$(LOCAL_PATH)/../../../extern/protobuf-lite \
					$(LOCAL_PATH)/../../../extern/protobuf-lite/google/protobuf \
					$(LOCAL_PATH)/../../../extern/protobuf-lite/google/protobuf/io \
					$(LOCAL_PATH)/../../../extern/protobuf-lite/google/protobuf/stubs \
					$(LOCAL_PATH)/../../../extern/quicklib/quick \
					$(LOCAL_PATH)/../../../extern/md5 \
					$(LOCAL_PATH)/../../../extern/qqHall

# _COCOS_LIB_ANDROID_BEGIN
# _COCOS_LIB_ANDROID_END

LOCAL_CFLAGS += -DANYSDK

# for AnySDK.注：PluginProtocolStatic请勿使用LOCAL_STATIC_LIBRARIES，否则会导致AnySDK部分函数找不到。
LOCAL_WHOLE_STATIC_LIBRARIES += PluginProtocolStatic

#fmod库
#LOCAL_SHARED_LIBRARIES += fmodL
LOCAL_SHARED_LIBRARIES += fmod
#LOCAL_SHARED_LIBRARIES += fmodstudioL
LOCAL_SHARED_LIBRARIES += fmodstudio

# 引入bugly/Android.mk定义的Module
LOCAL_STATIC_LIBRARIES += bugly_crashreport_cocos_static
# 引入bugly/lua/Android.mk定义的Module
LOCAL_STATIC_LIBRARIES += bugly_agent_cocos_static_lua

include $(BUILD_SHARED_LIBRARY)

$(call import-module,external/bugly)
$(call import-module,external/bugly/lua)
$(call import-module,scripting/lua-bindings/proj.android)
# for AnySDK
$(call import-module,protocols/android)

# _COCOS_LIB_IMPORT_ANDROID_BEGIN
# _COCOS_LIB_IMPORT_ANDROID_END

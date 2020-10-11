
THIRD_LIB_ROOT ?= ../3rd/

SKYNET_ROOT ?= $(THIRD_LIB_ROOT)skynet/
include $(SKYNET_ROOT)platform.mk

LFS_ROOT ?= $(THIRD_LIB_ROOT)lfs/
LFS_INC ?= $(SKYNET_ROOT)3rd/lua/

SKYNET_BUILD_PATH ?= .
LUACLIB_PATH ?= luaclib
MCSERVICE_PATH ?= cservice

LUA_INC ?= $(SKYNET_ROOT)3rd/lua
CFLAGS = -g -O2 -Wall -I$(LUA_INC) $(MYCFLAGS) 

# skynet

MCSERVICE =
LUACLIB = lfs

all : \
  $(foreach v, $(MCSERVICE), $(MCSERVICE_PATH)/$(v).so) \
  $(foreach v, $(LUACLIB), $(LUACLIB_PATH)/$(v).so)

$(MCSERVICE_PATH) :
	mkdir $(MCSERVICE_PATH)

$(LUACLIB_PATH) :
	mkdir $(LUACLIB_PATH)

$(LUACLIB_PATH)/lfs.so : $(LFS_ROOT)lfs.c | $(LUACLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@
clean :
	rm -f $(MCSERVICE_PATH)/*.so $(LUACLIB_PATH)/*.so

cleanall: clean


# Makefile

TF_INC = `python -c "import tensorflow; print(tensorflow.sysconfig.get_include())"`

ifndef CUDA_HOME
    CUDA_HOME := /usr/local/cuda
endif

CC        = gcc -O2 -pthread
CXX       = g++
GPUCC     = nvcc
CFLAGS    = -std=c++11 -I$(TF_INC) -I"$(CUDA_HOME)/include" -DGOOGLE_CUDA=1
GPUCFLAGS = -c
LFLAGS    = -pthread -shared -fPIC
GPULFLAGS = -x cu -Xcompiler -fPIC
CGPUFLAGS = -L$(CUDA_HOME)/lib -L$(CUDA_HOME)/lib64 -lcudart

OUT_DIR   = src/ops/build
CORRELATION_SRC = "src/ops/correlation/correlation_kernel.cc" "src/ops/correlation/correlation_grad_kernel.cc" "src/ops/correlation/correlation_op.cc"
GPU_SRC_CORRELATION  = src/ops/correlation/correlation_kernel.cu.cc
GPU_SRC_CORRELATION_GRAD  = src/ops/correlation/correlation_grad_kernel.cu.cc
GPU_SRC_PAD = src/ops/correlation/pad.cu.cc
GPU_PROD_CORRELATION = $(OUT_DIR)/correlation_kernel_gpu.o
GPU_PROD_CORRELATION_GRAD = $(OUT_DIR)/correlation_grad_kernel_gpu.o
GPU_PROD_PAD = $(OUT_DIR)/correlation_pad_gpu.o
CORRELATION_PROD 	= $(OUT_DIR)/correlation.so


ifeq ($(OS),Windows_NT)
    detected_OS := Windows
else
    detected_OS := $(shell sh -c 'uname -s 2>/dev/null || echo not')
endif
ifeq ($(detected_OS),Darwin)  # Mac OS X
	CGPUFLAGS += -undefined dynamic_lookup
endif
ifeq ($(detected_OS),Linux)
	CFLAGS += -D_MWAITXINTRIN_H_INCLUDED -D_FORCE_INLINES -D__STRICT_ANSI__ -D_GLIBCXX_USE_CXX11_ABI=0
endif

all: correlation

correlation:
	$(GPUCC) -g $(CFLAGS) $(GPUCFLAGS) $(GPU_SRC_CORRELATION) $(GPULFLAGS) $(GPUDEF) -o $(GPU_PROD_CORRELATION)
	$(GPUCC) -g $(CFLAGS) $(GPUCFLAGS) $(GPU_SRC_CORRELATION_GRAD) $(GPULFLAGS) $(GPUDEF) -o $(GPU_PROD_CORRELATION_GRAD)
	$(GPUCC) -g $(CFLAGS) $(GPUCFLAGS) $(GPU_SRC_PAD) $(GPULFLAGS) $(GPUDEF) -o $(GPU_PROD_PAD)
	$(CXX) -g $(CFLAGS)  $(CORRELATION_SRC) $(GPU_PROD_CORRELATION) $(GPU_PROD_CORRELATION_GRAD) $(GPU_PROD_PAD) $(LFLAGS) $(CGPUFLAGS) -o $(CORRELATION_PROD)

clean:
	rm -f $(OUT_DIR)/*

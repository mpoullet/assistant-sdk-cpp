#!/bin/bash
set -e
set -u
set -o pipefail
set -x
PROJECT_PATH=$(pwd)

# Step 1. Clean up any dependencies
echo "Cleaning dependencies"
./tests/clean-all.sh

# Step 2. Install dependencies
echo "Installing dependencies"
sudo apt-get -y -qq install autoconf automake libtool build-essential curl unzip pkg-config
sudo apt-get -y -qq install libasound2-dev  # For ALSA sound output
sudo apt-get -y -qq install libcurl4-openssl-dev # CURL development library

# Step 3. Build protocol buffer, gRPC, and Google APIs
git clone -b "$(curl -L https://grpc.io/release)" https://github.com/grpc/grpc
GRPC_PATH=${PROJECT_PATH}/grpc
cd "${GRPC_PATH}"
# Checkout stable release of gRPC
git checkout v1.16.0
git submodule update --init

echo "Compiling gRPC protobufs"
cd third_party/protobuf
./autogen.sh && ./configure && make
sudo make install
sudo ldconfig

echo "Compiling gRPC"
cd "${GRPC_PATH}"
make clean
LDFLAGS="-lm" make
sudo make install
sudo ldconfig

echo "Compiling Google APIs"
cd "${PROJECT_PATH}"
git clone https://github.com/googleapis/googleapis.git
cd googleapis/
make LANGUAGE=cpp

# Step 4. Build assistant-grpc
echo "Compiling C++ Assistant"
cd "${PROJECT_PATH}"
GOOGLEAPIS_GENS_PATH=${PROJECT_PATH}/googleapis/gens make run_assistant

# If we get to this point, the project has successfully been built, and we can exit.
echo "Project built!"

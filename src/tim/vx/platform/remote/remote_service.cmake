# list(APPEND ${TARGET_NAME}_SRCS
#   "${PROJECT_SOURCE_DIR}/src/tim/vx/platform/remote/remote_service_client.cc"
#   "${PROJECT_SOURCE_DIR}/src/tim/vx/platform/remote/remote_service_client.h"
#   "${PROJECT_SOURCE_DIR}/src/tim/vx/platform/remote/remote.cc")

find_package(Threads REQUIRED)

include(FetchContent)
FetchContent_Declare(
  grpc
  GIT_REPOSITORY https://github.com/grpc/grpc.git
  GIT_TAG v1.50.0)
set(FETCHCONTENT_QUIET OFF)
FetchContent_MakeAvailable(grpc)

# Since FetchContent uses add_subdirectory under the hood, we can use
# the grpc targets directly from this build.
set(_PROTOBUF_LIBPROTOBUF libprotobuf)
set(_REFLECTION grpc++_reflection)
# set(_PROTOBUF_PROTOC $<TARGET_FILE:protoc>)
set(_PROTOBUF_PROTOC ${PROJECT_SOURCE_DIR}/prebuilt-sdk/grpc/protoc)
set(_GRPC_GRPCPP grpc++)
set(_GRPC_GRPC grpc)
if(CMAKE_CROSSCOMPILING)
  # find_program(_GRPC_CPP_PLUGIN_EXECUTABLE grpc_cpp_plugin)
  set(_GRPC_CPP_PLUGIN_EXECUTABLE ${PROJECT_SOURCE_DIR}/prebuilt-sdk/grpc/grpc_cpp_plugin)
else()
  set(_GRPC_CPP_PLUGIN_EXECUTABLE $<TARGET_FILE:grpc_cpp_plugin>)
  # set(_GRPC_CPP_PLUGIN_EXECUTABLE ${PROJECT_SOURCE_DIR}/prebuilt-sdk/grpc/)
endif()

# Proto file
get_filename_component(rs_proto "${CMAKE_CURRENT_SOURCE_DIR}/vx/platform/remote/remote_service.proto" ABSOLUTE)
get_filename_component(rs_proto_path "${rs_proto}" PATH)

# Generated sources
set(rs_proto_srcs "${CMAKE_CURRENT_BINARY_DIR}/remote_service.pb.cc")
set(rs_proto_hdrs "${CMAKE_CURRENT_BINARY_DIR}/remote_service.pb.h")
set(rs_grpc_srcs "${CMAKE_CURRENT_BINARY_DIR}/remote_service.grpc.pb.cc")
set(rs_grpc_hdrs "${CMAKE_CURRENT_BINARY_DIR}/remote_service.grpc.pb.h")
add_custom_command(
  OUTPUT "${rs_proto_srcs}" "${rs_proto_hdrs}" "${rs_grpc_srcs}" "${rs_grpc_hdrs}"
  COMMAND ${_PROTOBUF_PROTOC}
  ARGS --grpc_out "${CMAKE_CURRENT_BINARY_DIR}"
    --cpp_out "${CMAKE_CURRENT_BINARY_DIR}"
    -I "${rs_proto_path}"
    --plugin=protoc-gen-grpc="${_GRPC_CPP_PLUGIN_EXECUTABLE}"
    "${rs_proto}"
  DEPENDS "${rs_proto}")

# Include generated *.pb.h files
include_directories("${CMAKE_CURRENT_BINARY_DIR}")

# rs_grpc_proto
add_library(rs_grpc_proto
  ${rs_grpc_srcs}
  ${rs_grpc_hdrs}
  ${rs_proto_srcs}
  ${rs_proto_hdrs})
target_link_libraries(rs_grpc_proto
  ${_REFLECTION}
  ${_GRPC_GRPCPP}
  ${_PROTOBUF_LIBPROTOBUF})

# Targets remote_service_(client|server)
# foreach(_target
#     remote_service_demo remote_service_server)
#   add_executable(${_target}
#     "${_target}.cc")
#   target_link_libraries(${_target} -Wl,--whole-archive tim-vx
#     -Wl,--no-whole-archive
#     rs_grpc_proto
#     ${_GRPC_GRPC}
#     ${_REFLECTION}
#     ${_GRPC_GRPCPP}
#     ${_PROTOBUF_LIBPROTOBUF}
#     )
#   target_include_directories(${_target} PRIVATE
#     ${CMAKE_CURRENT_SOURCE_DIR}
#   )
# endforeach()

# add_executable(remote_service_server
#   ${CMAKE_CURRENT_SOURCE_DIR}/vx/platform/remote/remote_service_server.cc)
# target_link_libraries(remote_service_server
#   -Wl,--whole-archive
#   tim-vx
#   -Wl,--no-whole-archive
#   rs_grpc_proto
#   ${_GRPC_GRPC}
#   ${_REFLECTION}
#   ${_GRPC_GRPCPP}
#   ${_PROTOBUF_LIBPROTOBUF})

# add_executable(remote_service_demo
#   ${CMAKE_CURRENT_SOURCE_DIR}/vx/platform/remote/remote_service_demo.cc)
# target_link_libraries(remote_service_demo -Wl,--whole-archive tim-vx)

# install(DIRECTORY ${CMAKE_SOURCE_DIR}/include/tim/vx/platform/remote
#   DESTINATION ${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_INCLUDEDIR}/tim/vx/platform)
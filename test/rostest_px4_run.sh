#! /bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
echo ${BASH_SOURCE[0]}
echo ${DIR}
PX4_SRC_DIR=${DIR}/..
PX4_BIN_SIR=${DIR}/../../../bin
source /opt/ros/kinetic/setup.bash
source ${PX4_SRC_DIR}/Tools/setup_gazebo.bash ${PX4_SRC_DIR} ${PX4_SRC_DIR}/build/posix_sitl_default

export ROS_PACKAGE_PATH=$ROS_PACKAGE_PATH:${PX4_BIN_DIR}:${PX4_SRC_DIR}:${PX4_SRC_DIR}/Tools/sitl_gazebo

sleep 30m

rostest px4 "$@"

# Build from the repository root:
# docker build -f docker/Dockerfile -t ground_vio:catkin .
FROM ros:noetic

ENV DEBIAN_FRONTEND=noninteractive
ENV CATKIN_WS=/catkin_ws

SHELL ["/bin/bash", "-c"]

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    git \
    pkg-config \
    python3-catkin-tools \
    python3-pip \
    python3-rosdep \
    libeigen3-dev \
    libopencv-dev \
    ros-noetic-catkin \
    ros-noetic-cv-bridge \
    ros-noetic-image-transport \
    ros-noetic-nav-msgs \
    ros-noetic-roscpp \
    ros-noetic-rospy \
    ros-noetic-rviz \
    ros-noetic-sensor-msgs \
    ros-noetic-std-msgs \
    ros-noetic-tf \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p ${CATKIN_WS}/src

COPY . ${CATKIN_WS}/src/gv_tools

WORKDIR ${CATKIN_WS}

RUN source /opt/ros/noetic/setup.bash && \
    catkin init && \
    catkin config --extend /opt/ros/noetic --merge-devel && \
    catkin build

RUN echo "source /opt/ros/noetic/setup.bash" >> /etc/bash.bashrc && \
    echo "source ${CATKIN_WS}/devel/setup.bash" >> /etc/bash.bashrc

WORKDIR ${CATKIN_WS}

CMD ["/bin/bash"]

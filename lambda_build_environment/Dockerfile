FROM amazonlinux:latest
 
RUN yum update -y
RUN yum install -y \
    gcc \
    openssl-devel \
    zlib-devel \
    libffi-devel \
    wget && \
    yum -y clean all

RUN amazon-linux-extras enable python3.8 && \
    yum install -y \
    python3.8 \ 
    python38-devel

WORKDIR /app
ENTRYPOINT ["/bin/bash", "-c", "./install.sh"]

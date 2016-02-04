FROM centos:7

MAINTAINER Vadim Rutkovsky, https://github.com/vrutkovs

LABEL io.openshift.tags  manageiq
LABEL io.openshift.wants postgres
LABEL io.k8s.description ManageIQ Cloud Management Platform
LABEL io.openshift.expose-services 443:https
LABEL io.openshift.non-scalable true

USER 0

RUN yum -y install https://www.softwarecollections.org/en/scls/rhscl/rh-ruby22/epel-7-x86_64/download/rhscl-rh-ruby22-epel-7-x86_64.noarch.rpm
RUN yum -y install scl-utils \
        rh-ruby22-ruby-devel \
        rh-ruby22-rubygems-devel \
        rh-ruby22-rubygem-rake \
        rh-ruby22-rubygem-bundler \
        rh-ruby22-rubygem-json \
# Important utils
        git \
        tar \
        postgresql \
        postgresql-server \
        postgresql-devel \
        memcached \
        httpd \
        mod_ssl \
# Gem's build requirements
        gcc \
        gcc-c++ \
        libxml2-devel \
        libxslt-devel \
        make \
        patch \
        which \
        net-tools \
        iproute \
        psmisc \
        bzip2 && \
   yum clean all -y

EXPOSE 443

COPY database.openshift.yml /
COPY apache.conf /
COPY run.sh /

CMD /bin/bash -l /run.sh

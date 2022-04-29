FROM openwhisk/dockerskeleton as wsk

FROM debian:buster-slim

RUN apt-get -q update \
	&& apt-get upgrade -y \
	&& apt-get install -y --no-install-recommends apt-utils apt-transport-https ca-certificates sed openssh-client \
	curl gnupg lsb-release apt-transport-https zip unzip bzip2 xz-utils wget openssl locales groff less g++ libc-dev \
	python3-pip \
	&& apt-get -q clean
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
	&& echo "deb [arch="`dpkg --print-architecture`" signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian "`lsb_release -cs`" stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null \
	&& apt-get update && apt-get install -y --no-install-recommends docker-ce docker-ce-cli containerd.io docker-compose-plugin \
	&& apt-get -q clean \
	&& rm -rf /var/lib/apt/lists \
	&& locale-gen en_US.UTF-8 
RUN apt-get -q update && apt-get install -y --no-install-recommends python3-dev && apt-get -q clean \
	&& rm -rf /var/lib/apt/lists
RUN pip3 install --upgrade pip setuptools six \
  && pip3 install --no-cache-dir Jinja2==2.11.1 gevent==1.3.6 flask==1.0.2 itsdangerous==1.1.0 MarkupSafe==1.1.1 Click==7.0 greenlet==0.4.15 MarkupSafe==1.1.1

ENV LANG=en_US.UTF-8

ENV FLASK_PROXY_PORT 8080

ARG JQ_VERSION=1.6
RUN wget --no-check-certificate https://github.com/stedolan/jq/releases/download/jq-${JQ_VERSION}/jq-linux64 -O /tmp/jq-linux64  \
	&& cp /tmp/jq-linux64 /usr/bin/jq  \
	&& chmod +x /usr/bin/jq  \
	&& rm -f /tmp/jq-linux64

ARG IBMCLOUD_VERSION=2.6.0
RUN wget --quiet -O /tmp/Bluemix_CLI.tar.gz https://download.clis.cloud.ibm.com/ibm-cloud-cli/${IBMCLOUD_VERSION}/IBM_Cloud_CLI_${IBMCLOUD_VERSION}_amd64.tar.gz  \
	&& tar -xzvf /tmp/Bluemix_CLI.tar.gz -C /tmp  \
	&& export PATH=/opt/IBM/cf/bin:$PATH  \
	&& /tmp/Bluemix_CLI/install_bluemix_cli  \
	&& rm -rf /tmp/Bluemix_CLI*  \
	&& ibmcloud config --check-version false  \
	&& mkdir -p /usr/local/Bluemix/bin/cfcli  \
	&& mkdir -p /usr/local/ibmcloud/bin/cfcli

RUN ibmcloud plugin install container-service -r Bluemix -v 1.0.208  \
	&& ibmcloud plugin install container-registry -r Bluemix -v 0.1.566  \
	&& ibmcloud plugin install cloud-functions -r Bluemix -v 1.0.56  \
	&& ibmcloud plugin install schematics -r Bluemix -v 1.7.2  \
	&& ibmcloud plugin install doi -r Bluemix -v 0.3.1  \
	&& ibmcloud plugin install cis -r Bluemix -v 1.13.4  \
	&& ibmcloud cf install -v 6.51.0 --force

RUN ln -s /usr/local/ibmcloud/bin/cfcli/cf /usr/local/Bluemix/bin/cfcli/cf  \
	&& ln -s /usr/local/ibmcloud/bin/cfcli/cf /usr/local/bin/cf  \
	&& ln -s /usr/local/ibmcloud/bin/ibmcloud /usr/local/bin/ic

RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip && ./aws/install && rm -rf aws awscliv2.zip

# RUN mkdir -p /actionProxy/owplatform

RUN ln -s /usr/bin/python3 /usr/bin/python

COPY --from=wsk /actionProxy/actionproxy.py /actionProxy/
# COPY --from=wsk /actionProxy/owplatform/ /actionProxy/

RUN mkdir -p /action

COPY update_dns_record.sh /action/exec
RUN chmod +x /action/exec

CMD ["/bin/bash", "-c", "cd actionProxy && python -u actionproxy.py"]

ENV TMPDIR=/tmp
ENV HOME=/root
ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/go/bin:/root/go/bin
ENV BASH_ENV=/root/.bashrc

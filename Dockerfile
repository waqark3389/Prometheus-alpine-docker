FROM alpine:3.7

# Set home for prom daemon
ARG PROMETHEUS_HOME=/prometheus
# TODO unhardcode version
ARG PROMETHEUS_VERSION=2.15.2

# Build URL
ARG PROMETHEUS_TAR=prometheus-${PROMETHEUS_VERSION}.linux-amd64
ARG PROMETHEUS_TAR_FULLNAME=${PROMETHEUS_TAR}.tar.gz
ARG PROMETHEUS_URL=https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/${PROMETHEUS_TAR_FULLNAME}

# Update apk and base system
RUN apk update \ 
    apk upgrade
# Install wget and remove cache to reduce size of container
RUN apk add wget && rm -rf /var/cache/apk/*
#Download the release from github
RUN wget ${PROMETHEUS_URL}

# Extract and remove the defaiut config that comes with the container
RUN tar xvfz ${PROMETHEUS_TAR_FULLNAME} -C / && \
    mv /${PROMETHEUS_TAR} /prometheus && \
    rm -rf /prometheus/prometheus.yml

# Add user so we dont run as root
RUN addgroup -S prometheus && adduser -S prometheus -G prometheus

# Give ownership to prom user - adjust inside the persistant EBS volume
RUN chown -R prometheus:prometheus /prometheus
# Add our own config - # todo - unhardcode, download from s3 bucket instead
ADD prometheus.yml /prometheus/prometheus.yml

# Remove downloaded tar package to reduce size of container
RUN rm -rf /${PROMETHEUS_TAR_FULLNAME}
# Install pip and python 
RUN apk add --no-cache python3
# Install pip
RUN python3 -m ensurepip
RUN pip3 install --no-cache --upgrade pip setuptools wheel
# Install aws cli as we need to interact with it later
RUN pip3 install awscli --upgrade
EXPOSE 9090
# Run in the /prometheus dir for isolation
WORKDIR ${PROMETHEUS_HOME}

USER prometheus


# TODO - replace with script below. todo download config from s3 before run 
ENTRYPOINT [ "./prometheus" ]
CMD        [ "--config.file=/prometheus/prometheus.yml", \
    "--storage.tsdb.path=/prometheus", \
    "--web.console.libraries=/usr/share/prometheus/console_libraries", \
    "--web.console.templates=/usr/share/prometheus/consoles" ]

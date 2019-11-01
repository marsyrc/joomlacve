FROM medicean/vulapps:base_joomla_3.7.0

# RUN echo "deb http://archive.ubuntu.com/ubuntu trusty main universe"> /etc/apt/sources.list 

# 创建用户组和非root用户
RUN groupadd -r redis && useradd -r -g redis redis 
############################################
#ENV用于设置环境变量
ENV REDIS_VERSION 5.0.4
ENV REDIS_DOWNLOAD_URL http://download.redis.io/releases/redis-5.0.4.tar.gz
ENV REDIS_DOWNLOAD_SHA 3ce9ceff5a23f60913e1573f6dfcd4aa53b42d4a2789e28fa53ec2bd28c987dd

# for redis-sentinel see: http://redis.io/topics/sentinel
# set -ex作用是当set命令执行出错后，就退出执行。
RUN set -ex; \
	\
	buildDeps=' \
		ca-certificates \
		wget \
		\
		gcc \
		libc6-dev \
		make \
	'; \
	apt-get update \
	&& apt-get install -y $buildDeps --no-install-recommends; \
	rm -rf /var/lib/apt/lists/*; \
	\
	wget -O redis.tar.gz "$REDIS_DOWNLOAD_URL"; \
	echo "$REDIS_DOWNLOAD_SHA *redis.tar.gz" | sha256sum -c -; \
	mkdir -p /usr/src/redis; \
	tar -xzf redis.tar.gz -C /usr/src/redis --strip-components=1; \
	rm redis.tar.gz; \
	\
# disable Redis protected mode [1] as it is unnecessary in context of Docker
# (ports are not automatically exposed when running inside Docker, but rather explicitly by specifying -p / -P)
# [1]: https://github.com/antirez/redis/commit/edd4d555df57dc84265fdfb4ef59a4678832f6da
	grep -q '^#define CONFIG_DEFAULT_PROTECTED_MODE 1$' /usr/src/redis/src/server.h; \
	sed -ri 's!^(#define CONFIG_DEFAULT_PROTECTED_MODE) 1$!\1 0!' /usr/src/redis/src/server.h; \
	grep -q '^#define CONFIG_DEFAULT_PROTECTED_MODE 0$' /usr/src/redis/src/server.h; \
# for future reference, we modify this directly in the source instead of just supplying a default configuration flag because apparently "if you specify any argument to redis-server, [it assumes] you are going to specify everything"
# see also https://github.com/docker-library/redis/issues/4#issuecomment-50780840
# (more exactly, this makes sure the default behavior of "save on SIGTERM" stays functional by default)
	\
	make -C /usr/src/redis -j "$(nproc)"; \
	make -C /usr/src/redis install; \
	\
	rm -r /usr/src/redis; \
	\
	apt-get purge -y --auto-remove $buildDeps
	
VOLUME [ "/data" ]
COPY flagSet.sh /usr/local/bin/flagSet.sh
RUN  chmod u+x /usr/local/bin/flagSet.sh 
EXPOSE 80
EXPOSE 6379

ENTRYPOINT ["/usr/local/bin/flagSet.sh"]

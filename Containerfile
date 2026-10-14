FROM apache/hadoop:3.3.6

USER root
RUN curl -fL --progress-bar --retry 3 --retry-delay 5 \
      -o /tmp/spark.tgz https://archive.apache.org/dist/spark/spark-3.5.4/spark-3.5.4-bin-hadoop3.tgz \
    && tar -xzf /tmp/spark.tgz -C /opt \
    && rm /tmp/spark.tgz \
    && ln -s /opt/spark-3.5.4-bin-hadoop3 /opt/spark
ENV SPARK_HOME=/opt/spark
ENV PATH=/opt/spark/bin:${PATH}
COPY config/ /opt/hadoop/etc/hadoop/
COPY config/spark-defaults.conf /opt/spark/conf/spark-defaults.conf
COPY container/start-master.sh /usr/local/bin/start-master.sh
COPY container/start-worker.sh /usr/local/bin/start-worker.sh
RUN chmod +x /usr/local/bin/start-master.sh /usr/local/bin/start-worker.sh


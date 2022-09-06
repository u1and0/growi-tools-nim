# 定期的なピックアップ記事の更新
# Usage: docker run -t --rm u1and0/growi-pickup
FROM nimlang/nim:latest-alpine AS nimbuilder
WORKDIR /tmp
COPY ./growiapi.nim /tmp/growiapi.nim
COPY ./pickup.nim /tmp/pickup.nim
RUN nim c -d:release pickup.nim

FROM alpine
# Install cron
RUN apk --update --no-cache add tzdata
ARG TASK="/etc/crontabs/root"
ARG CRON="3 12 * * *"
# 平日12時に更新
RUN echo "SHELL=/bin/sh" > $TASK &&\
    echo "PATH=/sbin:/bin:/usr/sbin:/usr/bin" >> $TASK &&\
    echo "${CRON} /usr/bin/pickup" >> $TASK

# Growi API
COPY --from=nimbuilder /tmp/pickup /usr/bin/pickup
RUN chmod +x /usr/bin/pickup

# Set env & Run
ENV TZ="Asia/Tokyo"
# Daily update
CMD ["crond", "&&", "tail", "-f"]

LABEL maintainer="u1and0 <e01.ando60@gmail.com>" \
      description="Growiピックアップ記事を/ピックアップ記事へ投稿する。" \
      version="growi-pickup:v0.1.1" \
      usage="docker run -t --rm u1and0/growi-ranking"

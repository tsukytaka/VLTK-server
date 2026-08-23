#!/bin/sh
set -eu

RETENTION_DAYS=7

for log_dir in \
    /home/jxser/server1/Logs \
    /home/jxser/gateway/Logs \
    /home/jxser/gateway/s3relay/Logs
do
    if [ -d "$log_dir" ]; then
        find "$log_dir" -xdev -type f \
            \( -name '*.log' -o -name '*.txt' \) \
            -mtime "+$RETENTION_DAYS" -delete
    fi
done

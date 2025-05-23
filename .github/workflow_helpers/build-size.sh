#!/bin/bash
set -e
echo "🔍 Image size report" > build-size.txt
docker image inspect alfred-nightly:latest --format='{{.RepoTags}} - Size: {{.Size}} bytes' >> build-size.txt

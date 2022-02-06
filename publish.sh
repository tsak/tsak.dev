#!/bin/bash

set -euxo pipefail

hugo -v

rsync -a --progress ./public/ nuc:/home/htdocs/tsak.dev/

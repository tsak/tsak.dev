#!/bin/bash

set -euxo pipefail

hugo server --disableFastRender --buildDrafts 


#!/bin/bash
set -e

export DEBIAN_FRONTEND=noninteractive

set -e

# This script will install the latest released version of pixlet,
# Unless this argument is set to a specific version tag
# e.g. v0.22.7
PIN_VERSION_TAG="${ENV_PIXLET_VERSION:-"0.33.5"}"

cd /tmp

echo "::install libwebp-dev::"
sudo apt update -y
sudo apt -y install libwebp-dev 

echo "::install pixlet::"

if [ -z "$PIN_VERSION_TAG" ]; then
    TAG=$(git -c 'versionsort.suffix=-' ls-remote --tags --sort='v:refname' https://github.com/tidbyt/pixlet.git | tail -n1  | cut --delimiter='/' --fields=3)
else
    TAG="$PIN_VERSION_TAG"
fi

URL="https://github.com/tidbyt/pixlet/releases/download/v${TAG}/pixlet_${TAG}_linux_amd64.tar.gz"

echo "Installing version ${TAG} from - ${URL}"

wget -O pixlet.tar.gz $URL
tar -xzf pixlet.tar.gz pixlet
sudo mv pixlet /usr/local/bin/

echo "::Validate Pixlet Installed::"
pixlet version

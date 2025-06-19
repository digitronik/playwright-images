#!/bin/bash

set -e

DOCKERFILE="Dockerfile.multibuild"
IMAGE_REPO="localhost/playwright-vnc"
IMAGE_TAG="latest"

# Define all build targets. The key is the target name in the Dockerfile,
# and the value is the suffix for the image tag.
declare -A targets
targets["firefox"]="firefox"
targets["chromium"]="chromium"
targets["chrome"]="chrome"
targets["all"]="all"

# --- Build Logic ---
echo "🚀 Starting Docker image build process..."

# Determine which targets to build
targets_to_build=("$@")
if [ ${#targets_to_build[@]} -eq 0 ]; then
    # If no specific targets are provided as arguments, build all of them.
    targets_to_build=("${!targets[@]}")
    echo "No specific targets provided. Building all variants: ${targets_to_build[*]}"
fi

# Loop through the targets and build each one
for target in ${targets_to_build[@]}; do
    if [[ -z "${targets[$target]}" ]]; then
        echo "⚠️ Warning: Unknown build target '$target'. Skipping."
        continue
    fi

    tag_suffix="${targets[$target]}"
    full_image_name="${IMAGE_REPO}:${tag_suffix}-${IMAGE_TAG}"

    echo ""
    echo "------------------------------------------------------------"
    echo "Building target: '$target'  =>  Image: $full_image_name"
    echo "------------------------------------------------------------"

    podman build \
        --file ${DOCKERFILE} \
        --target ${target} \
        --tag ${full_image_name} \
        . # Build context is the current directory

    echo "✅ Successfully built ${full_image_name}"
done

echo ""
echo "🎉 All specified images built successfully!"

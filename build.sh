#!/bin/bash

set -e

# Enhanced build script with version support
DOCKERFILE="Dockerfile.multibuild"
IMAGE_REPO="${IMAGE_REPO:-digitronik/playwright-vnc}"

# Version handling
PLAYWRIGHT_VERSION=""
USE_LATEST_TAG=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --playwright-version)
            PLAYWRIGHT_VERSION="$2"
            shift 2
            ;;
        --latest)
            USE_LATEST_TAG=true
            shift
            ;;
        --repo)
            IMAGE_REPO="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [options] [browser-targets...]"
            echo ""
            echo "Options:"
            echo "  --playwright-version VERSION  Use specific Playwright version"
            echo "  --latest                      Also tag as latest"
            echo "  --repo REPO                   Docker repository (default: digitronik/playwright-vnc)"
            echo "  --help                        Show this help"
            echo ""
            echo "Browser targets: firefox, chromium, chrome, all (default: all if none specified)"
            echo ""
            echo "Examples:"
            echo "  $0                                    # Build all browsers with auto-detected latest version"
            echo "  $0 firefox chrome                     # Build only Firefox and Chrome variants"
            echo "  $0 --playwright-version 1.50.0 all   # Build all browsers with specific version"
            echo "  $0 --latest firefox                   # Build Firefox and tag as latest"
            exit 0
            ;;
        -*)
            echo "Unknown option: $1"
            exit 1
            ;;
        *)
            break
            ;;
    esac
done

# Auto-detect Playwright version if not specified
if [ -z "$PLAYWRIGHT_VERSION" ]; then
    echo "🔍 Auto-detecting latest Playwright version..."
    if [ -f "scripts/get-playwright-version.sh" ]; then
        PLAYWRIGHT_VERSION=$(scripts/get-playwright-version.sh latest)
        echo "📦 Detected Playwright version: $PLAYWRIGHT_VERSION"
    else
        echo "⚠️ Warning: Version detection script not found, using default version from Dockerfile"
        PLAYWRIGHT_VERSION="1.52.0"  # Fallback
    fi
fi

# Define all build targets. The key is the target name in the Dockerfile,
# and the value is the suffix for the image tag.
declare -A targets
targets["firefox"]="firefox"
targets["chromium"]="chromium"
targets["chrome"]="chrome"
targets["all"]="all"

# Build metadata
BUILD_DATE=$(date -u +%Y-%m-%dT%H:%M:%SZ)
VCS_REF=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
VERSION="pw-${PLAYWRIGHT_VERSION}"

echo "🚀 Starting Docker image build process..."
echo "📋 Build Configuration:"
echo "   Playwright Version: $PLAYWRIGHT_VERSION"
echo "   Repository: $IMAGE_REPO"
echo "   Build Date: $BUILD_DATE"
echo "   VCS Ref: $VCS_REF"
echo "   Version Tag: $VERSION"

# Determine which targets to build
targets_to_build=("$@")
if [ ${#targets_to_build[@]} -eq 0 ]; then
    # If no specific targets are provided as arguments, build all of them.
    targets_to_build=("${!targets[@]}")
    echo "📦 No specific targets provided. Building all variants: ${targets_to_build[*]}"
fi

# Function to build and tag images
build_and_tag() {
    local target="$1"
    local tag_suffix="$2"
    
    # Tagging strategy: <browser-name>-<playwright-version> or just <playwright-version> for 'all'
    local primary_tag
    if [ "$target" = "all" ]; then
        primary_tag="${IMAGE_REPO}:${PLAYWRIGHT_VERSION}"
    else
        primary_tag="${IMAGE_REPO}:${tag_suffix}-${PLAYWRIGHT_VERSION}"
    fi
    
    echo ""
    echo "🏗️ ============================================================"
    echo "Building target: '$target'  =>  Image: $primary_tag"
    echo "============================================================"
    
    # Build the image with metadata
    docker build \
        --file ${DOCKERFILE} \
        --target ${target} \
        --build-arg PLAYWRIGHT_VERSION="${PLAYWRIGHT_VERSION}" \
        --build-arg BUILD_DATE="${BUILD_DATE}" \
        --build-arg VCS_REF="${VCS_REF}" \
        --build-arg VERSION="${VERSION}" \
        --tag "${primary_tag}" \
        .
    
    echo "✅ Successfully built ${primary_tag}"
    
    # Additional tagging logic
    local tags_created=("${primary_tag}")
    
    # Create appropriate latest tags
    if [ "$target" = "all" ]; then
        # For 'all' target, create the main 'latest' tag
        local latest_tag="${IMAGE_REPO}:latest"
        docker tag "${primary_tag}" "${latest_tag}"
        tags_created+=("${latest_tag}")
        echo "🏷️ Tagged as: ${latest_tag} (all browsers)"
    else
        # For specific browsers, create browser-specific latest tag
        local latest_tag="${IMAGE_REPO}:${tag_suffix}-latest"
        docker tag "${primary_tag}" "${latest_tag}"
        tags_created+=("${latest_tag}")
        echo "🏷️ Tagged as: ${latest_tag}"
    fi
    
    # If --latest flag is used, also create overall latest for 'all' (redundant but kept for compatibility)
    if [ "$USE_LATEST_TAG" = true ] && [ "$target" = "all" ]; then
        echo "🏷️ Latest tag already created for all browsers"
    fi
    
    echo "📋 All tags created for $target:"
    for tag in "${tags_created[@]}"; do
        echo "   📌 $tag"
    done
    
    return 0
}

# Loop through the targets and build each one
echo ""
echo "🔨 Starting build process for ${#targets_to_build[@]} target(s)..."

for target in "${targets_to_build[@]}"; do
    if [[ -z "${targets[$target]}" ]]; then
        echo "⚠️ Warning: Unknown build target '$target'. Skipping."
        continue
    fi
    
    tag_suffix="${targets[$target]}"
    build_and_tag "$target" "$tag_suffix"
done

echo ""
echo "🎉 All specified images built successfully!"
echo ""
echo "📊 Build Summary:"
echo "   Playwright Version: $PLAYWRIGHT_VERSION"
echo "   Targets Built: ${targets_to_build[*]}"
echo "   Repository: $IMAGE_REPO"
echo ""
echo "💡 Next steps:"
echo "   • Test your images: docker run -p 5900:5900 -p 3000:3000 ${IMAGE_REPO}:latest"
echo "   • Push to registry: docker push ${IMAGE_REPO} --all-tags"
echo "   • Connect via VNC: vncviewer localhost:5900"

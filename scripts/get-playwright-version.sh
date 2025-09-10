#!/bin/bash

set -e

# Script to fetch the latest Playwright version from GitHub API
# Usage: ./get-playwright-version.sh [latest|list|details]

API_URL="https://api.github.com/repos/microsoft/playwright/releases"

fetch_versions() {
    echo "Fetching Playwright versions from GitHub API..." >&2
    
    # Use timeout and retry for better reliability
    if ! curl -s --max-time 30 --retry 2 "$API_URL"; then
        echo "Error: Failed to fetch versions from GitHub API after retries" >&2
        exit 1
    fi
}

get_latest_version() {
    local versions_json=$(fetch_versions)
    
    # Extract the latest version (first in the list, remove 'v' prefix if present)
    echo "$versions_json" | jq -r '.[0].tag_name' | sed 's/^v//'
}

list_versions() {
    local versions_json=$(fetch_versions)
    
    # List last 10 versions with release dates
    echo "Recent Playwright versions:" >&2
    echo "$versions_json" | jq -r '.[:10][] | "\(.tag_name | ltrimstr("v"))\t\(.published_at[:10])\t\(.name)"'
}

get_version_details() {
    local target_version="$1"
    local versions_json=$(fetch_versions)
    
    echo "$versions_json" | jq -r --arg version "$target_version" '.[] | select(.tag_name == $version or .tag_name == ("v" + $version)) | {version: (.tag_name | ltrimstr("v")), published_at, name, html_url}'
}


case "${1:-latest}" in
    "latest")
        get_latest_version
        ;;
    "list")
        list_versions
        ;;
    "details")
        if [ -z "$2" ]; then
            echo "Error: Please provide a version number for details" >&2
            echo "Usage: $0 details <version>" >&2
            exit 1
        fi
        get_version_details "$2"
        ;;
    *)
        echo "Usage: $0 [latest|list|details <version>]"
        echo ""
        echo "Commands:"
        echo "  latest              Get the latest Playwright version (default)"
        echo "  list               List recent versions with dates"
        echo "  details <version>   Get details for a specific version"
        exit 1
        ;;
esac

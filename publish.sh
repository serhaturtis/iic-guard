#!/bin/bash
set -e

usage() {
    echo "Usage: $0 {test|pypi}"
    exit 1
}

if [ "$#" -ne 1 ]; then
    usage
fi

TARGET="$1"

echo "--- Cleaning up old builds ---"
rm -rf build/ dist/ iic_guard.egg-info/ wheelhouse/

echo "--- Building source and wheel distributions ---"
python3 setup.py sdist bdist_wheel

WHEEL_FILE=$(find dist -name "iic_guard-*.whl")
if [ -z "$WHEEL_FILE" ]; then
    echo "Error: Wheel file not found."
    exit 1
fi
echo "Found wheel: $WHEEL_FILE"

echo "--- Repairing wheel with auditwheel ---"
auditwheel repair "$WHEEL_FILE" -w wheelhouse

REPAIRED_WHEEL=$(find wheelhouse -name "iic_guard-*.whl")
if [ -z "$REPAIRED_WHEEL" ]; then
    echo "Error: Repaired wheel not found."
    exit 1
fi
echo "Found repaired wheel: $REPAIRED_WHEEL"

SDIST_FILE=$(find dist -name "iic_guard-*.tar.gz")
if [ -z "$SDIST_FILE" ]; then
    echo "Error: Source distribution not found."
    exit 1
fi
echo "Found source distribution: $SDIST_FILE"

if [ "$TARGET" == "test" ]; then
    echo "--- Uploading to TestPyPI ---"
    python3 -m twine upload --repository testpypi "$SDIST_FILE" "$REPAIRED_WHEEL"
elif [ "$TARGET" == "pypi" ]; then
    echo "--- Uploading to PyPI ---"
    python3 -m twine upload "$SDIST_FILE" "$REPAIRED_WHEEL"
else
    echo "Error: Invalid target '$TARGET'."
    usage
fi

echo "--- Publication to $TARGET complete! ---" 
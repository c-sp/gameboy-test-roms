#!/usr/bin/env bash
set -e
#
# portable shebang:
# https://www.cyberciti.biz/tips/finding-bash-perl-python-portably-using-env.html
#
# bash on macos:
# https://itnext.io/upgrading-bash-on-macos-7138bd1066ba
#



###############################################################################
##
##   utility methods
##
###############################################################################

print_usage_and_exit()
{
    echo "usage:"
    echo "    $0 $CMD_AGE_TEST_ROMS"
    echo "    $0 $CMD_BLARGG"
    echo "    $0 $CMD_DMG_ACID2"
    echo "    $0 $CMD_CGB_ACID2"
    echo "    $0 $CMD_CGB_ACID_HELL"
    echo "    $0 $CMD_GAMBATTE"
    echo "    $0 $CMD_MEALYBUG_TEAROOM_TESTS"
    echo "    $0 $CMD_MOONEYE_GB"
    echo "    $0 $CMD_RELEASE_ZIP <zip-file>"
    echo "    $0 $CMD_RGBDS"
    echo "    $0 $CMD_SAME_SUITE"
    exit 1
}

mkdir_artifact()
{
    if [ -z "$1" ]; then
        echo "artifact name not specified"
        exit 1
    fi
    ART_DIR="$ARTIFACTS_DIR/$1"

    # delete old artifact
    # (dir and tar* file)
    rm -rf "$ART_DIR"*

    # create artifact dir
    mkdir -p "$ART_DIR"
    echo "$ART_DIR"
}

tar_rm_artifact()
{
    ARTIFACT_NAME=$1
    if [ -z "$ARTIFACT_NAME" ]; then
        echo "artifact name not specified"
        exit 1
    fi
    ART_DIR="$ARTIFACTS_DIR/$ARTIFACT_NAME"

    # tar artifact
    cd "$ARTIFACTS_DIR"
    tar -czf "$ARTIFACT_NAME.tar.gz" "$ARTIFACT_NAME"

    # remove untar'd artifact files as they
    # should not be uploaded
    rm -rf "$ARTIFACT_NAME"
}

untar_all_artifacts()
{
    # untar and remove all tar files in the current directory
    for f in *.tar*; do
        if [ -f "$f" ]; then
            tar -xvf "$f" && rm "$f"
        fi
    done
}



assemble_blargg()
{
    ARTIFACT_NAME=blargg
    ARTIFACT=$(mkdir_artifact $ARTIFACT_NAME)

    REPO=$(mktemp -d)
    cd "$REPO"
    git clone https://github.com/retrio/gb-test-roms.git .
    git checkout c240dd7d700e5c0b00a7bbba52b53e4ee67b5f15

    rsync -am --include='*.gb' --include='*/' --exclude='*' ./ "$ARTIFACT"

    cd "$SRC_DIR/blargg-expected"
    rsync -am ./ "$ARTIFACT"

    tar_rm_artifact $ARTIFACT_NAME
}



assemble_gambatte()
{
    ARTIFACT_NAME=gambatte
    ARTIFACT=$(mkdir_artifact $ARTIFACT_NAME)

    REPO=$(mktemp -d)
    cd "$REPO"
    git clone https://github.com/pokemon-speedrunning/gambatte-speedrun.git .
    git checkout 4387f0dec5381a69ba247ca5984b0d1fcc9fbc8d
    cd test
    chmod +x ./scripts/assemble_tests.sh
    ./scripts/assemble_tests.sh

    cd hwtests
    rsync -am --include='*.gb' --include='*/' --exclude='*' ./ "$ARTIFACT"
    rsync -am --include='*.gbc' --include='*/' --exclude='*' ./ "$ARTIFACT"
    rsync -am --include='*.png' --include='*/' --exclude='*' ./ "$ARTIFACT"

    tar_rm_artifact $ARTIFACT_NAME
}



assemble_mooneye_gb()
{
    ARTIFACT_NAME=mooneye-gb
    ARTIFACT=$(mkdir_artifact $ARTIFACT_NAME)

    REPO_WLA_DX=$(mktemp -d)
    cd "$REPO_WLA_DX"
    git clone https://github.com/vhelin/wla-dx.git .
    git checkout eba3774e8d06f9d92f7ec1d4f39a0f3b9a92b27d
    cmake -G "Unix Makefiles" .
    make wla-gb wlalink
    PATH="$REPO_WLA_DX/binaries:$PATH"

    REPO=$(mktemp -d)
    cd "$REPO"
    git clone https://github.com/Gekkio/mooneye-gb.git .
    git checkout 2d52008228557f9e713545e702d5b7aa233d09bb
    make -C tests clean all

    cd tests
    rsync -am --include='*.png' --include='*/' --exclude='*' ./ "$ARTIFACT"
    cd build
    rsync -am --include='*.gb' --include='*/' --exclude='*' ./ "$ARTIFACT"

    tar_rm_artifact $ARTIFACT_NAME
}



build_rgbds()
{
    ARTIFACT_NAME=rgbds
    ARTIFACT=$(mkdir_artifact $ARTIFACT_NAME)

    # build rgbds from source:
    # https://rgbds.gbdev.io/install/source
    REPO_RGBDS=$(mktemp -d)
    cd "$REPO_RGBDS"
    git clone https://github.com/gbdev/rgbds.git .
    git checkout e970b6d6eb50125717e637375bd893f223d2c7e7
    cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
    cmake --build build

    cp build/src/rgbasm build/src/rgbfix build/src/rgbgfx build/src/rgblink "$ARTIFACT"

    tar_rm_artifact $ARTIFACT_NAME
}



build_age_test_roms()
{
    # extract RGBDS artifacts
    cd "$ARTIFACTS_DIR"
    untar_all_artifacts
    PATH="$ARTIFACTS_DIR/rgbds:$PATH"

    ARTIFACT_NAME=age-test-roms
    ARTIFACT=$(mkdir_artifact $ARTIFACT_NAME)

    REPO_AGE_TEST_ROMS=$(mktemp -d)
    cd "$REPO_AGE_TEST_ROMS"
    git clone https://github.com/c-sp/age-test-roms.git .
    git checkout 620943b975d8a471f308e58f6499467871649c4d
    make

    cd build
    rsync -am --include='*.gb' --include='*/' --exclude='*' ./ "$ARTIFACT"

    tar_rm_artifact $ARTIFACT_NAME
}



build_dmg_acid2()
{
    # extract RGBDS artifacts
    cd "$ARTIFACTS_DIR"
    untar_all_artifacts
    PATH="$ARTIFACTS_DIR/rgbds:$PATH"

    ARTIFACT_NAME=dmg-acid2
    ARTIFACT=$(mkdir_artifact $ARTIFACT_NAME)

    REPO_DMG_ACID2=$(mktemp -d)
    cd "$REPO_DMG_ACID2"
    git clone --recurse-submodules https://github.com/mattcurrie/dmg-acid2 .
    git checkout 8a98ce731f96dde032ffb22ec36dc985d78fdb18
    make

    cp build/dmg-acid2.gb "$ARTIFACT"
    cp img/reference-cgb.png "$ARTIFACT/dmg-acid2-cgb.png"
    cp img/reference-dmg.png "$ARTIFACT/dmg-acid2-dmg.png"

    tar_rm_artifact $ARTIFACT_NAME
}



build_cgb_acid2()
{
    # extract RGBDS artifacts
    cd "$ARTIFACTS_DIR"
    untar_all_artifacts
    PATH="$ARTIFACTS_DIR/rgbds:$PATH"

    ARTIFACT_NAME=cgb-acid2
    ARTIFACT=$(mkdir_artifact $ARTIFACT_NAME)

    REPO_CGB_ACID2=$(mktemp -d)
    cd "$REPO_CGB_ACID2"
    git clone --recurse-submodules https://github.com/mattcurrie/cgb-acid2 .
    git checkout 76c4e2c42de62141dacc829232eb9e2531a79538
    make

    cp build/cgb-acid2.gbc "$ARTIFACT"
    cp img/reference.png "$ARTIFACT/cgb-acid2.png"

    tar_rm_artifact $ARTIFACT_NAME
}



build_cgb_acid_hell()
{
    # extract RGBDS artifacts
    cd "$ARTIFACTS_DIR"
    untar_all_artifacts
    PATH="$ARTIFACTS_DIR/rgbds:$PATH"

    ARTIFACT_NAME=cgb-acid-hell
    ARTIFACT=$(mkdir_artifact $ARTIFACT_NAME)

    REPO_CGB_ACID_HELL=$(mktemp -d)
    cd "$REPO_CGB_ACID_HELL"
    git clone https://github.com/mattcurrie/cgb-acid-hell.git .
    git checkout 107b7c5a875f26473ebc1193e32c59394bdd3049

    # The GitHub Ubuntu runner does not know any "md5" command
    # (Ubuntu comes with "md5sum" instead).
    # We comment out the "md5" step in the Makefile ...
    sed -i.bak "s/md5/#md5/" Makefile

    make

    cp cgb-acid-hell.gbc "$ARTIFACT"
    cp img/reference.png "$ARTIFACT/cgb-acid-hell.png"

    tar_rm_artifact $ARTIFACT_NAME
}



build_mealybug_tearoom_tests()
{
    # extract RGBDS artifacts
    cd "$ARTIFACTS_DIR"
    untar_all_artifacts
    PATH="$ARTIFACTS_DIR/rgbds:$PATH"

    ARTIFACT_NAME=mealybug-tearoom-tests
    ARTIFACT=$(mkdir_artifact $ARTIFACT_NAME)

    REPO_MEALYBUG_TEAROOM_TESTS=$(mktemp -d)
    cd "$REPO_MEALYBUG_TEAROOM_TESTS"
    git clone --recurse-submodules https://github.com/mattcurrie/mealybug-tearoom-tests.git .
    git checkout 70e88fb90b59d19dfbb9c3ac36c64105202bb1f4
    make

    # Ubuntu (GitHub runner) symlinks "rename" to the Perl script "prename".
    # Fedora comes with the regular "rename".
    # As these two are not compatible and I thus would not be able
    # to test this script on my machine, we do this the hard way ...
    for f in expected/CPU\ CGB\ C/*.png; do
        mv -- "$f" "${f%.png}_cgb_c.png"
    done
    for f in expected/CPU\ CGB\ D/*.png; do
        mv -- "$f" "${f%.png}_cgb_d.png"
    done
    for f in expected/DMG-CPU\ B/*.png; do
        mv -- "$f" "${f%.png}_dmg_b.png"
    done
    for f in expected/DMG-blob/*.png; do
        mv -- "$f" "${f%.png}_dmg_blob.png"
    done

    cd build
    rsync -am --include='*.gb' --include='*/' --exclude='*' ./ "$ARTIFACT"

    cd ..
    cp expected/CPU\ CGB\ C/*.png "$ARTIFACT/ppu"
    cp expected/CPU\ CGB\ D/*.png "$ARTIFACT/ppu"
    cp expected/DMG-CPU\ B/*.png "$ARTIFACT/ppu"
    cp expected/DMG-blob/*.png "$ARTIFACT/ppu"

    tar_rm_artifact $ARTIFACT_NAME
}



build_same_suite()
{
    # extract RGBDS artifacts
    cd "$ARTIFACTS_DIR"
    untar_all_artifacts
    PATH="$ARTIFACTS_DIR/rgbds:$PATH"

    ARTIFACT_NAME=same-suite
    ARTIFACT=$(mkdir_artifact $ARTIFACT_NAME)

    REPO_SAME_SUITE=$(mktemp -d)
    cd "$REPO_SAME_SUITE"
    git clone https://github.com/LIJI32/SameSuite.git .
    git checkout a09fc186fb6c42e2e496d804b46129a8d02c067a

    make
    pwd

    rsync -am --include='*.gb' --include='*/' --exclude='*' ./ "$ARTIFACT"

    tar_rm_artifact $ARTIFACT_NAME
}



create_release_zip()
{
    ZIP_FILE=$1
    if [ -z "$ZIP_FILE" ]; then
        print_usage_and_exit
    fi

    mkdir -p "$ARTIFACTS_DIR"
    cp README.md CHANGELOG.md "$ARTIFACTS_DIR"

    # remove old zip file
    cd "$ARTIFACTS_DIR"
    rm -rf "$ZIP_FILE"

    # create new zip file
    untar_all_artifacts
    rm -rf rgbds
    zip -r "$ZIP_FILE" .
}



###############################################################################
##
##   script starting point
##
###############################################################################

CMD_BLARGG=blargg-roms
CMD_GAMBATTE=gambatte-roms
CMD_MOONEYE_GB=mooneye-gb-roms
CMD_RGBDS=rgbds
CMD_AGE_TEST_ROMS=age-test-roms
CMD_DMG_ACID2=dmg-acid2
CMD_CGB_ACID2=cgb-acid2
CMD_CGB_ACID_HELL=cgb-acid-hell
CMD_MEALYBUG_TEAROOM_TESTS=mealybug-tearoom-tests
CMD_SAME_SUITE=same-suite
CMD_RELEASE_ZIP=release-zip

# identify repository directories based on the path of this script
SCRIPT_DIR=$(dirname "$0")
REPO_DIR=$(cd "$SCRIPT_DIR/.." && pwd -P)
ARTIFACTS_DIR="$REPO_DIR/artifacts"
SRC_DIR="$REPO_DIR/src"

# check the first parameter
CMD=$1
if [ -n "$CMD" ]; then
    shift
fi

case ${CMD} in
    "${CMD_BLARGG}") assemble_blargg "$@" ;;
    "${CMD_GAMBATTE}") assemble_gambatte "$@" ;;
    "${CMD_MOONEYE_GB}") assemble_mooneye_gb "$@" ;;
    "${CMD_RGBDS}") build_rgbds "$@" ;;
    "${CMD_AGE_TEST_ROMS}") build_age_test_roms "$@" ;;
    "${CMD_DMG_ACID2}") build_dmg_acid2 "$@" ;;
    "${CMD_CGB_ACID2}") build_cgb_acid2 "$@" ;;
    "${CMD_CGB_ACID_HELL}") build_cgb_acid_hell "$@" ;;
    "${CMD_MEALYBUG_TEAROOM_TESTS}") build_mealybug_tearoom_tests "$@" ;;
    "${CMD_SAME_SUITE}") build_same_suite "$@" ;;
    "${CMD_RELEASE_ZIP}") create_release_zip "$@" ;;

    *) print_usage_and_exit ;;
esac

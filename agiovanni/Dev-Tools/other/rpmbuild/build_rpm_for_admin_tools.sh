#!/bin/bash
# Check out all STASH repositories and builds a top-level RPM.
# Must have STASH access configured.
# Author: Michael Nardozzi  <michael.a.nardozzi@nasa.gov>

# Must run from the users home directory
if [[ $(pwd) != "$HOME/rpmbuild" ]]; then
    echo "Must be run from $HOME/rpmbuild" 1>&2
    exit 1
fi

# Make sure TMPDIR is set and scripts can be run from it
if [[ ! -d "$TMPDIR" ]]; then
    echo "Define TMPDIR environment variable and make sure that directory exists." 1>&2
    exit 1
else
    if [[ `df $TMPDIR | tail -1 | rev | cut -f1 -d ' ' | rev | xargs -I {} sh -c "mount | grep ' {} ' | cut -d ' ' -f6 | grep noexec"` != '' ]]; then
        echo "TMPDIR is set to $TMPDIR and cannot be used because it is on a file system ($FS) which is disallowed from running executables. Please set TMPDIR to another directory." 1>&2
        exit 1
    fi
fi

# Read from standard input
if [[ $1 == "" ]]; then
    echo "Usage $0 GIT_TAG REV OPT_INSTALL_FLAG" 1>&2
    exit 1
fi

echo "Checking out from GIT repository" 1>&2

# Args
branch_name=$1 # Where branch_name is the git Branch you are building from
rev=$2 # Where rev is the revision number of the RPM
package=$3 # Where package is the package your are installing ie. agiovanni_admin

# Use the date as the version if building from HEAD
if [[ $branch_name == "HEAD" ]]; then
    version=$(date +"%Y%m%d").$rev
else
    version=$(echo $branch_name | sed -e 's/\-/_/g').$rev
fi

# Generate tarball containing all repositories
# ----------------------------------------------------------
tmp_dir=$(mktemp -d)
cd $tmp_dir
mkdir $package-$version
cd $package-$version

# Clone and checkout from GIT repository
URL1='https://git.earthdata.nasa.gov/scm/fedgianni/'$package'.git'
git clone -b $branch_name $URL1

# If SPECS directory does not exist, then make it so we can store the
# RPM build specification file(s)
if [ ! -d ~/rpmbuild/SPECS/ ]; then
    mkdir ~/rpmbuild/SPECS/
# Copy the SPECS file template(s) to the newly created SPECS directory under
# our buildroote 
cp agiovanni/Dev-Tools/other/rpmbuild/SPECS/*.template ~/rpmbuild/SPECS/
fi

cd ..

# Zip up the tarball and copy the file to the sources directory
tar czvf $package-$version.tar.gz $package-$version
mkdir -p ~/rpmbuild/SOURCES
cp $package-$version.tar.gz ~/rpmbuild/SOURCES

cd ~/rpmbuild

# Create specfile based on template
# ----------------------------------------------------------
arch=$(arch)

# We use this spec file for git
cat SPECS/$package\.spec.template \
| sed -e "s/__ARCH__/$arch/g" \
| sed -e "s/__VERSION__/$version/g" \
> SPECS/$package\.spec

# Build the RPM
# ----------------------------------------------------------
rpmbuild -ba SPECS/$package\.spec

rm -rf $tmp_dir  # Removes tmp directory

if [[ $? == 0 ]]; then
    echo Success
else
    echo Failure
fi

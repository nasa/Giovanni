#!/bin/bash
# Check out all STASH repositories and builds a top-level RPM.
# Must have STASH access configured.
# Author: Daniel da Silva <Daniel.e.daSilva@nasa.gov>
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
    echo "Usage $0 GIT_TAG RELEASE_NUMBER REVISION_NUMBER OPT_PARTNER_FLAG" 1>&2
    exit 1
fi

echo "Checking out from GIT repositiry" 1>&2

# Args
branch_name=$1 # This is the git repo you are building the RPM from
release=$2 # This is the giovanni release number 
rev=$3 # This is the revision number of the giovanni release
opt_partner_flag=$4 # Use this flag for installing a specific giovanni partner instance (For example: aGiovanni_podaac)

# Set the default repository for agiovanni if the user does not supply a custom repo
if [[ $4 = "" ]]; then
    opt_partner_flag="giovanni"
fi

# Use the date as the version if building from HEAD
if [[ $branch_name == "HEAD" ]]; then
    version=$(date +"%Y%m%d").$rev
else
    version=$(echo $release | sed -e 's/\-/_/g').$rev
fi

# Generate tarball containing all repositories
# ----------------------------------------------------------
tmp_dir=$(mktemp -d)

cd $tmp_dir

mkdir giovanni4-$version
cd giovanni4-$version

# Clone and checkout from GIT repository
URL1='https://git.earthdata.nasa.gov/scm/fedgianni/agiovanni.git'
URL2='https://git.earthdata.nasa.gov/scm/fedgianni/agiovanni_algorithms.git'
URL3='https://git.earthdata.nasa.gov/scm/fedgianni/agiovanni_dataaccess.git'
URL4='https://git.earthdata.nasa.gov/scm/fedgianni/agiovanni_www.git'
URL5='https://git.earthdata.nasa.gov/scm/fedgianni/agiovanni_shapes.git'
URL6='https://git.earthdata.nasa.gov/scm/fedgianni/agiovanni_admin.git'
URL7='https://git.earthdata.nasa.gov/scm/fedgianni/jasmine.git'
URL8='https://git.earthdata.nasa.gov/scm/fedgianni/agiovanni_'$opt_partner_flag'.git'

git clone -b $branch_name $URL1
git clone -b $branch_name $URL2
git clone -b $branch_name $URL3
git clone -b $branch_name $URL4
git clone -b $branch_name $URL5
git clone -b $branch_name $URL6
git clone -b $branch_name $URL7
git clone -b $branch_name $URL8

# Set the path to include addGiovanniServices.pl; this is to make sure that 
# addGiovanniService.pl can be run without its prior installation
CWD="$(pwd)"
chmod 0755 $CWD/agiovanni/Dev-Tools/scripts/addGiovanniService.pl
export PATH=$PATH:$CWD/agiovanni/Dev-Tools/scripts

# We need to check if there is a shapefiles directory under buildroot
if [ -d "/var/giovanni/shapefiles" ]; then
    cp -vr /var/giovanni/shapefiles .
fi
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
tar czvf giovanni4-$version.tar.gz giovanni4-$version
mkdir -p ~/rpmbuild/SOURCES
cp giovanni4-$version.tar.gz ~/rpmbuild/SOURCES

cd ~/rpmbuild

# Create specfile based on template
# ----------------------------------------------------------
arch=$(arch)

# We use this spec file for git
cat SPECS/giovanni4.spec.template \
| sed -e "s/__ARCH__/$arch/g" \
| sed -e "s/__VERSION__/$version/g" \
| sed -e "s/__PARTNER_REPO__/agiovanni_$opt_partner_flag/g" \
> SPECS/giovanni4.spec

# Build the RPM
# ----------------------------------------------------------
rpmbuild -ba SPECS/giovanni4.spec

rm -rf $tmp_dir  # Removes tmp directory

if [[ $? == 0 ]]; then
    echo Success
else
    echo Failure
fi

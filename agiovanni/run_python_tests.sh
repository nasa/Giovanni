#!/bin/bash
# Runs python unit tests in all sub-directories.
# Tests are identified by matching 't/*_test.py'
# Exits with 0 if all successful, otherwise the exit code
# of the first failure, unless --safe is given in which
# case always exit with 0.
# Author: Daniel da Silva <Daniel.E.daSilva@nasa.gov>

rc=0  # global

say_colored() {
    local text=$1

    echo -n $(tput bold)$(tput setaf 6)
    echo -n $text
    echo $(tput sgr0)
}

# modifies $rc global 
normal_tests() {
    for child in $(ls | sort); do
        if [ ! -d "$child" ]; then
            continue  # skip non-directories
        fi
        
        cd "$child"

        for test_file in $(find . -name '*_test.py'); do
            say_colored "Running $child/${test_file:2}"

            PYTHONPATH=scripts:src:../bin \
                python $test_file 2>&1
            
            local this_rc=$?
            if [[ $this_rc != 0 ]]; then
                rc=$this_rc
            fi

            echo
        done
        
        cd ..
    done
}

special_tests() {
    say_colored "Running tests for agiovanni python package"

    cd python

    nosetests

    local this_rc=$?
    if [[ $this_rc != 0 ]]; then
        rc=$this_rc
    fi

    cd ..
}


normal_tests
special_tests


if [[ $rc == 0 ]]; then
    echo 
    echo ==============================================
    echo Testing done. All tests passed.
    echo ==============================================
else
    echo 
    echo ==============================================
    echo Testing done. At least one python test failed.
    echo ==============================================
fi

if [[ $1 != '--safe' ]]; then
    exit $rc
fi

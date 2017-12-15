#!/usr/bin/env sh

# TODO add flags to decide whether or not to clean
stack clean
stack build --coverage
test_file=`stack test --coverage 2>&1 | egrep -i "The coverage report for GS1Combinators's test-suite \"GS1Combinators-test\" is available at " | sed "s/The coverage report for GS1Combinators's test-suite \"GS1Combinators-test\" is available at //g"`

echo $test_file
(google-chrome $test_file &)
echo

use inc::Module::Install;
name 'Micrawler';
all_from 'lib/Micrawler.pm';

# requires '';

tests 't/*.t';
author_tests 'xt';

author 'Camille Maussang';

readme_from 'lib/Micrawler.pm';

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;

cd $(dirname $0)
cd ..
perl Build.PL
cover -delete
HARNESS_PERL_SWITCHES=-MDevel::Cover ./Build test
cover

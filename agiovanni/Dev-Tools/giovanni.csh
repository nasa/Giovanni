alias aggodir 'set dir=`convertGiovanniUrlToDir.pl \!:1`; chdir $dir'
alias makemyg4 'createGiovanniSandbox.pl -task deploy -repo ecc'
alias makemyg4fromcvs 'createGiovanniSandbox.pl -task deploy -repo cvs'
alias makemy83c 'createGiovanniSandbox.pl -task deploy -repo cvs -version "Sprint-83-C" -force'

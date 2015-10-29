#!/usr/bin/env perl 
#===============================================================================
#         FILE: perl-mail-gen.pl
#        USAGE: ./perl-mail-gen.pl  
#       AUTHOR: Sergey Magochkin (), magaster@gmail.com
#      CREATED: 10/18/2015 22:23:40
#===============================================================================

use strict;
use warnings;
use utf8;
use v5.18;
use Data::Random qw(:all);
use Getopt::Long qw(GetOptions);

my $emails_count = 1000; #per file  max 45427
my $files_count = 3;
my $prefix_file = "output_";

GetOptions(
           'emails_count=i' => \$emails_count,
           'files_count=i' => \$files_count,
           'prefix_file=s' => \$prefix_file,
                                            ) or die "Usage: $0 --emails_count 999 \n"
                                                    . "Default: $emails_count \n"
                                                    . "Usage: $0 --files_count 1 \n"
                                                    . "Default: $files_count \n"
                                                    . "Usage: $0 --prefix_file NAME \n"
                                                    . "Default \"$prefix_file\" \n";


my @mail_list = (
                 "mail.ru",
                 "gmail.ru",
                 "bk.ru",
                 "yandex.ru",
                 "correct-b10.com",
                 "123.pro",
                 "_uncorrect.com",
                 qw(!@$%^&&uncorrect_name.333),
             );



while($files_count--) {
    my @random_words = rand_words( size => $emails_count );
    my $name_output_file = $prefix_file . ($files_count+1) . ".txt";
    open (FILE, ">" , $name_output_file) or die "can't open or create file $!";
    foreach my $name (@random_words) {
        $name = $name . rand_chars( set => 'all', min => 1, max => 2 );
        $name = $name . "@" . $mail_list[rand(@mail_list)];
        print FILE $name . "\n";
    }
}

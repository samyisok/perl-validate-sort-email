#!/usr/bin/env perl 
#===============================================================================
#         FILE: perl-sort-mail.pl
#        USAGE: ./perl-sort-mail.pl
#       AUTHOR: Sergey Magochkin (), magaster@gmail.com
#      VERSION: 1.0
#      CREATED: 10/22/2015 22:28:38
#===============================================================================

use strict;
use warnings;
use utf8;
use v5.18;
use List::MoreUtils qw(uniq part);
use Unicode::CaseFold;
use threads;
use threads::shared;

my $treads_count  = 4;
my @treads_arrays = ();
my $regex =
qr/^[a-zA-Z0-9.!#$%&'*+\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$/;
my @main_email_array = ();

my @final_array : shared;
my %final_hash : shared;

sub sort_by_domain {
    my (@array) = @_;
    my %tmp_hash;
    foreach my $email (@array) {
        my $domain = lc( ( split /@/, $email )[1] );
        if ( exists $tmp_hash{$domain} ) {
            $tmp_hash{$domain}++;
        }
        else {
            $tmp_hash{$domain} = 1;
        }
    }
    return %tmp_hash;
}

sub valid_by_mail {
    my (@array_email) = @_;
    chomp @array_email;
    my @tmp_array = ();
    foreach my $email (@array_email) {
        push @tmp_array, $email if $email =~ $regex;
    }
    return @tmp_array;
}

sub check_and_sort_email {
    my (@tmp_array) = @_;
    @tmp_array = valid_by_mail(@tmp_array);
    my %hash = sort_by_domain(@tmp_array);
    {
        lock(@final_array);
        push @final_array, @tmp_array;
    }
    {
        lock(%final_hash);
        foreach my $key ( keys %hash ) {
            if ( exists $final_hash{$key} ) {
                $final_hash{$key} = $final_hash{$key} + $hash{$key};
            }
            else {
                $final_hash{$key} = $hash{$key};
            }
        }
    }

}

die "file list is empty\n" unless (@ARGV);

foreach my $filename (@ARGV) {
    die "can't find file $!\n" unless ( -e $filename );
    open( FILE, "<", $filename ) or die "can't read file $!";
    while (<FILE>) {
        my $email = $_;
        push @main_email_array, $email;
    }
}



say "In list email: " . scalar @main_email_array;
my $time1 = time();
$_ = fc foreach (@main_email_array);
my $time2 = time();
@main_email_array =  uniq(@main_email_array);
my $time3 = time();

my $i = 0;
$treads_count = 1 if ( scalar @main_email_array < 8 );
@treads_arrays =
  part { ( $treads_count * $i++ ) / @main_email_array } @main_email_array;
my @treads_list;
my $treads = $treads_count;
while ( $treads-- ) {
    say "Start Job: $treads";
    push @treads_list,
      (
        threads->create(
            sub { check_and_sort_email( @{ $treads_arrays[$treads] } ) }
        )
      );
}

foreach (@treads_list) {
    $_->join;
    say "JobDone";
}

print "Totaly correct emails: ";
say scalar @final_array;
print "Totaly correct domains: ";
say scalar( keys %final_hash );

open( FILE, ">", "output_report.txt" );
foreach
  my $name ( sort { $final_hash{$a} <=> $final_hash{$b} } keys %final_hash )
{
    print FILE "$name = $final_hash{$name}\n";
}
close FILE;

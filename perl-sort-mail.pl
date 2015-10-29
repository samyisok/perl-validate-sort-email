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
use Test::More;

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

sub test_sort_by_domain {
    my @test_input_array =
      ( 'magaster@gmail.com', 'test@gmail.com', 'test@yandex.ru' );
    my $test_expected_hash = { 'gmail.com' => 2, 'yandex.ru' => 1, };
    my (%test_output) = sort_by_domain(@test_input_array);
    is_deeply( \%test_output, $test_expected_hash,
        "making test sort by domain" );

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

sub test_valid_by_mail {
    my @test_input_array =
      qw/ magaster@gmail.com $$$uncorrect@mail.com 3424234@_234.com @@@@ /;
    my @test_expect_array = qw / magaster@gmail.com /;
    my @test_output       = valid_by_mail(@test_input_array);
    is_deeply( @test_output, @test_expect_array, "making test valid by mail" );
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

sub test_check_and_sort_email {
    my @test_input_array =
      qw/ magaster@gmail.com $$$uncorrect@mail.com 3424234@_234.com @@@@ correct@yandex.ru correct@gmail.com /;
    my $test_expected_hash = { 'gmail.com' => 2, 'yandex.ru' => 1, };
    my @test_expected_array =
      qw/ magaster@gmail.com correct@yandex.ru correct@gmail.com /;
    check_and_sort_email(@test_input_array);
    is_deeply( \@test_expected_array, \@final_array,
        "make test final array from check and sort email" );
    is_deeply( $test_expected_hash, \%final_hash,
        "make test final hash from check and sort email" );

}

my ($is_test) = @ARGV;
if ( $is_test eq "make_test" ) {
    plan tests => 4;
    make_test();
}

sub make_test {
    test_sort_by_domain();
    test_valid_by_mail();
    test_check_and_sort_email();
    done_testing();
    exit 0;
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
@main_email_array = uniq(@main_email_array);
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

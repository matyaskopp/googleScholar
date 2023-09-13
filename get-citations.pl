#!/usr/bin/env perl

use warnings;
use strict;
use open qw(:std :utf8);
use utf8;
use Getopt::Long;
use Text::CSV qw/csv/;

use Data::Dumper;

my ($in,$out);

GetOptions (
            'in=s' => \$in,
            'out=s' => \$out,
        );


my $INPUT;
my $OUTPUT;

my %mapping = (
    googleScholarID => 'Cluster ID',
    googleScholarTitle => 'Title',
    citations => 'Citations',
    versions => 'Versions',
  );

if($in){
  open $INPUT,"<$in" or die "ERROR: unable to open file for reading: $in";
  binmode $INPUT;
} else {
  $INPUT = *STDIN;
}

if($out){
  open $OUTPUT,">$out" or die "ERROR: unable to open file for writing: $out";
} else {
  $OUTPUT = *STDOUT;
}

my $tsv_in = Text::CSV->new ({ binary => 1, auto_diag => 1, sep_char=> "\t" });
#print STDERR <$INPUT>;die;
$tsv_in->header ($INPUT, { detect_bom => 1, munge_column_names => "none"});

my $tsv_out = Text::CSV->new ({ binary => 1, auto_diag => 1, sep_char=> "\t", eol => $/, quote_char => undef });
$tsv_out->column_names(qw/cuniID year title googleScholarID googleScholarTitle harvestDate citations versions/);
$tsv_out->print($OUTPUT,[$tsv_out->column_names]);

my $row;
my @rows;
my $today;
while (my $record = $tsv_in->getline_hr($INPUT)) {
  my $result={};
  $result->{cuniID} = $record->{'ID publikace'};
  $result->{year} = $record->{'Rok'};
  $result->{title} = $record->{'Název'};
  $result->{harvestDate} = $today;
  queryGoogleScholar($result,$result->{year}, $result->{title});
  $tsv_out->print_hr ($OUTPUT, $result);
  $tsv_out->print_hr (*STDOUT, $result);

}

close $INPUT if $in;
close $OUTPUT if $out;


sub queryGoogleScholar {
  my ($result, $year, $title) = @_;
  my $cmd = sprintf('python3 scholar.py -c 1 --after %d --before %d --phrase "%s" --title-only',$year,$year,$title);
  my $resp = `$cmd`;
  print "$cmd\n$resp\n";
  for my $line (split(/ *\n */,$resp)){
    for my $k (keys %mapping){
      my $pref = $mapping{$k};
      my ($val) = $line =~ /^ *$pref *(.*)$/;
      $result->{$k} //= $val if defined $val;
    }
  }
}
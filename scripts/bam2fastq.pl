#!/usr/bin/perl -w
use strict;
use Data::Dumper;
use File::Basename;

# Input a .bam file, and output .fastq files
@ARGV == 3 or die "Usage: perl $0 <FI: bam file> <DIR: output> <STR: file name>\n";
my ($bam,$outdir,$name) = @ARGV;
my $samtools = "samtools";
system("mkdir $outdir") unless (-e "$outdir");
my %dictionary = qw{A T T A C G G C};

open FQ1, ">$outdir/$name.1.fq" or die "$!";
open FQ2, ">$outdir/$name.2.fq" or die "$!";
my ($fq1,$fq2) = (0,0);

open ERROR, ">Error.info" or die "$!";
open BAM, "$samtools view $bam |" or die "$!";
while(<BAM>){
    chomp;
    my ($rname,$flag,$seq,$quality) = (split /\s+/)[0,1,9,10];
    my ($readflag,$reverse) = &ParseFlagReads($flag);
    my $thisseq = &readReverseOrNot($seq,$reverse);
    my $thisquality = &qualityReverse($quality,$reverse);
    if ($readflag == 1){
        print FQ1 "\@$rname/$readflag\n$thisseq\n+\n$thisquality\n";
        $fq1++;
    }elsif ($readflag == 2){
        print FQ2 "\@$rname/$readflag\n$thisseq\n+\n$thisquality\n";
        $fq2++;
    }
}
close BAM;
close FQ1;
close FQ2;
close ERROR;

if ($fq1 > 0){
    `gzip $outdir/$name.1.fq`;
}else{
    `rm -f $outdir/$name.1.fq`;
}

if ($fq2 > 0){
    `gzip $outdir/$name.2.fq`;
}else{
    `rm -f $outdir/$name.2.fq`;
}

################ Sub Function ################
sub qualityReverse{
    my ($string,$reverse) = @_;
    my $outstring;
    if ($reverse == 1){
        $outstring = reverse $string;
    }else{
        $outstring = $string;
    }
    return $outstring;
}

sub readReverseOrNot{
    my ($string,$reverse) = @_;
    my $outstring;
    if ($reverse == 1){
        my $tmp = reverse $string;
        my @tmp = split //, $tmp;
        my @new;
        for my $base(@tmp){
            my $rbase = $dictionary{$base};
            unless ($rbase){
                print ERROR join("\t",$base,$string,$reverse),"\n";
            }
            push @new, $rbase;
        }
        $outstring = join("",@new);
    }else{
        $outstring = $string;
    }
    return $outstring;
}
    
sub ParseFlagReads{
    my ($number) = @_;
    my ($readflag,$reverse) = (0,0);
    my $binary = sprintf( "%b", $number);
    my @binary = split //,$binary;
    if ($binary[-7] == 1){
        $readflag = 1;
    }elsif ($binary[-8] == 1){
        $readflag = 2;
    }
    if ($binary[-5] == 1){
        $reverse = 1;
    }
    return ($readflag,$reverse);
}

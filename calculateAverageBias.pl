#!/usr/bin/perl
##############
#
# calculateAverageBias.pl
# take the input of the committeeBiasFile s for the previous weeks of a season (from weeks 10-15)
# and calculate the average bias for a team for the whole season
# get the week number of input from the cli
#
# usage: calculateAverageBias.pl year week
#
# input files: committeeBias file(s)  week 9-15
#
# output files: averageCommitteeBias file week 9-15
#
##############



use strict;
use Math::MatrixReal;
use Data::Dumper;
use Statistics::Basic qw(:all ipres=4);   #ipres sets the precision of the mean function - 3 significant digits


if ($#ARGV != 1) {     #should be 2 aruments on CLI
print "Usgae: calculateAverageBias.pl year week\n";
print "example- calculateAverageBias.pl 2014 10\n";
die;
 }

my ($year,$week) = @ARGV;

if (($year < 2014) || ($year > 2015))  {
print "year should be 2014 or 2015\n";
die;
 }

if (($week < 9) || ($week > 15))  {
print "week should be between 9 - 15\n";
die;
 }




my $fbsTeams = "/home/neville/cfbPlayoffPredictor/data/$year/fbsTeamNames.txt";



#Read in FBS teams for this year
my (%team,%teamH) = ();   #initialize both hases in one line
open (FBSTEAMS, "<", $fbsTeams) or die "Can't open the file $fbsTeams";
while (my $line = <FBSTEAMS> )   {
    chomp ($line);
    my ($a, $b) = split(" => ", $line);   #this will result in $key holding the name of a team (1st thing before split)
    $team{$b} = $a;
    $teamH{$a} = $b;
}     #at the conclusion of this block $team{4} will be "Florida State" and $teamH{Auburn} will be "53"
my @teams=keys(%team);                     #this creates @teams array which has elements like ("127" , "32" , "90" , "118" ,... , "34") - not sure of the value of that
my $numberOfTeams = $#teams + 1;  #$#teams starts counting at zero



my $teamName;
my $teamBias;
my $numberOfTeams = $#teams + 1;  #$#teams starts counting at zero
my $n = $week;  # week number of input  
my $k;
my $committeeBiasFile;
my $averageCommitteeBiasFile;
my $biasInput;
my $z;



#Create the weekly biases as a matrix --  best way I can figure to do it at this point
my $biasMatrix = new Math::MatrixReal($numberOfTeams, $n-8);  #minus 8 becasue week 10 should be 2 columns wide, for example











for (   $k=9;   $k<=$week;  $k++   ) {   

$committeeBiasFile = "/home/neville/cfbPlayoffPredictor/data/$year/week$k/Week$k" . "CommitteeBiasFile.txt";     # input file for script	
open (SINGLEWEEKCOMMITTEEBIASFILE, "<$committeeBiasFile") or die "$! error trying to open";     

my $r = 0;
for $biasInput (<SINGLEWEEKCOMMITTEEBIASFILE>) {
 $r = $r +1;
($teamName, $teamBias) = (split / ratingBias is /, $biasInput);
 $biasMatrix->assign($r, $k-8, $teamBias);      #format of matrix is [team, week]
}

close SINGLEWEEKCOMMITTEEBIASFILE;



}

#my $value = $biasMatrix->element (1, 2);
#print "$value\n";


#print $biasMatrix;

#print $biasMatrix->element (1,1);   #these are the weeks of Boston College's bias
#print $biasMatrix->element (1,2);
#print $biasMatrix->element (1,3);
#print $biasMatrix->element (1,4);
#print $biasMatrix->element (1,5);
#print $biasMatrix->element (1,6);

#print "\n";
#print $biasMatrix->element (2,1); #these are the weeks of Clemson's bias
#print $biasMatrix->element (2,2);
#print $biasMatrix->element (2,3);
#print $biasMatrix->element (2,4);
#print $biasMatrix->element (2,5);
#print $biasMatrix->element (2,6);
#print "\n";


$averageCommitteeBiasFile =  "/home/neville/cfbPlayoffPredictor/data/$year/week$week/Week$week" . "AverageCommitteeBiasFile.txt";     # output file for script
#$averageCommitteeBiasFile = "/tmp/Week$week" . "AverageCommitteeBiasFile.txt";   # testing




open (AVERAGECOMMITTEEBIASFILE, ">$averageCommitteeBiasFile") or die "$! error trying to overwrite";   
for (my $i=1; $i<$#teams+2; $i++ ) {    
my @w;
for ($z=9 ;  $z<=$week ; $z++) {
my $value = $biasMatrix->element ($i, $z-8);
#print "$team{$i} ratingBias for week $z is $value"; 
push (@w, $value);
}
my $mean = mean (  @w );
print "average ratingBias of $team{$i} for weeks 9-$week is $mean\n";
print AVERAGECOMMITTEEBIASFILE "$team{$i} averageRatingBiasThroughWeek$week is $mean\n";
}
close AVERAGECOMMITTEEBIASFILE;
print "output through week number $week written to $averageCommitteeBiasFile\n";





	
	
	
	
	



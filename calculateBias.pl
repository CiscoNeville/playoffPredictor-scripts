#!/usr/bin/perl
##############
#
# calculateBias.pl
# Determine the FBS playoff committee bias per team 
# Computes a playoff committee rating bias (rbCV)  which is the difference of where the aga matrix computes each teams  true rating and the listed ratings of the selection committee
# output a file that 
# this script needs to be run once a week on Tuesdays after 6:30pm by the admin

# first week this is valid for is week 9
#
# usage: calculateBias.pl year week
#
# input files: ncfScoresFile  week 9-15
#
# output files: CommitteeBias file week 9-15
#
##############



use strict;
use Math::MatrixReal;
#use Number::Format;
use Data::Dumper;


if ($#ARGV != 1) {     #should be 2 aruments on CLI
print "Usgae: calculateBias.pl year week\n";
print "example- calculateBias.pl 2014 9\n";
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


#use these 3 file for historical analysis
my $committeeCurrentRankingsFile = "/home/neville/cfbPlayoffPredictor/data/$year/week$week/Week$week"."PlayoffCommitteeRankings.txt";   #I know this week's committee rankings  - for POV, think of this script being run on wednesday
my $lastWeekNcfScoresFile = "/home/neville/cfbPlayoffPredictor/data/$year/week$week/Week$week"."NcfScoresFile.txt";   #I know this week's scores
my $committeeBiasFile = "/home/neville/cfbPlayoffPredictor/data/$year/week$week/Week$week"."CommitteeBiasFile.txt";     #so I can compute this weeks bias file.  this is the output file of this script. It is a calculated committee bias file.

#to project next week you need last week's average bias file




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



my $cM;   # the Colley Matrix in line 17 of the colley matrix method
my $rCV;  # the r column-vector in line 17 of the colley matrix method
my $bCV;  # the b column-vector in line 17 of the colley matrix method

my @results;
my $resultsWinner;
my $resultsLoser;

my $teamNumberWinner;
my $teamNumberLoser;

my @teamWins;
my @teamLosses;

my @teams=keys(%team);
my $numberOfTeams = $#teams + 1;  #$#teams starts counting at zero

my @agaRating;
my $rematch =0;

print "number of teams is $numberOfTeams\n\n";
#create the matrix



#create blank matricies
$cM = new Math::MatrixReal($numberOfTeams,$numberOfTeams);
$rCV = new Math::MatrixReal($numberOfTeams,1);    #column vector is this notation. lots of rows, 1 column
$bCV = new Math::MatrixReal($numberOfTeams,1);



#read input data from a file.
my $scoreInput;
my $k;      #there is probably a better way to do this
open (NCFSCORESFILE, "<$lastWeekNcfScoresFile") or die "$! error trying to open";     
for $scoreInput (<NCFSCORESFILE>) {
#   print $scoreInput;

($resultsWinner, $resultsLoser) = (split /:/, $scoreInput);

$scoreInput =~ m/Final.*: (.+?) (\d+) - (.+?) (\d+)/;

my $aTeamName = $1;
my $aTotal = $2;
my $hTeamName = $3;
my $hTotal = $4;


# Determine if a team is a 1AA team and assign them to the team "1AA"
if (  ($aTeamName ~~ [values %team])    )  {
#that's great, away team is FBS. Do Nothing
}
else {   #otherwise it was a 1AA team
$aTeamName = "1AA";
}


if (  ($hTeamName ~~ [values %team])    )  {    #Like it would ever happen -- a 1A team plays a game on the road against a 1AA team
#that's great, home team is FBS. Do Nothing
}
else {   #otherwise it was a 1AA team
$hTeamName = "1AA";
}



#Figure out which team won and give it to the @results array in 1-0 format
 if ($hTotal > $aTotal)  {    #home team won
$results[$k] = "$hTeamName 1-0 $aTeamName";
}
else {    #away team won. No ties anymore...
$results[$k] = "$aTeamName 1-0 $hTeamName";

}
$k++;
}
close NCFSCORESFILE;




#populate the matrix with the data

#create zeros for initial wins and losses for every team
for (my $i = 1; $i<$numberOfTeams+1; $i++ ) {
 $teamWins[$i]=0;
 $teamLosses[$i]=0;
}


#Find an individual game winner
for (my $i = 0; $i<$#results+1; $i++ ) {
($resultsWinner, $resultsLoser) = (split / 1-0 /, $results[$i]);


#now, populate that one win and loss into the cM,
for (my $j = 1; $j<$#teams+3; $j++ ) {           #have not figured out why +3 here...
 if ($team{$j} eq $resultsWinner)  {  
$teamNumberWinner = $j;    
   $teamWins[$j]++;
}
 if ($team{$j} eq $resultsLoser)  {
  $teamNumberLoser = $j;
   $teamLosses[$j]++;
}
}


$rematch = $cM->element($teamNumberWinner,$teamNumberLoser);   #the matrix is symmetrical, so i only have to do this once


   $cM->assign($teamNumberWinner,$teamNumberLoser,-1 + $rematch);     #for 1st rematch   -2 inseted in the array
   $cM->assign($teamNumberLoser,$teamNumberWinner,-1 + $rematch);     
}


#assign the diagonal row of the CM
for (my $i = 1; $i<$#teams+2; $i++ ) {        # dont understand why +2, shuoldnt it be +1
 $cM->assign($i,$i,2+$teamWins[$i]+$teamLosses[$i]);     #the diagonal matrix entries correspond to total games played +2
}



#have to caputure each teams total wins and losses to populate bCV
#input for bCV.   
for (my $i = 1; $i<$#teams+2; $i++ ) {        # dont understand why +2, shuoldnt it be +1
 my $bi=($teamWins[$i]-$teamLosses[$i]);
 $bi=$bi/2;
 $bi=$bi +1;
 $bCV->assign($i,1,$bi);     #bi = 1 + (nwi-nli)/2
}



#solve for rCV
my $dim;
my $base;
my $LRM;  # this is the LR_Matrix defined in MatrixReal and returned by the method decompose_LR

$LRM = $cM->decompose_LR();

if ( ($dim,$rCV,$base) =  $LRM->solve_LR($bCV) ) {
#print "great, it solved the matrix\n";
#Note, I don't actually have to iterate. The Matrix solution takes care of that for me !
}
else {
print "crap, there was no solution to the Colley Matrix  (This should not have happened\n)";
die;
}

#print out the team ratings
#1st split the ratings out into an array with an index for each team


for (my $i = 1; $i<$#teams+2; $i++ ) {        # dont understand why +2, shuoldnt it be +1
 
#get the team rating in human readable form
my $rCVofI = $rCV->row($i);
$rCVofI =~ /\[(.+?)\]/;
$rCVofI = $1;
$rCVofI = sprintf("%.10g", $rCVofI);
#$rCVofI = substr $rCVofI, 0, 5;     # truncate out anything under thousandnths. note, this casues a loss of precision. display only.
if ($rCVofI eq 0.5)  {     #get 0.5 entries in 0.500 format for later sorting  
 $rCVofI = "0.500";
}

$agaRating[$i] = $rCVofI;
#print "$team{$i} agaRating is $rCVofI\n";
}


#Read in playoff committee rankings from file
#Give each team an  implied rating based on the rankings and a "normal squared" distribution  < The distribution theory needs development here
#the implied rating is in the input file,3rd field in 0.000 format
# Right now I'm putting this in the input file till I figure out how to do it correctly and mathematically

my $committeeInput;
my @committeeRanking;
my @committeeRating;



open (COMMITTEECURRENTRANKINGS, "<$committeeCurrentRankingsFile") or die "$! error trying to open";
for $committeeInput (<COMMITTEECURRENTRANKINGS>) {
my ($teamCRanking, $teamC, $teamCRating) = split(':', $committeeInput);
chomp $teamCRating;
$committeeRating[$teamH{$teamC}] = "$teamCRating";
$committeeRanking[$teamH{$teamC}] = "$teamCRanking";
}
close COMMITTEECURRENTRANKINGS;


#Assuming committee rating equal to the 26th place of agaRating to any team not in the committee rankings, but in the top 25 of the Aga Matrix
my @sortedAgaRating = reverse sort @agaRating;  #$sortedAgaRating[26] will be the rating of my 26th team

for (my $i=1; $i<$#teams+2; $i++ ) {        
if ( ($agaRating[$i] gt $sortedAgaRating[25])  && ($committeeRating[$i] eq '') ) {    #team is in top 25 of aga rating but not in top 25 of committee rankings
$committeeRating[$i] = 0.690; 
 }
}

#set all other committeeRatings equal to AgaRatings  - unranked committee teams assume my rating is correct
for (my $i=1; $i<$#teams+2; $i++ ) {        # dont understand why +2, shuoldnt it be +1
if ($committeeRating[$i] eq '') {
$committeeRating[$i] = $agaRating[$i];}    #this should catch bottom teams -- no committe ranking and not in aga top 25.
}



#compute rating bias for each team
#rating bias per team is defined as difference in implied committee rating minus Aga matrix rating
my @ratingBias;


for (my $i=1; $i<$#teams+2; $i++ ) {        # dont understand why +2, shuoldnt it be +1
 $ratingBias[$i] = $committeeRating[$i] - $agaRating[$i] ;
 #If the ratingBias is in scientific notation, convert to decimal
if ($ratingBias[$i] =~ m/e/) {   #matches for an "e" in the x -e format of the number
$ratingBias[$i] = sprintf("%.3f", $ratingBias[$i]);
 }
 
#print "The ratingBias of $team{$i} is $ratingBias[$i]\n";
}


my @output;

#print all the rating biases to a file
open (COMMITTEEBIASFILE, ">$committeeBiasFile") or die "$! error trying to overwrite";
for (my $i=1; $i<$#teams+2; $i++ ) {    
print COMMITTEEBIASFILE "$team{$i} ratingBias is $ratingBias[$i]\n";
$output[$i] = "$ratingBias[$i]:$team{$i}";
}
close COMMITTEEBIASFILE;



#pint the sorted nonzero rating biases to the screen
@output = sort { $b <=> $a } @output;      #notation for reverse numerical sort

for (my $i=0; $i<$#teams+2; $i++ ) {    
my ($outputTeamRatingBias, $outputTeam) = split (':',$output[$i]); 
if ($outputTeamRatingBias > 0){
 $outputTeamRatingBias = substr $outputTeamRatingBias, 0, 6;     # truncate out anything under ten-thousandnths. note, this casues a loss of precision. display only.
print  "$outputTeam  $outputTeamRatingBias\n";
}

if ($outputTeamRatingBias < 0){
 $outputTeamRatingBias = substr $outputTeamRatingBias, 0, 7;     # one extra digit to account for - sign
print  "$outputTeam  $outputTeamRatingBias\n";
}
}


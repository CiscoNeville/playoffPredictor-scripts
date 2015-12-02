#!/usr/bin/perl
##############
#
# calculateAgaRatings.pl
# Use the scores to this point in the season to compute the Aga Matrix
# AgaMatrix is defined as Colley Matrix with all IAA teams repreented by a single team
# This should be run weekly on Tuesdays just before playoff committe rankings are released, as biasFile calculations depends on agaRatingsFile output
#
# Input files: 
#   ncfScoresFile - contains results of games played up to that point in the season
#
# Output files:
#   agaMatrixRatingsFile - agaMatrix ratings of all teams to that point in the season  
#
#   also CurrentCalculatedRatings.txt  - temp, need this to populate homepage and sort for analyze schedule
#
##############



use strict;
use Math::MatrixReal;
use Data::Dumper;


#yes, a better way to do this would be calling the argument on the cli...
my $ncfScoresFile = "/home/neville/cfbPlayoffPredictor/data/current/ncfScoresFile.txt";  
my $agaMatrixRatingsFile = "/home/neville/cfbPlayoffPredictor/data/current/agaMatrixRatings.txt";
my $CurrentCalculatedRatingsFile = "/home/neville/cfbPlayoffPredictor/data/current/CurrentCalculatedRatings.txt";
my $fbsTeams = "/home/neville/cfbPlayoffPredictor/data/2015/fbsTeamNames.txt";



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
open (NCFSCORESFILE, "<$ncfScoresFile") or die "$! error trying to open";     
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




#my @output;

#print all the rating biases to a file
open (AGAMATRIXRATINGSFILE, ">$agaMatrixRatingsFile") or die "$! error trying to overwrite";
for (my $i=1; $i<$#teams+2; $i++ ) {    
print AGAMATRIXRATINGSFILE "$team{$i} agaRating= $agaRating[$i]\n";
#$output[$i] = "$agaRating[$i]:$team{$i}";
}
print "output written to $agaMatrixRatingsFile\n";
close AGAMATRIXRATINGSFILE;












#print out sorted ratings for home page and analyze schedule use
open (CURRENTCALCULATEDRATINGSFILE, ">$CurrentCalculatedRatingsFile") or die "$! error trying to overwrite";
my @ratings;
my @sortedRatings;

for (my $i=1; $i<$#teams+2; $i++ ) {    
push @ratings, "$agaRating[$i]:$team{$i}:$agaRating[$i]: record is $teamWins[$i] and $teamLosses[$i]"
}
@sortedRatings = reverse sort @ratings;
for (my $i=0; $i<$#teams+1; $i++ ) {    
$sortedRatings[$i] =~ /(.+?):(.+?):(.+?):(.+)/;   #need to greedily take the last part (no : delimiter at the end)
$sortedRatings[$i] = "$2:$3:$4";   #get rid of the rating in the front (needed earlier to sort) 
#print  "$sortedRatings[$i]\n";
print CURRENTCALCULATEDRATINGSFILE "$sortedRatings[$i]\n";
}
print "output written to $CurrentCalculatedRatingsFile\n";
close CURRENTCALCULATEDRATINGSFILE;








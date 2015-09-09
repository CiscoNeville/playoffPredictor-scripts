#!/usr/bin/perl
##############
#
# Build the current FBS results and future schedule files by scraping ESPN ncf scoreboard for a whole season
#
# Input files: none
#
# Output files:
#   ncfScoresFile - contains results of games played up to that point in the season
#   ncfScheduleFile - contains all upcoming scheduled games for the rest of the season
# 
##############

use strict;
use warnings;
use HTML::Parser;
use Data::Dumper;
use WWW::Mechanize;
use HTML::TokeParser;
use File::Copy;
use JSON;
use Data::Dumper;
use feature qw/ say /;

my $ncfScoresFile = "/home/neville/cfbPlayoffPredictor/data/current/ncfScoresFile.txt";
my $ncfScheduleFile = "/home/neville/cfbPlayoffPredictor/data/current/ncfScheduleFile.txt";
my $seasonYear = "2015";

my $confId;    #80 is all FBS
my $seasonType;   #2 is regular season 3 is bowls
my $weekNumber;    # goes from 1 to 16
my $gameStatus;
my $aTeamName;
my $aTotal;
my $hTeamName;
my $hTotal;
my %team1;
my %team2;
my $score1;
my $score2;


#Clear out any previous scorefiles:
open (NCFSCORESFILE, ">$ncfScoresFile") or die "$! error trying to overwrite";
print NCFSCORESFILE ""; 
close NCFSCORESFILE;

open (NCFSCHEDULEFILE, ">$ncfScheduleFile") or die "$! error trying to overwrite";
print NCFSCHEDULEFILE ""; 
close NCFSCHEDULEFILE;





#subroutine scrapeScores
sub scrapeScoresESPN {
my (@ops) = @_;
$confId = $ops[0];
$seasonYear = $ops[1];
$seasonType = $ops[2];
$weekNumber = $ops[3];


my $baseurl ="http://scores.espn.go.com/college-football/scoreboard/_/group/$confId/year/$seasonYear/seasonType/$seasonType/week/$weekNumber";
# new url syntax is restful -- http://scores.espn.go.com/college-football/scoreboard/_/group/80/year/2015/seasontype/2/week/1
# but the json response is buried deep inside and have to use regex to pull it out

my $browser = WWW::Mechanize->new();
my $html;
$browser->get($baseurl);
die $browser->response->status_line unless $browser->success;
$html = $browser->content;

$html =~ /(.+)<\/script><script>window.espn.scoreboardData 	= (.+?)\;window.espn.scoreboardSettings/sg;
my $json = $2;  #this should be all the espn json

#open (SCORES1, ">/tmp/scores.json") or die "$! error trying to overwrite";
#print SCORES1 "$json\n";

my $data = decode_json $json;
 
#print Dumper $data;
#my $dumpedData = Dumper $data;
#open (SCORES2, ">/tmp/scores2.txt") or die "$! error trying to overwrite";
#print SCORES2 "$dumpedData";

my @events = @{ $data -> {"events"}    };

for (my $i=0; $i<100 ; $i++)  {                                         #I should really do a foreach here instead...
if (defined ( @{$events[$i] ->  {"competitions"} }   )) {               #again, i shuld use foreach...
my @competitions = @{ $events[$i] ->  {"competitions"}      };

#foreach my @competitions  (@events -> {"competitions"})  {


my @competitors = @{ $competitions[0] -> {"competitors"}          };   
%team1 = %{ $competitors[0] -> {"team"}       };
%team2 = %{ $competitors[1] -> {"team"}       };

#if present, change the accent in San José State to just San Jose State
$team1{location} =~ s/Jos. State/Jose State/g;
$team2{location} =~ s/Jos. State/Jose State/g;





if (defined ($competitors[0] -> {"winner"})) { #the winner will be undefined for a not final game. 
$score1 = $competitors[0] -> {"score"}    ;  
$score2 = $competitors[1] -> {"score"}    ;

#I could actually pull final from competitions->status->type->detail, but if a winner is declared then if must be final.

print "week $weekNumber: Final : $team1{location} $score1 - $team2{location} $score2\n";
print NCFSCORESFILE "week $weekNumber: Final : $team1{location} $score1 - $team2{location} $score2\n";   #convert to 1-0 format in cm.pl. need it in this format now cause like to see final scores in analyze schedule



} else {  #game still to be played out

print "week $weekNumber: Scheduled : $team1{location} vs $team2{location}\n";
print NCFSCHEDULEFILE "week $weekNumber:$team1{location} - $team2{location}\n"; 
 
}
}
}







#if (  ($aTeamName[$i] ~~ [values %team])  &&  ($hTeamName[$i] ~~ [values %team])  )  {   #use this construct (with a matched }) in order to only do FBS vs FBS games.  Currently I do not want that
 



}



















open (NCFSCORESFILE, ">>$ncfScoresFile") or die "$! error trying to append";
open (NCFSCHEDULEFILE, ">>$ncfScheduleFile") or die "$! error trying to append";







#get regular season games
for (my $k = 1; $k<=15; $k++ ) {     #15 is the final regular season week
print "getting $seasonYear week $k\n";
scrapeScoresESPN (80, $seasonYear, 2, $k);
}


#get bowl games
print "getting $seasonYear bowl games (week 17)\n";
scrapeScoresESPN (80,$seasonYear,3,17);

print "All done.\n";




close NCFSCORESFILE;
close NCFSCHEDULEFILE;
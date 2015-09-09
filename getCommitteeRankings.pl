#!/usr/bin/perl
##############
#
# get the current committee rankings into the rankings file
# Run this on Tuesdays after the committee rankings are announced
# First week this is valid for is week 9
#
# ***note that collegefootballplayoff.com is one week ahead -- that is their week 10 is my week 9***
# 
# Usage:getCommitteeRankings.pl year week
#
# Input files: none
#
# Output files:
#   currentPlayoffCommitteeRankings - playoff committee rankings for the previous week
#
#
# the committee ratings for each team are obtained my mapping the committee rankings to a committee rating using ??  
# ideas are a "normal distribution" where all teams would be assigned 1-129 at beginning of season, simulate out and see AgaMatrix ratings on a per week basis  <-- to try
# Use last 6 years of data from colley matrix per week <- what's done now
#
##############





use strict;
use HTML::Parser;
use Data::Dumper;
use WWW::Mechanize;
use HTML::TokeParser;

 
 
if ($#ARGV != 1) {     #should be 2 aruments on CLI
print "Usgae: getCommitteeRankings.pl year week\n";
print "example- getCommitteeRankings.pl 2014 9\n";
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

my $nextWeek = $week +1;  #IMPORTANT--- If I want to see how the committee ranked teams at the end of week 11s games, I have to pull week 12 of data -- their calendar is one week ahead and goes weeks 10-16.   Mine goes weeks 9-15

#pull from ESPN CFP committee rankings
my $baseurl = "http://espn.go.com/college-football/playoffPicture";    #use this line alone for the current poll
$baseurl = $baseurl."/_/week/$nextWeek/year/$year";  #append here for historical data

my $browser = WWW::Mechanize->new();
my $html;
$browser->get($baseurl);
die $browser->response->status_line unless $browser->success;
$html = $browser->content;

#open (RANKINGS, ">/root/cfbPlayoffPredictor/rankings1.html") or die "$! error trying to overwrite";
#print RANKINGS "$html\n";


my @rankingsArray;
my @rankingNum;
my @rankingName;


#@rankingsArray = ($html =~ m/<td class="team-rank">(\d+)<\/td><td .+?><ul .+?><li .+?><div .+?><\/div><a .+?>(.+?)<\/a>/g);  #way I did it in 2014
@rankingsArray = ($html =~ m/<tr class=".+?"><td><a href=".+?">(.+?)<\/a>/g);



for (my $i = 0; $i<$#rankingsArray+1; $i++ ) {  
$rankingName[$i] = $rankingsArray[$i];
#print "$rankingNum[$i] : $rankingName[$i] \n"; 
}

#clean up some bad name tagging on thier part. hopefully this will not be needed come week 10 2015, but it seems to be needed on aug 2015 for 2014 data
for (my $i = 0; $i<$#rankingsArray+1; $i++ ) {  
if ($rankingName[$i] eq "Miss St")  {$rankingName[$i] = "Mississippi State"}
if ($rankingName[$i] eq "FSU")  {$rankingName[$i] = "Florida State"}
if ($rankingName[$i] eq "OSU")  {$rankingName[$i] = "Ohio State"}
if ($rankingName[$i] eq "ECU")  {$rankingName[$i] = "East Carolina"}

}






 
my $committeeRankings = "/home/neville/cfbPlayoffPredictor/data/$year/week$week/Week$week"."PlayoffCommitteeRankings.txt";



#Write the rankings -- need to map committe rankings to a rating

#the measured ratings are past 6 year historical colley ratings for that rank number at that week
#my @week9MeasuredRatings = qw ( 0.973 0.933 0.918 0.908 0.893 0.867 0.851 0.839 0.833 0.824 0.819 0.805 0.797 0.788 0.781 0.776 0.767 0.761 0.754 0.749 0.740 0.731 0.727 0.719 0.715   );
#my @week10MeasuredRatings = qw ( 0.987 0.950 0.920 0.902 0.894 0.878 0.854 0.843 0.828 0.818 0.813 0.808 0.802 0.794 0.789 0.781 0.770 0.765 0.757 0.746 0.733 0.726 0.723 0.716 0.707   );
#my @week11MeasuredRatings = qw ( 0.971 0.944 0.927 0.910 0.890 0.872 0.857 0.846 0.841 0.831 0.817 0.811 0.804 0.792 0.782 0.774 0.764 0.758 0.753 0.744 0.741 0.733 0.726 0.720 0.714   );
#my @week12MeasuredRatings = qw ( 0.963 0.939 0.910 0.896 0.890 0.872 0.864 0.856 0.846 0.838 0.826 0.814 0.807 0.803 0.794 0.783 0.776 0.765 0.756 0.752 0.747 0.738 0.732 0.720 0.715   );
#my @week13MeasuredRatings = qw (  0.972 0.940 0.921 0.900 0.891 0.879 0.865 0.848 0.842 0.838 0.831 0.825 0.818 0.803 0.798 0.784 0.777 0.771 0.763 0.754 0.748 0.728 0.721 0.710 0.703  );
#my @week14MeasuredRatings = qw (  0.988 0.954 0.922 0.903 0.892 0.877 0.868 0.857 0.845 0.840 0.834 0.825 0.814 0.799 0.795 0.789 0.776 0.765 0.753 0.748 0.735 0.726 0.719 0.709 0.706  );
#my @week15MeasuredRatings = qw ( 1.000 0.965 0.932 0.906 0.891 0.873 0.866 0.859 0.853 0.847 0.836 0.830 0.814 0.800 0.784 0.776 0.767 0.762 0.752 0.746 0.738 0.727 0.717 0.712 0.707    );


#The below numbers are Neville's fiddling :(
my @week9MeasuredRatings = qw  ( 0.973 0.933 0.915 0.905 0.898 0.872 0.851 0.839 0.833 0.824 0.819 0.805 0.797 0.788 0.781 0.776 0.767 0.761 0.754 0.749 0.740 0.731 0.727 0.719 0.715   );
my @week10MeasuredRatings = qw ( 0.987 0.950 0.915 0.900 0.899 0.883 0.854 0.843 0.828 0.818 0.813 0.808 0.802 0.794 0.789 0.781 0.770 0.765 0.757 0.746 0.733 0.726 0.723 0.716 0.707   );
my @week11MeasuredRatings = qw ( 0.971 0.944 0.925 0.905 0.895 0.877 0.857 0.846 0.841 0.831 0.817 0.811 0.804 0.792 0.782 0.774 0.764 0.758 0.753 0.744 0.741 0.733 0.726 0.720 0.714   );
my @week12MeasuredRatings = qw ( 0.970 0.939 0.905 0.890 0.890 0.872 0.864 0.856 0.846 0.838 0.826 0.814 0.807 0.803 0.794 0.783 0.776 0.765 0.756 0.752 0.747 0.738 0.732 0.720 0.715   );
my @week13MeasuredRatings = qw ( 0.980 0.940 0.915 0.895 0.891 0.879 0.865 0.848 0.842 0.838 0.831 0.825 0.818 0.803 0.798 0.784 0.777 0.771 0.763 0.754 0.748 0.728 0.721 0.710 0.703  );
my @week14MeasuredRatings = qw ( 0.990 0.954 0.920 0.900 0.892 0.877 0.868 0.857 0.845 0.840 0.834 0.825 0.814 0.799 0.795 0.789 0.776 0.765 0.753 0.748 0.735 0.726 0.719 0.709 0.706  );
my @week15MeasuredRatings = qw ( 1.000 0.965 0.930 0.900 0.891 0.873 0.866 0.859 0.853 0.847 0.836 0.830 0.814 0.800 0.784 0.776 0.767 0.762 0.752 0.746 0.738 0.727 0.717 0.712 0.707    );











open (CFPRANKINGS, ">$committeeRankings") or die "$! error trying to overwrite";


if ($week eq 9) {
for (my $i = 1 ; $i <=25 ; $i++) {
print CFPRANKINGS "$i:$rankingName[$i-1]:$week9MeasuredRatings[$i-1]\n";
}
}

if ($week eq 10) {
for (my $i = 1 ; $i <=25 ; $i++) {
print CFPRANKINGS "$i:$rankingName[$i-1]:$week10MeasuredRatings[$i-1]\n";
}
}

if ($week eq 11) {
for (my $i = 1 ; $i <=25 ; $i++) {
print CFPRANKINGS "$i:$rankingName[$i-1]:$week11MeasuredRatings[$i-1]\n";
}
}

if ($week eq 12) {
for (my $i = 1 ; $i <=25 ; $i++) {
print CFPRANKINGS "$i:$rankingName[$i-1]:$week12MeasuredRatings[$i-1]\n";
}
}

if ($week eq 13) {
for (my $i = 1 ; $i <=25 ; $i++) {
print CFPRANKINGS "$i:$rankingName[$i-1]:$week13MeasuredRatings[$i-1]\n";
}
}

if ($week eq 14) {
for (my $i = 1 ; $i <=25 ; $i++) {
print CFPRANKINGS "$i:$rankingName[$i-1]:$week14MeasuredRatings[$i-1]\n";
}
}

if ($week eq 15) {
for (my $i = 1 ; $i <=25 ; $i++) {
print CFPRANKINGS "$i:$rankingName[$i-1]:$week15MeasuredRatings[$i-1]\n";
}
}







#print CFPRANKINGS "1:$rankingName[0]:.970\n";
#print CFPRANKINGS "2:$rankingName[1]:.920\n";
#print CFPRANKINGS "3:$rankingName[2]:.890\n";
#print CFPRANKINGS "4:$rankingName[3]:.870\n";
#print CFPRANKINGS "5:$rankingName[4]:.850\n";
#print CFPRANKINGS "6:$rankingName[5]:.830\n";
#print CFPRANKINGS "7:$rankingName[6]:.810\n";
#print CFPRANKINGS "8:$rankingName[7]:.795\n";
#print CFPRANKINGS "9:$rankingName[8]:.790\n";
#print CFPRANKINGS "10:$rankingName[9]:.785\n";
#print CFPRANKINGS "11:$rankingName[10]:.780\n";
#print CFPRANKINGS "12:$rankingName[11]:.775\n";
#print CFPRANKINGS "13:$rankingName[12]:.770\n";
#print CFPRANKINGS "14:$rankingName[13]:.760\n";
#print CFPRANKINGS "15:$rankingName[14]:.750\n";
#print CFPRANKINGS "16:$rankingName[15]:.745\n";
#print CFPRANKINGS "17:$rankingName[16]:.740\n";
#print CFPRANKINGS "18:$rankingName[17]:.735\n";
#print CFPRANKINGS "19:$rankingName[18]:.730\n";
#print CFPRANKINGS "20:$rankingName[19]:.725\n";
#print CFPRANKINGS "21:$rankingName[20]:.720\n";
#print CFPRANKINGS "22:$rankingName[21]:.715\n";
#print CFPRANKINGS "23:$rankingName[22]:.710\n";
#print CFPRANKINGS "24:$rankingName[23]:.705\n";
#print CFPRANKINGS "25:$rankingName[24]:.700\n";


close CFPRANKINGS;



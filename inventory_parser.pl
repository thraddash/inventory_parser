#!/usr/bin/perl

use warnings;
use strict;
use Net::Telnet;

&main;

sub main{

#	&login;		#tmp uncommented
	&parse;		
}

sub login{

#read list of storage chars and passwords
#format:
#comments are lines starting with # (they are ignored)
#one char name/password per line like this:
#char_name:password


	open(ROSTER,"/secret/inventory_parser_secret.pl") or die "cant open secret file";

	my %roster;
	my $mud_ip="isengard.nazgul.com";
	my $mud_port=4040;

	while(defined(my $line=<ROSTER>)){
		if($line =~ /^#/){
			next;
		}else{
			chomp($line);
			my ($name,$password)=split(/:/,$line);
			$roster{$name}="$password";
		}
	}

	foreach my $name (keys %roster){

		my $t = new Net::Telnet (Timeout => 10, Port => $mud_port,);

		$t->open($mud_ip);

#this is what the login looks like
#Please enter name:
#Please enter password:
#(23 H 2 M):

		$t->waitfor('/Please enter name:/');
		$t->print($name);


		$t->waitfor('/Please enter password:/');
		$t->print($roster{$name});

		$t->waitfor('/\(\d+ H \d+ M\):/');
		$t->print("rem all");
		$t->waitfor('/\(\d+ H \d+ M\):/');
		$t->print("i");
		my @inventory = $t->waitfor('/\(\d+ H \d+ M\):/');
		my $inv_ref=\@inventory;
		&parse($inv_ref);
	}
}

sub parse{
#You have: an aquamarine potion, a blue bubbly potion, two dark flasks, some
#  eye of newt, a golden dagger, three green potions, a hammer of
#  thunderbolts, two hazy potions, an ivory coffer, a verdant green scroll,
#  nine wand of the efreetis, three werewolf sire skulls.  Inventory weight
#  is 248 lbs.
#(120 H 3 M):

#	my($inv_ref)=@_;		#temporary uncomment 

#	my @inventory = @{$inv_ref};	#tmp uncomment

#	open(OUTPUT,">output.txt"); 	#tmp uncomment 
#	print OUTPUT "@inventory";	#tmp uncomment
	open(INPUT,"output.txt");


#reconstruct inventory lines
	my $result="";
	my @inventory=<INPUT>;
	foreach my $line (@inventory){
		$line=~s/\(\d+ H \d+ M\)://g;
		$line=~s/\n|\r//g;
		$result=$result.$line;
	}

	$result =~ /You have: (.*) Inventory weight is (\d+) lbs./;
	print "items: $1\nweight: $2\n";
	print "##############################\n";
	&parse_items($1);
	
#sample output
#items: two Ahrot's magic strings (+1), two Medallion of Durins, an  aquamarine potion (M), a blue bubbly potion (M), a crown of foam, two dark  flasks (M), two sets of eye of newt (M), two galvorn rings, a galvorn  shield, a giant hammer of thunder (+3), a grey scroll (M), two hazy  potions (M), an imeril leggings (+1), some imeril sleeves (+1), an ivory  coffer, a knapsack, a mask of distortion, some mithril lamella armor, some  obsidian gauntlets, a silver hoop, two sundorian tassles, some volcanic  boots (+1), four wand of the efreetis (M). 
#weight: 182



}

sub parse_items{
	my %keywords;
	
	$keywords{'some'}=1;
	$keywords{'a'}=1;	
	$keywords{'an'}=1;	
	$keywords{'the'}=1;	

	my($parse_items)=@_;

	$parse_items=~s/,\s+/,/g;
	$parse_items=~s/\s+/ /g;
	$parse_items=~s/\.//g;
	$parse_items=~s/\s+$//g;
	my @inventory=split(/,/,$parse_items);

	foreach my $item(@inventory){
		foreach my $k(keys %keywords){
			if($item=~/^$k\s(.*)/){
				print "$item ==> [$keywords{$k} $1]\n";
			}
		}
	}
}



#!/usr/bin/perl
# Copyright (c) 2017 Trinity College, Dublin
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

use warnings;
use strict;
use utf8;

use URI;
use Web::Scraper;
use Encode;
use Data::Dumper;

my $uribase = 'http://www.fuaimeanna.ie/en/Recordings.aspx';

open(SOUNDSGD, '>>', 'fuaimeanna-sounds-gd.txt');
open(SOUNDSCR, '>>', 'fuaimeanna-sounds-cr.txt');
open(SOUNDSCD, '>>', 'fuaimeanna-sounds-cd.txt');
open(GD, '>>', 'fuaimeanna-pron-gd.txt');
open(CR, '>>', 'fuaimeanna-pron-cr.txt');
open(CD, '>>', 'fuaimeanna-pron-cd.txt');

binmode STDOUT, ":utf8";
binmode GD, ":utf8";
binmode CR, ":utf8";
binmode CD, ":utf8";
binmode SOUNDSGD, ":utf8";
binmode SOUNDSCR, ":utf8";
binmode SOUNDSCD, ":utf8";

my @outfiles = (*GD, *CR, *CD);
my @outsound = (*SOUNDSGD, *SOUNDSCR, *SOUNDSCD);

my $uri;
if($ARGV[0] && $ARGV[0] ne '') {
	$uri = URI->new($ARGV[0]);
} else {
	$uri = URI->new($uribase);
}

my $prons = scraper {
	process '//div[@class="pager"]/a[@title="forward"]', 'next' => '@href';
	process '//div[@class="friotal"]', 'items[]' => scraper {
		process '//span[@class="column-left"]/span[@class="ortho"]', 'orth' => 'TEXT';
		process '//span[@class="taifead"]', 'items[]' => scraper {
			process '//span[@class="player"]/object/param[@name="movie"]', 'sound' => '@value';
			process '//span[@class="phonological"]/a[@class="phoneme"]', 'phones[]' => 'TEXT';
		};
	};
};

my $r = $prons->scrape($uri);

my $cancontinue = 1;

while($cancontinue) {
	for my $item (@{$r->{items}}) {
		my $orth = $item->{'orth'};
		$orth =~ s/^<//;
		$orth =~ s/>$//;

		my $curfile;
		my $curaud;
		my @dialects = @{$item->{'items'}};

		for my $i (0..2) {
			$curfile = $outfiles[$i];
			$curaud = $outsound[$i];
			my $thisitem = $dialects[$i];
			my $sound = $thisitem->{'sound'};
			
			$sound =~ s!/musicplayer.swf\?\&song_url=!http://www.fuaimeanna.ie!;

			my $cur = join(" ", @{$thisitem->{'phones'}});

			print $curfile "$orth\t$cur\n";
			print $curaud "$orth\t$sound\n";

		}
	}

	if(exists $r->{'next'}) {
		$r = $prons->scrape($r->{'next'});
	} else {
		$cancontinue = 0;
	}
}


#!/usr/bin/env perl
use strict;
use warnings;
use Getopt::Long qw(:config bundling no_ignore_case no_auto_abbrev require_order);
use Search::Engine;
use XML::LibXML;

my $DEFAULT_SELECTOR = "#make-everything-ok-button";
sub usage {
    print "$0 [--etalon_selector=xpath <etalon_page> <search_page> [search_page..]\n"
          . "\t--etalon_selector - custom selector for search element in etalon_page, default $DEFAULT_SELECTOR\n"
          . "\t<etalon_page> - path to html page with etalon of search element\n"
          . "\t<seacrh_page> - path to html page for searching element\n";
}

sub main  {
    my $etalon_selector = $DEFAULT_SELECTOR;
    my $help;
    GetOptions("etalon_selector|s" => \$etalon_selector,
               "help" => \$help);
    if ($help) {
        usage();
    }
    my ($etalon_page, @search_pages) = @ARGV;
    if (!$etalon_page || !@search_pages) {
        select STDERR;
        print "etalon page or diff page is not specified\n";
        usage();
    }
    my $engine = Search::Engine->new(
        selector => $etalon_selector,
        file => $etalon_page,
    );
    for my $search_page (@search_pages) {
        my $xml = XML::LibXML->load_xml(location => $search_page);
        my $result = $engine->match($xml);
        if ($result) {
            printf("Page %s, best button canidate %s with score %d is \n%s\n", $search_page, $result->element->nodePath, $result->score, $result->element);
        } else {
            printf("Page %s, no appropriate button candidate\n", $search_page);
        }
    }
}
main();

package Search::Engine;

use strict;
use warnings;
use Params::Validate qw(:all);
use XML::LibXML;
use XML::LibXML::QuerySelector;
use Search::Strategy;

sub _read_criteria {
    my ($selector, $file) = @_;
    my $xml_file = XML::LibXML->load_xml(location => $file);
    my $etalon_element = $xml_file->querySelector($selector);
    if (!$etalon_element) {
        die "etalon element not found if file $file with selector $selector";
    }
    my @strategy_names = qw/class title href text/;
    my @criteria;
    for my $strategy_name (@strategy_names) {
        my $strategy_class = "Search::Strategy::". ucfirst($strategy_name);
        my $value = $strategy_class->extract_value($etalon_element);
        if (!$value) {
            warn "Value is empty for $strategy_name in etalon element. Skipping $strategy_name..\n";
        }
        push @criteria, $strategy_class->new($value);
    }
    if (!@criteria) {
        die "can't fetch any data from etalon_element";
    }
    return \@criteria;
}

sub match {
    my ($self, $xml_file) = @_;
    my @strategies = @{$self->{_sc}};

    my @candidates;
    for my $strategy (@strategies) {
        if ($strategy->skip_match) {
            next;
        }
        push @candidates, $strategy->match($xml_file);
    }
    for my $candidate (@candidates) {
        for my $strategy (@strategies) {
            $strategy->evaluate($candidate); 
        }
    }
    my ($best_candidate) = sort { $b->score <=> $a->score } @candidates;
    return $best_candidate;
}

sub new {
    my $class = shift;
    my %params = validate(
        @_, {
            selector => { type => SCALAR },
            file     => { type => SCALAR },
        }
    );
    my $search_criteria = _read_criteria(@params{qw/selector file/});
    my $self = {
        _sc => $search_criteria,
    };
    return bless $self, $class;
}


1;

#!/usr/bin/perl


use strict;
use warnings;

use Search::Strategy;
use Search::Result;
use Test::More;
use parent 'Test::Class';
use XML::LibXML;

sub startup : Test(startup) {
    my $self = shift;
    $self->{good_file} = XML::LibXML->load_xml(location => 'data/sample-0-origin.html');
    $self->{file1} = XML::LibXML->load_xml(location => 'data/sample-1-evil-gemini.html');
    $self->{file2} = XML::LibXML->load_xml(location => 'data/sample-2-container-and-clone.html');
    $self->{file3} = XML::LibXML->load_xml(location => 'data/sample-3-the-escape.html');
    $self->{file4} = XML::LibXML->load_xml(location => 'data/sample-4-the-mash.html');
    $self->{etalon} = Search::Result->new($self->{good_file}->querySelector("#make-everything-ok-button"));
}

sub setup : Test(setup) {
    my $self = shift;
    $self->{etalon}->score(0);
}

sub test_strategy {
    my $self = shift;
    my $class_str = shift;
    my ($result) = $class_str->match($self->{good_file});
    ok($result);
    $class_str->evaluate($result);
    is($result->score, 1);
    $class_str->evaluate($self->{etalon});
    is($self->{etalon}->score, 1);

}
sub class_strategy : Tests {
    my $self = shift;
    $self->test_strategy(Search::Strategy::Class->new('btn btn-success'));
}

sub title_stategy :Tests {
    my $self = shift;
    $self->test_strategy(Search::Strategy::Title->new('Make-Button'));
}

sub href_stategy :Tests {
    my $self = shift;
    $self->test_strategy(Search::Strategy::Href->new('#ok'));
}

__PACKAGE__->runtests;

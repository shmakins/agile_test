package Search::Strategy;

use strict;
use warnings;
use Search::Result;
use XML::LibXML::QuerySelector;
use parent 'Class::Accessor';
__PACKAGE__->mk_accessors(qw/match_value/);

sub new {
    my ($class, $match_value) = @_;
    bless {match_value => $match_value }, $class;
}

sub skip_match {
    return 0;
}

sub match {
    my $class = ref $_[0] || $_[0];
    die "$class is abstract";
}

sub evaluate {
    my $class = ref $_[0] || $_[0];
    die "$class is abstract";
}

sub extract_value {
    my ($class, $element) = @_;
    my $value = $element->getAttribute($class->get_param_name);
    return $value;
}

package Search::Strategy::Class;

use strict;
use warnings;

push @Search::Strategy::Class::ISA, 'Search::Strategy';

sub get_param_name {
    return 'class';
}

sub _parse_class_value {
    my ($value) = @_;
    my @match_values = ($value, sort { length $b <=> length $a} split(/\s+/, $value));
    return @match_values;
}

sub match {
    my $self = shift; 
    my $xml = shift;
    my $class = $self->match_value;
    my (@search_classes) = _parse_class_value($class);
    my @elements;
    for $class (@search_classes) {
        my @_elements = $xml->querySelectorAll(qq{a[class='$class']});
        if (@_elements) {
            @elements = @_elements;        
            last;
        }
    }
    return map { Search::Result->new($_) } @elements;
}

sub evaluate {
    my ($self, $result) = @_;
    my $etalon_class = $self->match_value;
    my $got_class = $self->extract_value($result->element);
    my $score = $etalon_class =~ /\b$got_class\b/ ? 1 : 0;
    $result->score($score + $result->score);
}

package Search::Strategy::CompareAttr;

use strict;
use warnings;

push @Search::Strategy::CompareAttr::ISA, 'Search::Strategy';

sub get_param_name { die "Abstract class" }

sub match {
    my $self = shift;
    my $xml = shift;
    my $attr_name = $self->get_param_name;
    my $value = $self->match_value;
    my @elements = $xml->querySelectorAll(qq{a[$attr_name='$value']});
    return map { Search::Result->new($_) } @elements;
}

sub evaluate {
    my ($self, $result) = @_;
    my $etalon_title = $self->match_value;
    my $got_title = $self->extract_value($result->element) // '';
    my $score = $etalon_title eq $got_title ? 1 : 0;
    $result->score($score + $result->score);
}

package Search::Strategy::Title;

use strict;
use warnings;

push @Search::Strategy::Title::ISA, 'Search::Strategy::CompareAttr';

sub get_param_name { return 'title' }

package Search::Strategy::Href;

use strict;
use warnings;

push @Search::Strategy::Href::ISA, 'Search::Strategy::CompareAttr';

sub get_param_name { return 'href' };

package Search::Strategy::Text;
use strict;
use warnings;

push @Search::Strategy::Text::ISA, 'Search::Strategy';

sub get_param_name { return 'text' };

sub skip_match {
    return 1;
}

sub evaluate {
    my ($self, $result) = @_;
    my $etalon_value = $self->match_value;
    my $got_value = $self->extract_value($result->element);
    my $score = $etalon_value eq $got_value ? 1 : 0;
    $result->score($score + $result->score);
}

sub extract_value {
    my ($class, $element) = @_;
    my $text_node = $element->firstChild();
    if ($text_node && $text_node->isa('XML::LibXML::Text') && length($text_node->data)) {
        my $text = $text_node->data;
        $text =~ s/^\s+|\s+$//g; # trim spaces
        return $text;
    }
    return '';
}

1;

package Search::Result;

use strict;
use warnings;
use parent 'Class::Accessor';
__PACKAGE__->mk_accessors(qw/element score/);

sub new {
    my $class = shift;
    my $el = shift;
    die "undefined el unless $el" unless $el;
    return bless{ element => $el, score => 0}, $class;
}

1;

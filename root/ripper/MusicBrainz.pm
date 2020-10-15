package WebService::MusicBrainz;

use strict;

our $VERSION = '0.15';

=head1 NAME

WebService::MusicBrainz

=head1 SYNOPSIS

    use WebService::MusicBrainz;

    my $artist_ws = WebService::MusicBrainz->new_artist();
    my $track_ws = WebService::MusicBrainz->new_track();
    my $release_ws = WebService::MusicBrainz->new_release();
    my $label_ws = WebService::MusicBrainz->new_label();

=head1 DESCRIPTION

This module will act as a factory using static methods to return specific web service objects;

=head1 METHODS

=head2 new_artist()

Return new instance of WebService::MusicBrainz::Artist object.

=cut

sub new_artist {
   my $class = shift;

   require WebService::MusicBrainz::Artist;

   return WebService::MusicBrainz::Artist->new();
}

=head2 new_track

Return new instance of WebService::MusicBrainz::Track object.

=cut 

sub new_track {
   my $class = shift;

   require WebService::MusicBrainz::Track;

   return WebService::MusicBrainz::Track->new();
}

=head2 new_release

Return new instance of WebService::MusicBrainz::Release object.

=cut 

sub new_release {
   my $class = shift;

   require WebService::MusicBrainz::Release;

   return WebService::MusicBrainz::Release->new();
}

=head2 new_release

Return new instance of WebService::MusicBrainz::Label object.

=cut 

sub new_label {
   my $class = shift;

   require WebService::MusicBrainz::Label;

   return WebService::MusicBrainz::Label->new();
}

=head1 AUTHOR

=over 4

=item Bob Faist <bob.faist@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2006-2007 by Bob Faist

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

http://wiki.musicbrainz.org/XMLWebService

=cut

1;

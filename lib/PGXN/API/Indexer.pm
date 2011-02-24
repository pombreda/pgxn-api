package PGXN::API::Indexer v0.1.0;

use 5.12.0;
use utf8;
use Moose;
use PGXN::API;
use XML::LibXML;
use File::Spec::Functions qw(catfile catdir);
use File::Path qw(make_path);
use namespace::autoclean;

(my $def_doc_root = __FILE__) =~ s{(?:blib/)?lib/PGXN/API/Indexer[.]pm$}{www};

has doc_root => (is => 'ro', isa => 'Str', lazy => 1, default => sub {
     PGXN::API->instance->config->{doc_root} || do {
         my $file = quotemeta catfile qw(lib PGXN API Indexer.pm);
         my $blib = quotemeta catfile 'blib', '';
         (my $dir = __FILE__) =~ s{(?:$blib)?$file$}{www};
         $dir;
     };
});

sub add_distribution {
    my ($self, $params) = @_;

    my $src_dir = $params->{src_dir};
    my $meta    = $params->{meta};
    my $idx_dir = catdir +PGXN::API->instance->config->{index_path};

    $self->merge_metadata($meta);

    return $self;
}

sub merge_distmeta {
    my ($self, $meta) = @_;

    # Merge the list of versions into the meta file.
    my $by_dist_file = $self->file_for('by-dist' => $meta);
    my $by_dist = PGXN::API->instance->read_json_from($by_dist_file);
    $meta->{releases} = $by_dist->{releases};

    # Write the merge metadata to the file.
    my $fn = $self->file_for(meta => $meta);
    open my $fh, '>:utf8', $fn or die "Cannot open $fn: $!\n";
    print $fh JSON->new->pretty->encode($meta);
    close $fh or die "Cannot close $fn: $!\n";
    return $self;
}

sub file_for {
    my ($self, $name, $meta) = @_;
    my $dist_uri = PGXN::API->instance->uri_templates->{$name}->process(
        dist    => $meta->{name},
        version => $meta->{version},
    );

    return catfile +PGXN::API->instance->config->{mirror_root},
        $dist_uri->path_segments;
}

1;

__END__

=head1 Name

PGXN::API::Index - PGXN API distribution indexer

=head1 Synopsis

  use PGXN::API::Indexer;
  PGXN::API::Indexer->add_distribution({
      meta    => $meta,
      src_dir => File::Spec->catdir(
          $self->source_dir, "$meta->{name}-$meta->{version}"
      ),
  });

=head1 Description

More to come.

=head1 Author

David E. Wheeler <david.wheeler@pgexperts.com>

=head1 Copyright and License

Copyright (c) 2011 David E. Wheeler.

This module is free software; you can redistribute it and/or modify it under
the L<PostgreSQL License|http://www.opensource.org/licenses/postgresql>.

Permission to use, copy, modify, and distribute this software and its
documentation for any purpose, without fee, and without a written agreement is
hereby granted, provided that the above copyright notice and this paragraph
and the following two paragraphs appear in all copies.

In no event shall David E. Wheeler be liable to any party for direct,
indirect, special, incidental, or consequential damages, including lost
profits, arising out of the use of this software and its documentation, even
if David E. Wheeler has been advised of the possibility of such damage.

David E. Wheeler specifically disclaims any warranties, including, but not
limited to, the implied warranties of merchantability and fitness for a
particular purpose. The software provided hereunder is on an "as is" basis,
and David E. Wheeler has no obligations to provide maintenance, support,
updates, enhancements, or modifications.

=cut

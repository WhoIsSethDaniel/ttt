package DBIx::Class::OnChanges;

# This is based on DBIx::Class::Helper::Row::OnColumnChange.
# Unfortunately that module only overrides update.

our $VERSION = '1.0';

use strict;
use warnings;
use feature ':5.22';

use parent qw( DBIx::Class::Core );

__PACKAGE__->load_components( qw( Helper::Row::StorageValues ) );

# override from Row::StorageValues
sub _has_storage_value { return 1 }

sub _get_all_changing_cols {
  my( $self, $cols ) = @_;

  my %dirty = ( $self->get_dirty_columns, %{$cols||{}} );
  return keys %dirty;
}

sub update {
  my $self = shift;

  my @changing = $self->_get_all_changing_cols(@_);

  $self->before_change( \@changing, @_ ) if $self->can( 'before_change' );
  $self->before_update( \@changing, @_ ) if $self->can( 'before_update' );

  # update columns that are changing since the above methods
  #   may have updated new columns
  @changing = $self->_get_all_changing_cols;

  my %data = $self->get_columns;
  my %old = map { $_ => $self->get_storage_value( $_ ) } keys %data;

  my $ret = $self->maybe::next::method;

  $self->after_update( \@changing, @_ ) if $self->can( 'after_update' );
  $self->after_change( \@changing, @_ ) if $self->can( 'after_change' );

  return $ret;
}

sub insert {
  my $self = shift; 

  my %cols = $self->get_columns;
  my @changing = keys %cols;

  $self->before_change( \@changing, @_ ) if $self->can( 'before_change' );
  $self->before_insert( \@changing, @_ ) if $self->can( 'before_insert' );

  # do it again in case the above methods made changes
  %cols = $self->get_columns;
  @changing = keys %cols;

  my $ret = $self->maybe::next::method;

  $self->after_insert( \@changing, @_ ) if $self->can( 'after_insert' );
  $self->after_change( \@changing, @_ ) if $self->can( 'after_change' );

  return $ret;
}

1;

__END__

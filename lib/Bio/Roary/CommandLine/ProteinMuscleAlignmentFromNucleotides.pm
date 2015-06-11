package Bio::Roary::CommandLine::ProteinMuscleAlignmentFromNucleotides;

# ABSTRACT: Take in a multifasta file of nucleotides, convert to proteins and align with muscle

=head1 SYNOPSIS

Take in a multifasta file of nucleotides, convert to proteins and align with muscle, reverse translate back to nucleotides

=cut

use Moose;
use Getopt::Long qw(GetOptionsFromArray);
use Bio::Roary::AnnotateGroups;
use Bio::Roary::External::Prank;
use Bio::Roary::Output::GroupsMultifastaProtein;
use Bio::Roary::SortFasta;
extends 'Bio::Roary::CommandLine::Common';


has 'args'        => ( is => 'ro', isa => 'ArrayRef', required => 1 );
has 'script_name' => ( is => 'ro', isa => 'Str',      required => 1 );
has 'help'        => ( is => 'rw', isa => 'Bool',     default  => 0 );

has 'nucleotide_fasta_files'  => ( is => 'rw', isa => 'ArrayRef' );
has '_error_message'          => ( is => 'rw', isa => 'Str' );
has 'verbose'                 => ( is => 'rw', isa => 'Bool', default => 0 );

sub BUILD {
    my ($self) = @_;

    my ( $nucleotide_fasta_files, $help,$verbose );

    GetOptionsFromArray(
        $self->args,
		'v|verbose'                 => \$verbose,
        'h|help'              => \$help,
    );
	
    if ( defined($verbose) ) {
        $self->verbose($verbose);
        $self->logger->level(10000);
    }

    $self->help($help) if(defined($help));
    if ( @{ $self->args } == 0 ) {
        $self->_error_message("Error: You need to provide at least 1 FASTA file");
    }

    for my $filename ( @{ $self->args } ) {
        if ( !-e $filename ) {
            $self->_error_message("Error: Cant access file $filename");
            last;
        }
    }
    $self->nucleotide_fasta_files( $self->args );
}

sub run {
    my ($self) = @_;

    ( !$self->help ) or die $self->usage_text;
    if ( defined( $self->_error_message ) ) {
        print $self->_error_message . "\n";
        die $self->usage_text;
    }

    for my $fasta_file (@{$self->nucleotide_fasta_files})
    {
      
      my $sort_fasta_before = Bio::Roary::SortFasta->new(
         input_filename   => $fasta_file,
		 make_multiple_of_three => 1,
       );
      $sort_fasta_before->sort_fasta->replace_input_with_output_file;
	  
	  my $prank_obj = Bio::Roary::External::Prank->new(
	    input_filename  => $fasta_file,
	    output_filename => $fasta_file.'.aln',
	    job_runner      => 'Local',
		logger          => $self->logger,
		verbose         => $self->verbose
	  );
	  $prank_obj->run();
	  
      my $sort_fasta_after_revtrans = Bio::Roary::SortFasta->new(
         input_filename      => $fasta_file.'.aln',
		 remove_nnn_from_end => 1,
       );
      $sort_fasta_after_revtrans->sort_fasta->replace_input_with_output_file;
      unlink($fasta_file);
    }
}

sub usage_text {
    my ($self) = @_;

    return <<USAGE;
    Usage: protein_muscle_alignment_from_nucleotides [options]
    Take in a multifasta file of nucleotides, convert to proteins and align with muscle
    
    # Transfer the annotation from the GFF files to the group file
    protein_muscle_alignment_from_nucleotides protein_fasta_1.faa protein_fasta_2.faa
    
    # This help message
    protein_muscle_alignment_from_nucleotides -h

USAGE
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

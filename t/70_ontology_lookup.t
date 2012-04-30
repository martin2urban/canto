use strict;
use warnings;
use Test::More tests => 33;

use PomCur::TestUtil;

use PomCur::Track;

my $test_util = PomCur::TestUtil->new();
$test_util->init_test();

my $config = $test_util->config();
my $lookup = PomCur::Track::get_adaptor($config, 'ontology');

my $search_string = 'transporter';
my $transport_id = 'GO:0005215';
my $transport_name = 'transporter activity';
my $transport_definition = 'Enables the directed movement of substances (such as macromolecules, small molecules, ions) into, out of or within a cell, or between cells.';

my $ont_name = 'molecular_function';

{
  my $results = $lookup->lookup(ontology_name => $ont_name,
                                search_string => $search_string,
                                max_results => 10,
                                include_definition => 0);

  ok(defined $results);

  is(scalar(@$results), 3);

  ok(grep { $_->{id} eq $transport_id &&
            $_->{name} eq $transport_name &&
            !defined $_->{definition}
          } @$results);

  is(scalar(map { $_->{name} =~ /^$search_string/ } @$results), 1);
}

{
  my $results = $lookup->lookup(ontology_name => $ont_name,
                                search_string => $search_string,
                                max_results => 10,
                                include_definition => 1);

  ok(defined $results);

  is(scalar(@$results), 3);

  ok(grep { $_->{id} eq $transport_id &&
            $_->{name} eq $transport_name &&
            $_->{definition} eq $transport_definition
          } @$results);

  is(scalar(map { $_->{name} =~ /^$search_string/ } @$results), 1);
}

# lookup a broad synonym
{
  my $results = $lookup->lookup(ontology_name => 'molecular_function',
                                search_string => 'tagging',
                                max_results => 10,
                                include_definition => 1);

  ok(defined $results);

  is(scalar(@$results), 2);

  ok(grep {
    $_->{id} eq 'GO:0031386' && $_->{name} eq 'protein tag'
  } @$results);

  ok(grep {
    $_->{id} eq 'GO:0005515' && $_->{name} eq 'protein binding'
  } @$results);
}

my $id_result = $lookup->lookup(ontology_name => 'biological_process',
                                search_string => 'GO:0006810',
                                max_results => 10,
                                include_definition => 1);

is(scalar(@$id_result), 1);

is($id_result->[0]->{id}, 'GO:0006810');
is($id_result->[0]->{name}, 'transport');
is($id_result->[0]->{annotation_namespace}, 'biological_process');
like($id_result->[0]->{definition}, qr/^The directed movement of substances/);

# try looking up an ID from the wrong ontology
$id_result = $lookup->lookup(ontology_name => 'biological_process',
                             search_string => 'GO:0030133',
                             max_results => 10,
                             include_definition => 1);

is(scalar(@$id_result), 1);

is($id_result->[0]->{id}, 'GO:0030133');
is($id_result->[0]->{name}, 'transport vesicle');
is($id_result->[0]->{annotation_namespace}, 'cellular_component');
like($id_result->[0]->{definition}, qr/^Any of the vesicles of the constitutive/);

my $child_results =
  $lookup->lookup(ontology_name => $ont_name,
                  include_children => 1,
                  search_string => $transport_id,
                  max_results => 10);

is(@$child_results, 1);

my $child_res = $child_results->[0];

is($child_res->{id}, $transport_id);
is($child_res->{name}, $transport_name);
ok(!defined $child_res->{definition});

my @children = @{$child_res->{children}};

is(@children, 2);
        use Data::Dumper;

ok(grep { $_->{id} eq 'GO:0005487' &&
          $_->{name} eq 'nucleocytoplasmic transporter activity' ||
          $_->{id} eq 'GO:0022857' &&
          $_->{name} eq 'transmembrane transporter activity' } @children);

# try a phenotype name
$id_result = $lookup->lookup(ontology_name => 'phenotype',
                             search_string => 'FYPO:0000114',
                             max_results => 10,
                             include_definition => 1);

is(scalar(@$id_result), 1);

is($id_result->[0]->{id}, 'FYPO:0000114');
is($id_result->[0]->{name}, 'cellular process phenotype');
is($id_result->[0]->{annotation_namespace}, 'fission_yeast_phenotype');


my @all_pco_terms = $lookup->get_all(ontology_name => 'phenotype_condition');

is (@all_pco_terms, 5);

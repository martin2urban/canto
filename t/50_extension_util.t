use strict;
use warnings;
use Test::More tests => 6;
use Test::Deep;

use Try::Tiny;

use Canto::ExtensionUtil;

my @res = Canto::ExtensionUtil::parse_extension("rel1 ( range1) ,\nrel2(range2)|rel3(range3)\n");

cmp_deeply([@res],
           [
             [
               {
                 'relation' => 'rel1',
                 'rangeValue' => 'range1'
               },
               {
                 'relation' => 'rel2',
                 'rangeValue' => 'range2'
               }
             ],
             [
               {
                 'rangeValue' => 'range3',
                 'relation' => 'rel3'
               }
             ]
           ]);

@res = Canto::ExtensionUtil::parse_extension("rel1(range1),residue=10,col17=PR:000123");
cmp_deeply([@res],
           [
             [
               {
                 'relation' => 'rel1',
                 'rangeValue' => 'range1'
               },
               {
                 'rangeValue' => '10',
                 'relation' => 'residue'
               },
               {
                 'rangeValue' => 'PR:000123',
                 'relation' => 'column_17'
               }
             ]
           ]);

try {
  @res = Canto::ExtensionUtil::parse_extension("rel1(range1),qualifier=unknown");
  fail("parse should fail");
} catch {
  is($_, "failed to store qualifier with value 'unknown' in: rel1(range1),qualifier=unknown\n");
};


@res = Canto::ExtensionUtil::parse_extension("");
cmp_deeply([@res],
           []);

@res = Canto::ExtensionUtil::parse_extension("    ");
cmp_deeply([@res],
           [[]]);

@res = Canto::ExtensionUtil::parse_extension();
cmp_deeply([@res],
           []);

use strict;
use warnings;
use Test::More tests => 21;

use Plack::Test;
use Plack::Util;
use HTTP::Request;
use HTTP::Cookies;

use PomCur::TestUtil;
use PomCur::Track::StatusStorage;
use PomCur::Role::MetadataAccess;
use PomCur::Controller::Curs;

my $test_util = PomCur::TestUtil->new();
$test_util->init_test('curs_annotations_1');

my $config = $test_util->config();
my $track_schema = $test_util->track_schema();

my $status_storage = PomCur::Track::StatusStorage->new(config => $config);

my @curs_objects = $track_schema->resultset('Curs')->all();
is(@curs_objects, 1);

my $curs_key = $curs_objects[0]->curs_key();
my $app = $test_util->plack_app()->{app};
my $cookie_jar = HTTP::Cookies->new(
  file => '/tmp/pomcur_web_test_$$.cookies',
  autosave => 1,
);
my $curs_schema = PomCur::Curs::get_schema_for_key($config, $curs_key);
my $root_url = "http://localhost:5000/curs/$curs_key";

my $thank_you ="Thank you for your contribution to PomBase";

test_psgi $app, sub {
  my $cb = shift;

  {
    my $uri = new URI("$root_url/");

    my $req = HTTP::Request->new(GET => $uri);
    my $res = $cb->($req);

    is $res->code, 200;

    like ($res->content(), qr/Choose a gene to annotate/s);
    like ($res->content(), qr/Publication details/s);

    is($status_storage->retrieve($curs_key, 'annotation_status'),
       PomCur::Controller::Curs::CURATION_IN_PROGRESS);
  }

  # change status to "NEEDS_APPROVAL"
  {
    my $uri = new URI("$root_url/finish_form");

    my $req = HTTP::Request->new(GET => $uri);
    my $res = $cb->($req);

    is $res->code, 200;

    is($status_storage->retrieve($curs_key, 'annotation_status'), "NEEDS_APPROVAL");
  }

  # log in
  {
    my $admin_role =
      $track_schema->resultset('Cvterm')->find({ name => 'admin' });

    my $admin_people =
      $track_schema->resultset('Person')->
        search({ role => $admin_role->cvterm_id() });

    my $first_admin = $admin_people->first();
    ok(defined $first_admin);

    my $uri = new URI("http://localhost:5000/login");
    $uri->query_form(email_address => $first_admin->email_address(),
                     password => $first_admin->password(),
                     return_path => 'http://localhost:5000/',
                     submit => 'login',
                   );

    my $req = HTTP::Request->new(GET => $uri);
    $cookie_jar->add_cookie_header($req);

    my $res = $cb->($req);
    is $res->code, 302;

    my $redirect_url = $res->header('location');
    is ($redirect_url, 'http://localhost:5000/');
  }

  # check that we now redirect to the "finished" page
  {
    my $uri = new URI("$root_url/");

    my $req = HTTP::Request->new(GET => $uri);
    my $res = $cb->($req);

    is $res->code, 200;

    (my $content = $res->content()) =~ s/\s+/ /g;

    like ($content, qr/$thank_you/s);

    is($status_storage->retrieve($curs_key, 'annotation_status'), "NEEDS_APPROVAL");
  }
};

done_testing;

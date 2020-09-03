#!/usr/bin/env perl
# ABSTRACT: API Endpoints for HTTP Hooks
package GreeHost::Hooks;
use Web::Simple;
use Plack::Request;
use JSON::MaybeXS qw( decode_json encode_json );
use Try::Tiny;
use Object::Remote;
use GreeHost::Builder;
use GreeHost::Minion;

open my $cfh, '<', '/opt/greehost/hooks/projects.json'
    or die "Failed to open /opt/greehost/hooks/projects.json for reading: $!";
my $projects = decode_json( do { local $/; <$cfh> } );
close $cfh;
        
sub dispatch_request {
    return (
        'POST + /gitea'    => sub { _process_hook_gitea(@_)    },
    );
}

sub _process_hook_gitea {
    my ( $self, $env ) = @_;
    my $req  = Plack::Request->new($env);
    my $push = try { decode_json($req->raw_body) };

    my $repo = $push->{repository}{ssh_url};

    if ( ! exists $projects->{$repo} ) {
        return [ 404, [ 'Content-Type' => 'application/json' ], [ encode_json( { status => 0, error => "$repo not found" } ) ] ];
    }

    my $id = GreeHost::Minion->new->enqueue( 'build_project' => [ $projects->{$repo} ], { queue => 'build_project' } );

    return [ 200, [ 'Content-Type' => 'application/json' ], [ encode_json( { status => 1, job_id => $id } ) ] ];
}

__PACKAGE__->run_if_script;

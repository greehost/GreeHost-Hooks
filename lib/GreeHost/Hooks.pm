#!/usr/bin/env perl
# ABSTRACT: API Endpoints for HTTP Hooks
package GreeHost::Hooks;
use Web::Simple;
use Plack::Request;
use JSON::MaybeXS qw( decode_json );
use Try::Tiny;
use Object::Remote;
use GreeHost::Builder;
        
# TODO: Kill me
use Data::Dumper;

sub dispatch_request {
    'POST + /gitea' => sub { _process_hook_gitea(@_) }
}

sub _process_hook_gitea {
        my ( $self, $env ) = @_;
        my $req  = Plack::Request->new($env);
        my $push = try { decode_json($req->raw_body) };

        # Throw an error if $push is wrong.

        # Find the account this is for so we can find the shared key
        
        # Calculate payload sig and verify, or throw error (also report to NOC)

        # Trigger build event for repo (should be minion)
        my $conn = Object::Remote->connect( 'root@192.168.18.11' );
        GreeHost::Builder->can::on( $conn, 'build_project' )->($push);

        return [ 200, [ ], [ ] ];
}

__PACKAGE__->run_if_script;

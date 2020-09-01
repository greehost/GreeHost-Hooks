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
        
sub dispatch_request {
    return (
        'POST + /gitea'    => sub { _process_hook_gitea(@_)    },
        'POST + /project'  => sub { _process_hook_project(@_)  },
        'POST + /sslstore' => sub { _process_hook_sslstore(@_) },
    );
}

sub _process_hook_project {
    my ( $self, $env ) = @_;
    my $req  = Plack::Request->new($env);
    my $push = try { decode_json($req->raw_body) };
}

sub _process_hook_sslstore {
    my ( $self, $env ) = @_;
    my $req  = Plack::Request->new($env);
    my $push = try { decode_json($req->raw_body) };

    my $id = GreeHost::Minion->new->enqueue( 'ssl_store_add' => [ 
        name    => $push->{name}, 
        domains =>  [ @{$push->{domains}} ],
        key     => $push->{linode_dns_key} 
    ]);

    return [ 200, [ 'Content-Type' => 'application/json' ], [ encode_json( { status => 1, job_id => $id } ) ] ];
}

sub _process_hook_gitea {
    my ( $self, $env ) = @_;
    my $req  = Plack::Request->new($env);
    my $push = try { decode_json($req->raw_body) };

    my $id = GreeHost::Minion->new->enqueue( 'build_project' => [ event => $push ] );

    return [ 200, [ 'Content-Type' => 'application/json' ], [ encode_json( { status => 1, job_id => $id } ) ] ];
}

__PACKAGE__->run_if_script;

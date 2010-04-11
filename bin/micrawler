#!/usr/bin/env perl

use strict; 
use warnings;

use IO::All;
use LWP::UserAgent;
use URI;
use Web::Scraper;

$|=1;

### Gestion des params de ligne de commande ###
my ( $max_depth, $max_pages_count, $max_distance, @seed_urls ) = @ARGV or die( 'need a lot of things ;)' );

print "Picrowler ---\n";
print "max_depth = $max_depth\n";
print "max_pages_count = $max_pages_count\n";
print "max_distance = $max_distance\n";

### Gestion de la base de données ###
my $nodes;
my $edges;
my $nodes_count = 0;

sub find_or_create_node {
    my $url = shift;
    my $id  = undef;    
    if( defined $nodes->{ $url } ) {
        $id = $nodes->{ $url };
    }
    else {
        $id = $nodes->{ $url } = ++$nodes_count; 
    }
    return $id;
}

### Initialisation de LWP ###
my $agent = LWP::UserAgent->new;
$agent->agent( 'Picrowler - http://github.com/cmaussan/Picrowler' );

### Initialisation du scraper ###
my $scraper = scraper {
    process "a", "links[]" => '@href';
};

my @sites_to_visit = map { $_->canonical->as_string } grep { defined $_ } map { site_uri( $_ ) } @seed_urls;
my @sites_already_visited = ();

my $distance = 0;

while( $distance <= $max_distance ) {

    my @sites_outlinks = ();
    
    for my $site_to_visit ( @sites_to_visit ) {

        next if( grep{ $_ eq $site_to_visit } @sites_already_visited );

        print "crawling [$site_to_visit] ($distance) :\n";
        my $id_source = find_or_create_node( $site_to_visit );

        push @sites_outlinks, { id_source => $id_source, links => crawler( $site_to_visit ) };
        push @sites_already_visited, $site_to_visit;

    }

    for my $site_relations ( @sites_outlinks ) {
        my $id_source = $site_relations->{ id_source };

        for my $site_outlink ( @{ $site_relations->{ links } } ) {
            my $site_found = site_uri( $site_outlink );
            next unless( $site_found );

            my $id_target = find_or_create_node( $site_found );
            $edges->{ "$id_source-$id_target" } ++ unless( $id_source == $id_target );

            next if( grep{ $_ eq $site_found->canonical->as_string } @sites_already_visited );
            push @sites_to_visit, $site_found; 
        }
    }

    $distance++;

}

export();

print "end crawling.\n";

### Vérificateur d'URL ###
sub is_valid {
    my $url = shift;
    my $uri = ( ref $url && ref $url =~ /^URI/ ) ? $url : URI->new( $url );

    if( ref( $uri ) ne 'URI::http' ) {
        warn "[$uri] not valid";
        $uri = undef;
    }
    return $uri;
}


### Définisseur de site ###
sub site_uri {
    my $uri = is_valid( shift );

    return undef unless( $uri );  

    # Heuristique de site, on met ce qu'on veut ici
    # Par défaut on renvoie le host canonisé
    return URI->new( $uri->scheme . '://' . $uri->host )->canonical;

}

sub is_outlink {
    my ( $site_uri, $link_uri ) = @_;
    return ( $link_uri->canonical->as_string !~ /^$site_uri/ ) ? 1 : 0;
}

### Crawler de site ###
sub crawler {
    my ( $site_uri ) = @_; # Ici était la start URL mais c'est foireux...

    my @to_visit = ( $site_uri );
    my @already_visited = ();
    my @outlinks = ();

    my $depth = 0;
    my $pages_count = 0;

    while( $depth < $max_depth && $pages_count < $max_pages_count && @to_visit ) {

        my @links = ();
        
        for my $url ( @to_visit ) {
            
            last if( $pages_count >= $max_pages_count );

            my $response = $agent->get( $url );
            if( $response->is_success ) {
                next unless( $response->header( 'content-type' ) =~ m!text/html! );
                $url = $response->request->uri->canonical->as_string;
                print "... crawling page [$url]\n";
                my $result = $scraper->scrape( $response->content );
                
                for my $link ( @{ $result->{ links } } ) {
                    my $link_uri = URI->new_abs( $link, $url );
                    if( is_outlink( $site_uri, $link_uri ) ) {
                        push @outlinks, $link_uri->as_string;
                    }
                    else {
                        push @links, $link_uri->as_string;
                    }
                 }

            }
            else {
                warn "[$url] impossible to get : " . $response->status_line;
                next;
            }

            push @already_visited, $url;
            $pages_count++;
        }

        @to_visit = ();
        
        for my $url_to_check ( @links ) {
            my $to_push = 1;
            for my $url_visited ( @already_visited ) {
                if( $url_to_check eq $url_visited ) { 
                    $to_push = 0; last; 
                }
                $to_push = 1;
            }
            push @to_visit, $url_to_check
                if( $to_push && !grep{ $_ eq $url_to_check } @to_visit );				
        }

        $depth++;

    }

    print "... found " . scalar( @outlinks ) . " outlinks\n";
    
    \@outlinks;
}

sub export {
    my $out = io( 'crawl.gdf' );

    "nodedef> name VARCHAR, label VARCHAR, site VARCHAR\n" > $out;

    for my $url ( keys %$nodes ) {
        my $id = $nodes->{ $url };
        my $host = URI->new( $url )->host;
        "v$id, '$url', '$host'\n" >> $out;
    }

    "edgedef> node1 VARCHAR, node2 VARCHAR, count INT\n" >> $out;

    for my $ids ( keys %$edges ) {
        my ( $id_source, $id_target ) = split( /-/, $ids );
        my $count = $edges->{ $ids };
        "v$id_source, v$id_target, $count\n" >> $out;
    }
}

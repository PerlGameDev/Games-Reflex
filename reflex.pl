use strict;
use warnings;
use SDL;
use SDL::Event;
use SDL::Events;
use SDLx::Sprite;
use SDLx::App;
use SDLx::Text;
use Sub::Frequency;
use Time::HiRes qw(gettimeofday tv_interval);

my $app = SDLx::App->new(
    title => 'Reflex',
    eoq => 1,
);

# initializes our key surface
my $button = {
    sprite  => SDLx::Sprite->new(
                  image => 'data/button.png',
                  x     => 100,
                  y     => 100,
               ),
    on      => SDL::Rect->new(0,0,416,419),
    off     => SDL::Rect->new(0,420,416,419),
    status  => 'off',
};

my $score = SDLx::Text->new( x => 10 );

my $started;
my $stopwatch = '0.0';
my $alert = {
    message => SDLx::Text->new( text => 'JUMPED THE GUN! 1 second penalty'),
    started => undef,
};

my $top10 = {
    text => SDLx::Text->new,
    list => [],
    last => 0,
};

$app->add_move_handler( sub {
    my ($delta, $app) = @_;

    with_probability 0.01 => sub {
        $button->{status} = 'on';
    };

    if ($alert->{started}) {
        $alert->{started} = undef
            if tv_interval( $alert->{started}, [gettimeofday] ) > 1;
    }

    if ($started) {
        $stopwatch = tv_interval( $started, [gettimeofday] );
    }
});

$app->add_event_handler( sub {
    my ($event, $app) = @_;

    if ($event->key_type == SDL_KEYDOWN) {
        if ($button->{status} eq 'off') {
            $alert->{started} = [gettimeofday];
        }
        elsif (!$alert->{started}) {
            my @top10 = sort @{$top10->{list}}, $stopwatch;
            splice @top10, 19 if @top10 == 20;
            $top10->{list} = \@top10;
            $top10->{last} = $stopwatch;
            $button->{status} = 'off';
            undef $started;
        }
    }
});

$app->add_show_handler( sub {
    my ($delta, $app) = @_;

    $app->draw_rect( [0,0,$app->w, $app->h], 0x112244FF );

    $button->{sprite}->clip( $button->{ $button->{status} });
    $button->{sprite}->draw( $app );
    $score->write_to($app, $stopwatch);

    if (!$started and $button->{status} eq 'on') {
        $started = [gettimeofday];
    }
    if ($alert->{started}) {
        $alert->{message}->write_xy($app, 10,30);
    }

    foreach my $i (1 .. @{$top10->{list}} ) {
        my $time = $top10->{list}[$i-1];
        $top10->{text}->color( $top10->{last} == $time ? 0x00FF00 : 0xFFFFFFFF );
        $top10->{text}->write_xy($app, 700, $i * 20, $top10->{list}[$i-1]);
    }
    $app->update;
});

$app->run;

package mdkapplet_urpm;

# taken from urpmi:

use MDK::Common;
use urpm::download;

sub userdir_prefix {
    my ($_urpm) = @_;
    '/tmp/.urpmi-';
}
sub userdir {
    my ($urpm) = @_;
    $< or return;

    my $dir = ($urpm->{urpmi_root} || '') . userdir_prefix($urpm) . $<;
    mkdir $dir, 0755; # try to create it

    -d $dir && ! -l $dir or $urpm->{fatal}(1, sprintf("fail to create directory %s", $dir));
    -o $dir && -w $dir or $urpm->{fatal}(1, sprintf("invalid owner for directory %s", $dir));

    mkdir "$dir/partial";
    mkdir "$dir/rpms";

    $dir;
}
sub ensure_valid_cachedir {
    my ($urpm) = @_;
    if (my $dir = userdir($urpm)) {
	$urpm->{cachedir} = $dir;
    }
    -w "$urpm->{cachedir}/partial" or $urpm->{fatal}(1, "Can not download packages into %s", "$urpm->{cachedir}/partial");
}
sub valid_cachedir {
    my ($urpm) = @_;
    userdir($urpm) || $urpm->{cachedir};
}

sub get_content {
    my ($urpm, $url) = @_;

    my $download_dir = valid_cachedir($urpm) . '/partial/';
    my $file = $download_dir . basename($url);

    unlink $file; # prevent "partial file" errors
    eval { urpm::download::sync($urpm, undef, [ $url ], quiet => 1, dir => $download_dir) };
    #sync_url($urpm, $url, dir => $download_dir, quiet => 1) or return;

    my @l = cat_($file);
    unlink $file;

    wantarray() ? @l : join('', @l);
}
    
1;

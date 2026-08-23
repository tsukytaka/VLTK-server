use strict;
use warnings;

my ($path) = @ARGV;
die "usage: $0 goldequip.txt\n" unless defined $path;

open my $in, '<:raw', $path or die "open $path: $!\n";
my @lines = <$in>;
close $in;

die "unexpected row count in $path: ".scalar(@lines)."\n" unless @lines == 5899;
my $template = $lines[531];
$template =~ s/\r?\n\z//;
my @base = split /\t/, $template, -1;
die "unexpected template field count in $path: ".scalar(@base)."\n" unless @base == 62;

sub make_row {
    my ($name, $desc, $suite, $skill) = @_;
    my @field = @base;
    $field[0] = $name;
    $field[8] = $desc;
    for my $i (13 .. 51) {
        $field[$i] = '';
    }
    if ($skill) {
        $field[13] = 139;
        $field[14] = 1;
        $field[15] = 1;
    }
    $field[52] = $suite;
    for my $i (53 .. 61) {
        $field[$i] = '';
    }
    return join("\t", @field)."\r\n";
}

while (@lines < 7000) {
    my $reserved_id = scalar(@lines);
    push @lines, make_row("RESERVED_GOLD_ID_$reserved_id", "N/A", '', 0);
}

my $name = pack('H*', '4e68c96e20546869aa6e2074f6');
my $desc = pack('H*', '4e68c96e20546869aa6e2074f63c656e7465723e4bfc206ea86e672076e86e2063e3202b312063ca703c656e7465723e4bdd636820686fb9742074ca742063b620746875e9632074dd6e6820c86e2063f161207472616e672062de2e3c656e7465723e3c656e7465723e3c62636c723d70696e6b3e564c544b204f66666c696e65202d204d6f646279205454543c62636c723e');
push @lines, make_row($name, $desc, 524, 1);

die "failed to place gold ID 7000 in $path\n" unless @lines == 7001;
open my $out, '>:raw', "$path.new" or die "write $path.new: $!\n";
print {$out} @lines;
close $out;

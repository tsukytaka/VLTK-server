use strict;
use warnings;

my ($path) = @ARGV;
die "usage: $0 goldequip.txt\n" unless defined $path;

open my $in, '<:raw', $path or die "open $path: $!\n";
my @lines = <$in>;
close $in;

die "missing gold item row 532 in $path\n" unless @lines >= 532;
my $line = $lines[531];
$line =~ s/\r?\n\z//;
my @field = split /\t/, $line, -1;
die "unexpected field count in $path: ".scalar(@field)."\n" unless @field == 62;

$field[0] = pack('H*', '4e68c96e20546869aa6e2074f6');
$field[8] = pack('H*', '4e68c96e20546869aa6e2074f63c656e7465723e4bfc206ea86e672076e86e2063e3202b312063ca703c656e7465723e4bdd636820686fb9742074ca742063b620746875e9632074dd6e6820c86e2063f161207472616e672062de2e3c656e7465723e3c656e7465723e3c62636c723d70696e6b3e564c544b204f66666c696e65202d204d6f646279205454543c62636c723e');
$field[13] = 139;
$field[14] = 1;
$field[15] = 1;
for my $i (16 .. 51) {
    $field[$i] = '';
}
$field[52] = 524;
for my $i (53 .. 61) {
    $field[$i] = '';
}
$lines[531] = join("\t", @field)."\r\n";

open my $out, '>:raw', "$path.new" or die "write $path.new: $!\n";
print {$out} @lines;
close $out;

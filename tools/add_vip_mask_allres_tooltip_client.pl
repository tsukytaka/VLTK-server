use strict;
use warnings;

my ($path) = @ARGV;
die "usage: $0 mask.txt\n" unless defined $path;

open my $in, '<:raw', $path or die "open $path: $!\n";
my @lines = <$in>;
close $in;

my $found = 0;
for my $line (@lines) {
    my $ending = ($line =~ /\r\n\z/) ? "\r\n" : "\n";
    $line =~ s/\r?\n\z//;
    my @field = split /\t/, $line, -1;
    if (@field >= 46 && $field[1] eq '0' && $field[2] eq '11' && $field[3] eq '592') {
        die "VIP mask tooltip slot is not empty in $path\n"
            if $field[13] ne '' || $field[14] ne '' || $field[15] ne '';
        $field[13] = 114;
        $field[14] = 50;
        $field[15] = 50;
        $found++;
    }
    $line = join("\t", @field).$ending;
}

die "expected one VIP mask row in $path, found $found\n" unless $found == 1;
open my $out, '>:raw', "$path.new" or die "write $path.new: $!\n";
print {$out} @lines;
close $out;

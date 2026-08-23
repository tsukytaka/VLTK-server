#!/usr/bin/perl
use strict;
use warnings;
use bytes;

my $root = '/home/jxser/server1';
my $skills_path = "$root/settings/skills.txt";

my @owners = (
    [qr/^quanshaolin150(?:_|$)/, 1055],
    [qr/^gunshaolin150(?:_|$)/, 1056],
    [qr/^daoshaolin150(?:_|$)/, 1057],
    [qr/^daotianwang150(?:_|$)/, 1058],
    [qr/^chuitianwang150(?:_|$)/, 1059],
    [qr/^qiangtianwang150(?:_|$)/, 1060],
    [qr/^jianemei150(?:_|$)/, 1061],
    [qr/^zhangemei150(?:_|$)/, 1062],
    [qr/^daocuiyan150(?:_|$)/, 1063],
    [qr/^neicuiyan150(?:_|$)/, 1065],
    [qr/^zhangwudu150(?:_|$)/, 1066],
    [qr/^daowudu150(?:_|$)/, 1067],
    [qr/^feidaotang150(?:_|$)/, 1069],
    [qr/^nutang150(?:_|$)/, 1070],
    [qr/^biaotang150(?:_|$)/, 1071],
    [qr/^zhanggaibang150(?:_|$)/, 1073],
    [qr/^gungaibang150(?:_|$)/, 1074],
    [qr/^zhanren150(?:_|$)/, 1075],
    [qr/^moren150(?:_|$)/, 1076],
    [qr/^qiwudang150(?:_|$)/, 1078],
    [qr/^jianwudang150(?:_|$)/, 1079],
    [qr/^daokunlun150(?:_|$)/, 1080],
    [qr/^jiankunlun150(?:fu)?(?:_|$)/, 1081],
    [qr/^pili_dan$/, 1110],
    [qr/^fuzhuemei150(?:_|$)/, 1114],
);

sub owner_for_block {
    my ($block) = @_;
    for my $entry (@owners) {
        return $entry->[1] if $block =~ $entry->[0];
    }
    return;
}

open my $sfh, '<:raw', $skills_path or die "open $skills_path: $!";
local $/;
my $skills_raw = <$sfh>;
close $sfh;

my @lines = split /\n/, $skills_raw, -1;
my @header = split /\t/, $lines[0], -1;
$header[-1] =~ s/\r$//;
my %col;
for my $i (0 .. $#header) { $col{$header[$i]} = $i; }
for my $required (qw(SkillId LvlSetScript LvlSetting1 LvlData1 LvlSetting20 LvlData20)) {
    die "missing column $required" unless exists $col{$required};
}

my %lua_blocks;
my @changed_rows;
for my $line (@lines) {
    my $had_cr = ($line =~ s/\r$//);
    my @f = split /\t/, $line, -1;
    my $id = $f[$col{SkillId}] // '';
    if ($id =~ /^\d+$/ && $id >= 1055 && $id <= 1131) {
        my ($owner, $block);
        for my $n (1 .. 20) {
            my $candidate = $f[$col{"LvlData$n"}] // '';
            my $candidate_owner = owner_for_block($candidate);
            if ($candidate_owner) {
                ($owner, $block) = ($candidate_owner, $candidate);
                last;
            }
        }
        if ($owner) {
            my ($has_add, $empty_setting);
            for my $n (1 .. 20) {
                my $name = $f[$col{"LvlSetting$n"}] // '';
                $has_add = 1 if $name eq 'addskillexp1';
                $empty_setting = $n if !defined($empty_setting) && $name eq '';
            }
            if (!$has_add) {
                die "skill $id has no empty LvlSetting" unless defined $empty_setting;
                $f[$col{"LvlSetting$empty_setting"}] = 'addskillexp1';
                $f[$col{"LvlData$empty_setting"}] = $block;
                push @changed_rows, $id;
            }
            my $lua_rel = $f[$col{LvlSetScript}] // '';
            die "skill $id has no LvlSetScript" if $lua_rel eq '';
            $lua_rel =~ s{\\}{/}g;
            $lua_rel =~ s{^/}{};
            $lua_blocks{"$root/$lua_rel"}{$block} = $owner;
            $line = join("\t", @f) . ($had_cr ? "\r" : '');
        }
    }
}

my %new_lua;
for my $path (sort keys %lua_blocks) {
    open my $lfh, '<:raw', $path or die "open $path: $!";
    my $raw = <$lfh>;
    close $lfh;
    for my $block (sort keys %{$lua_blocks{$path}}) {
        my $owner = $lua_blocks{$path}{$block};
        my $block_re = quotemeta($block);
        next if $raw =~ /(^\s*$block_re\s*=\s*\{.*?^\s*\},)/ms
             && $& =~ /addskillexp1=\{\{\{1,\Q$owner\E\},\{2,\Q$owner\E\}\}/;
        my $insert = "\t\taddskillexp1={{{1,$owner},{2,$owner}},{{1,1},{20,1}},{{1,0},{2,0}}}, -- Kinh nghiem luyen skill 150\r\n";
        my $count = ($raw =~ s/(^\s*$block_re\s*=\s*\{[^\r\n]*\r?\n)/$1$insert/m);
        die "cannot locate Lua block $block for owner $owner in $path" unless $count == 1;
    }
    $new_lua{$path} = $raw;
}

open my $out, '>:raw', "$skills_path.tmp" or die "write $skills_path.tmp: $!";
print {$out} join("\n", @lines);
close $out;
rename "$skills_path.tmp", $skills_path or die "rename skills: $!";

for my $path (sort keys %new_lua) {
    open my $out_lua, '>:raw', "$path.tmp" or die "write $path.tmp: $!";
    print {$out_lua} $new_lua{$path};
    close $out_lua;
    rename "$path.tmp", $path or die "rename $path: $!";
}

print "Added parent proficiency to ".scalar(@changed_rows)." level-150 child/event skill rows: @changed_rows\n";

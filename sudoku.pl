#!/usr/bin/perl -w

use strict;
use warnings;

my $MAX_NUMBER = 9;
my @RANGE = (1 .. $MAX_NUMBER);

my $MAX_ATTEMPS = 100;

#
# Prepare the grid based on the specified number and positions
# $i = rows, $j = cols
#
my @GRID;
my @DECIDED;	# Number of definitely decided positions

#
# Example grid from http://en.wikipedia.org/wiki/Sudoku
#
$GRID[0][0] = {5 => 1};
$GRID[0][1] = {3 => 1};
$GRID[0][4] = {7 => 1};
$GRID[1][0] = {6 => 1};
$GRID[1][3] = {1 => 1};
$GRID[1][4] = {9 => 1};
$GRID[1][5] = {5 => 1};
$GRID[2][1] = {9 => 1};
$GRID[2][2] = {8 => 1};
$GRID[2][7] = {6 => 1};
$GRID[3][0] = {8 => 1};
$GRID[3][4] = {6 => 1};
$GRID[3][8] = {3 => 1};
$GRID[4][0] = {4 => 1};
$GRID[4][3] = {8 => 1};
$GRID[4][5] = {3 => 1};
$GRID[4][8] = {1 => 1};
$GRID[5][0] = {7 => 1};
$GRID[5][4] = {2 => 1};
$GRID[5][8] = {6 => 1};
$GRID[6][1] = {6 => 1};
$GRID[6][6] = {2 => 1};
$GRID[6][7] = {8 => 1};
$GRID[7][3] = {4 => 1};
$GRID[7][4] = {1 => 1};
$GRID[7][5] = {9 => 1};
$GRID[7][8] = {5 => 1};
$GRID[8][4] = {8 => 1};
$GRID[8][7] = {7 => 1};
$GRID[8][8] = {9 => 1};


for (my $i = 0; $i < $MAX_NUMBER; $i++) {
	for (my $j = 0; $j < $MAX_NUMBER; $j++) {
		
		#
		# A number has ben given for this position
		#
		# TODO Manage this
		if (exists($GRID[$i][$j])) {
			push(@DECIDED, "$i,$j");
		}
		else {
			my %possibilities = map { $_ => 1 } @RANGE;
			$GRID[$i][$j] = \%possibilities;
		}
	}
}

print "Original grid:\n";
print_grid();
print "\n";

my $attempt = 0;
my @decided_last_attempt = @DECIDED;
while (scalar @DECIDED < $MAX_NUMBER**2 && $attempt < $MAX_ATTEMPS) {
	$attempt++;
	my @decided_this_attempt;
	
	foreach my $position (@decided_last_attempt) {
		my ($i, $j) = split(',', $position, 2);
		push(@decided_this_attempt, forbid($i, $j));
	}
	
	print "Attempt $attempt:\n";
	print_grid();
	#print "Decided positions: ".join(' ', @decided_this_attempt)."\n";
	print "\n";
		
	push(@DECIDED, @decided_this_attempt);
	@decided_last_attempt = @decided_this_attempt;
}

#
# Forbid the value of a set position from being possible on all
# positions of the same line, column and inside the same square
#
sub forbid {
	my ($i, $j) = @_;
	my $possibilities = $GRID[$i][$j];
	
	#
	# Positions that have been decided using this positions
	#
	my @decided_positions;
	
	#
	# Test if the position given is really deciced
	#
	unless (scalar keys %{$possibilities} == 1) {
		print "/!\\ Attempting to forbid undecided value using position ($i,$j)\n";
		print "/!\\ Remaining possibilities: ".join(' ', sort keys %{$possibilities})."\n";
		return;
	}
	
	#
	# Get the value of this position
	#
	my $value = _position_value($i, $j);
	#print "==> Forbidding using position ($i, $j) with value $value.\n";
	
	#
	# Row forbid
	#
	for (my $jj = 0; $jj < $MAX_NUMBER; $jj++) {
		my $p = $GRID[$i][$jj];
		unless ($jj == $j || scalar keys %{$p} == 1) {
			delete $p->{$value};
			if (scalar keys %{$p} == 1) {
				push(@decided_positions, "$i,$jj");
				#print "--- Position ($i, $jj) is now decided with value "._position_value($i, $jj).".\n";
			}
		}
	}
	
	#
	# Column forbid
	#
	for (my $ii = 0; $ii < $MAX_NUMBER; $ii++) {
		my $p = $GRID[$ii][$j];
		unless ($ii == $i || scalar keys %{$p} == 1) {
			delete $p->{$value};
			if (scalar keys %{$p} == 1) {
				push(@decided_positions, "$ii,$j");
				#print "--- Position ($ii, $j) is now decided with value "._position_value($ii, $j).".\n";
			}
		}
	}
	
	#
	# Square forbid
	#
	my $min_i = sqrt($MAX_NUMBER) * int($i / sqrt($MAX_NUMBER));
	my $max_i = $min_i + sqrt($MAX_NUMBER);
	my $min_j = sqrt($MAX_NUMBER) * int($j / sqrt($MAX_NUMBER));
	my $max_j = $min_j + sqrt($MAX_NUMBER);
	for (my $ii = $min_i; $ii < $max_i; $ii++) {
		for (my $jj = $min_j; $jj < $max_j; $jj++) {
			my $p = $GRID[$ii][$jj];
			unless (($ii == $i && $jj == $j) || scalar keys %{$p} == 1) {
				delete $p->{$value};
				if (scalar keys %{$p} == 1) {
					push(@decided_positions, "$ii,$jj");
					#print "--- Position ($ii, $jj) is now decided with value "._position_value($ii, $jj).".\n";
				}
			}
		}
	}
	return @decided_positions;
}

#
# Print the sudoku grid
# Decided postions show the value of the number
# Undecided positions show a dash
#
sub print_grid {
	for (my $i = 0; $i < $MAX_NUMBER; $i++) {
		print "\n" if ($i != 0 && $i % sqrt($MAX_NUMBER) == 0);
		
		for (my $j = 0; $j < $MAX_NUMBER; $j++) {
			print "\t" if ($j != 0 && $j % sqrt($MAX_NUMBER) == 0);

			my $possibilities = $GRID[$i][$j];
			if (scalar keys %{$possibilities} == 1) {
				print _position_value($i, $j);
			}
			else {
				print "-";
			}
			print "\t";
		}
		print "\n";
	}
}

#
# Returns the value of this position
#
sub _position_value {
	my ($i, $j) = @_;
	my $possibilities = $GRID[$i][$j];
	
	#
	# Test if the position given is really deciced
	#
	unless (scalar keys %{$possibilities} == 1) {
		print "/!\\ Attempting to read undecided value using position ($i,$j)\n";
		print "/!\\ Remaining possibilities: ".join(' ', sort keys %{$possibilities})."\n";
		return;
	}
	my $k = (keys %{$possibilities})[0];
	return $k;
}

Notes SQL
 	Advance SQL Puzzles imp
 		16, 17, 21, 28, 29, 38, 47,

	Postgres
		- Least and Greatest, finds the least or greatest between two columns - Puzzle 16, spouses
			- (1001, 2002), (2002, 1001) least() = 1001 greatest() = 2002
			- group by on least(col1,col2), greatest(col1,col2)
			- when exists (pat,charlie) and (charlie,pat) and we want  1 single row (charlie,pat)
		- string_agg(col, "seperator" order by col) requires group by
		- Median calculation
			select PERCENTILE_CONT(0.5) within group(order by integervalue) from sampledata s ;
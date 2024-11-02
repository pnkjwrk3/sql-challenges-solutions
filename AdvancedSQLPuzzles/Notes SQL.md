Notes SQL
 	Advance SQL Puzzles imp
 		16, 17, 21

	Postgres
		- Least and Greatest, finds the least or greatest between two columns
			- (1001, 2002), (2002, 1001) least() = 1001 greatest() = 2002
			- group by when exists (x,y) and (y,x)
		- string_agg(col, "seperator" order by col) requires group by
		- 
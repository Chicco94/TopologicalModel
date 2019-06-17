insieme = '''55 56 65 45 54 46 64 44 66'''

closure = '''74 54 68 34 52 67 63 35 45 84 86 36 66 65 62 75 73 44 42 46 43 53 48 26 85 57 24 77 25 47 37 33 76 64 55 56 58'''

boundary = '''74 54 68 34 52 67 63 35 45 84 86 36 66 65 62 75 73 44 42 46 43 53 48 26 85 57 24 77 25 47 37 33 76 64 55 56 58'''

def clear(): print(100*"\n")

def print_cell(value):
	if value: return "|"+str(value)
	return "| "

def print_schema(schema=[], size=9, res=""):
	res += "+-"*size + "+\n"
	for row in schema:
		for cell in row:
			res += print_cell(cell)
		res += "|\n"+"+-"*size + "+\n"
	print(res)


def create_schema(size=9):
	return [ [False for y in range(size)] for x in range(size)]


def fill_schema(schema=None ,cells=[],size=9, symbol=" "):
	if schema == None:
		schema = create_schema(size)
	for cell in cells:
		schema[int(cell[0])-1][int(cell[1])-1]=symbol
	return schema

schema = create_schema()
schema = fill_schema(schema, cells = insieme.split(" "), symbol="A")
print_schema(schema)

# closure
schema = create_schema()
schema = fill_schema(schema, cells = closure.split(" "), symbol="C")
print_schema(schema)

# boundary
schema = create_schema()
schema = fill_schema(schema, cells = boundary.split(" "), symbol="B")
print_schema(schema)
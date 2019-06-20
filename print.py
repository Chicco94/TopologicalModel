insieme = '''55 56 65 45 54 46 64 44 66'''

interior = '''55'''

closure =  '''54 45 66 65 44 46 64 55 56'''

boundary = '''54 45 66 65 44 46 64 56'''

exterior = '''11 12 13 14 15 16 17 18 19 21 22 23 24 25 26 27 28 29 31 32 33 34 35 36 37 38 39 41 42 43 47 48 49 51 52 53 57 58 59 61 62 63 67 68 69 71 72 73 74 75 76 77 78 79 81 82 83 84 85 86 87 88 89 91 92 93 94 95 96 97 98 99'''




def clear(): print(100*"\n")

def print_cell(value):
	if value: return "|"+str(value)
	return "| "

def print_schema(schema=[], size=9, res=" "):
	for i in range(size):
		res+="|"+str(i+1)
	res += "|\n-"+"+-"*size + "+\n"
	row_index = 1
	for row in schema:
		res+= str(row_index)
		row_index +=1
		for cell in row:
			res += print_cell(cell)
		res += "|\n-"+"+-"*size + "+\n"
	print(res)


def create_schema(size=9):
	return [ [False for y in range(size)] for x in range(size)]


def fill_schema(schema=None ,cells=[],size=9, symbol=" "):
	if schema == None:
		schema = create_schema(size)
	if cells == []:
		return schema
	for cell in cells:
		schema[int(cell[0])-1][int(cell[1])-1]=symbol
	return schema

# set
schema = create_schema()
schema = fill_schema(schema, cells = insieme.split(" "), symbol="A")
print("set")
print_schema(schema)

# interior
schema = create_schema()
schema = fill_schema(schema, cells = interior.split(" "), symbol="I")
print("interior")
print_schema(schema)

# closure
schema = create_schema()
schema = fill_schema(schema, cells = closure.split(" "), symbol="C")
print("closure")
print_schema(schema)

# boundary
schema = create_schema()
schema = fill_schema(schema, cells = boundary.split(" "), symbol="B")
print("boundary")
print_schema(schema)

# exterior
schema = create_schema()
schema = fill_schema(schema, cells = exterior.split(" "), symbol="E")
print("exterior")
print_schema(schema)